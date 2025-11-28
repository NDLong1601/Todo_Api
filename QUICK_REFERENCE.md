# 🚀 Quick Reference Guide

## 📌 Key Files

### Repository Layer
- **`lib/repositories/task_repository.dart`**
  - Coordinates between API and local storage
  - Handles online/offline logic
  - Manages sync operations
  - Provides `onSyncCompleted` callback

### Service Layer
- **`lib/services/api_service.dart`**
  - HTTP requests to backend API
  - CRUD operations

- **`lib/services/local_service.dart`**
  - Hive database operations
  - Two boxes: `tasksBox` (data) + `syncQueueBox` (pending operations)
  - Smart operation merging in `addToSyncQueue()`

### Provider Layer
- **`lib/providers/task_provider.dart`**
  - State management
  - UI refresh coordination
  - Sync callback handler

---

## 🔄 How Sync Works

### Automatic Sync (When Device Comes Online)

```
Device Online → TaskRepository detects →
  1. syncPendingTasks() processes queue
  2. getAllTasks() fetches from server
  3. saveAllTasks() updates local storage
  4. onSyncCompleted?.call() notifies provider
  5. Provider refreshes UI
```

### Manual Sync (Pull-to-Refresh)

```
User Pulls Down → TaskProvider.syncTasks() →
  Repository.manualSync() → Same steps as automatic sync
```

---

## 🧩 Operation Merging Rules

| Existing Op | New Op | Result | Reason |
|-------------|--------|--------|--------|
| `create` | `update` | `create` (updated data) | Task not on server yet |
| `create` | `delete` | *(removed)* | Never existed on server |
| `update` | `update` | `update` (latest) | Normal case |
| `update` | `delete` | `delete` | Delete takes priority |

---

## 🆔 ID Management

### Problem: Local ID vs Server ID

```
Offline: Task created with local ID "1701234567890"
         ↓
Online:  Synced → Server returns ID "abc123xyz"
         ↓
Issue:   UI might still reference "1701234567890"
```

### Solution: ID Mapping + Callback

1. **During Sync:** Track `localID → serverID` mapping
2. **After Sync:** Callback triggers UI refresh
3. **On Update:** Check if task exists by ID, queue if not found

---

## 💡 Common Scenarios

### Scenario 1: Create Offline → Update Offline → Go Online

```dart
// Offline
1. Create task "Buy milk" → local ID: "123"
   Queue: { "123": { op: "create", data: {...} } }

2. Update to "Buy organic milk"
   Queue: { "123": { op: "create", data: {updated} } } // Merged!

// Online
3. Sync executes:
   - POST /tasks → returns server ID: "abc"
   - Remove "123" from queue
   - Delete task "123" from tasksBox
   - Save task "abc" to tasksBox
   - Callback → Provider refreshes UI

Result: ✅ One API call, UI has correct server ID
```

### Scenario 2: Create Offline → Delete Before Sync

```dart
// Offline
1. Create task → Queue: { "123": { op: "create" } }
2. Delete task → Queue: { } // Completely removed!

// Online
3. Sync: Nothing to do (queue empty)

Result: ✅ No unnecessary API calls
```

### Scenario 3: Update Task After Sync (With Stale ID)

```dart
// User holds old reference with local ID "123"
1. Call updateTask(task with ID "123")
2. Repository: getTaskById("123") → null
3. Repository: Add to queue as offline operation
4. Next sync: Skip if task not found

Result: ⚠️ Update is lost (intentional - data safety)
Better: UI refreshes after sync, so user has correct ID
```

---

## 🎯 Best Practices

### ✅ DO

1. **Always refresh UI after sync**
   ```dart
   taskRepository.onSyncCompleted = () => getAllTasks();
   ```

2. **Use pull-to-refresh for manual sync**
   ```dart
   RefreshIndicator(
     onRefresh: () async => await provider.syncTasks(),
     child: ListView(...),
   )
   ```

3. **Check task.id before operations**
   ```dart
   if (task.id == null) return; // Safety check
   taskProvider.updateTask(task);
   ```

4. **Handle offline gracefully**
   ```dart
   try {
     await taskProvider.createTask(task);
   } catch (e) {
     if (e.toString().contains("offline")) {
       showSnackbar("Saved locally. Will sync when online.");
     }
   }
   ```

### ❌ DON'T

1. **Don't use fixed delays for sync**
   ```dart
   // BAD:
   await Future.delayed(Duration(seconds: 2));
   
   // GOOD:
   taskRepository.onSyncCompleted = _onSyncCompleted;
   ```

2. **Don't hold long-lived task references**
   ```dart
   // BAD: EditScreen holds task for minutes
   class EditScreen extends StatefulWidget {
     final TaskModel task; // Stale ID risk!
   }
   
   // BETTER: Pass ID, fetch latest
   class EditScreen extends StatefulWidget {
     final String taskId;
   }
   ```

3. **Don't skip sync queue**
   ```dart
   // BAD: Direct API call when offline
   if (offline) {
     await apiService.createTask(task); // Will fail!
   }
   
   // GOOD: Use repository (handles queue)
   await taskRepository.createTask(task); // Queues if offline
   ```

---

## 🐛 Debugging Tips

### Check Sync Queue

```dart
// In LocalService or via Hive Inspector
final queue = await localService.getSyncQueue();
print("Queue length: ${queue.length}");
for (var item in queue) {
  print("${item['operation']}: ${item['task']['id']}");
}
```

### Check Task IDs

```dart
final tasks = await localService.getAllTasks();
for (var task in tasks) {
  final isLocal = int.tryParse(task.id ?? '') != null;
  print("Task ${task.id}: ${isLocal ? 'LOCAL' : 'SERVER'} ID");
}
```

### Monitor Sync

```dart
// Add logging in TaskRepository
Future<void> syncPendingTasks() async {
  print("=== SYNC START ===");
  print("Queue size: ${queue.length}");
  
  for (var item in queue) {
    print("Processing: ${item['operation']} - ${item['task']['id']}");
    // ... sync logic
  }
  
  print("=== SYNC COMPLETE ===");
}
```

---

## 📊 Performance Considerations

### Sync Speed Estimates

| Queue Size | Estimated Time | Notes |
|------------|----------------|-------|
| 1-5 tasks | 200-500ms | Fast |
| 10-50 tasks | 1-3 seconds | Normal |
| 100+ tasks | 5-15 seconds | Consider pagination |

### Optimization Tips

1. **Batch API calls** (if backend supports)
2. **Limit queue size** (e.g., max 100 operations)
3. **Background sync** (use WorkManager for Android)
4. **Prioritize operations** (delete > update > create)

---

## 🧪 Testing Checklist

- [ ] Create task offline → sync works
- [ ] Create + update offline → single CREATE sync
- [ ] Create + delete offline → no sync
- [ ] Update task after sync → no stale ID error
- [ ] Pull-to-refresh triggers sync
- [ ] Callback invoked after sync
- [ ] UI refreshes with correct IDs
- [ ] Multiple operations sync correctly
- [ ] Sync failure doesn't crash app
- [ ] Queue cleared after successful sync

---

## 📚 Documentation Files

- **`SYNC_LOGIC_EXPLANATION.md`** - Detailed sync architecture
- **`BUG_FIX_SUMMARY.md`** - Stale ID bug fix details
- **`CALLBACK_SYNC_PATTERN.md`** - Callback pattern explanation
- **`QUICK_REFERENCE.md`** - This file

---

## 🆘 Common Issues & Solutions

### Issue: "Task not found" error

**Cause:** UI has stale task reference with local ID

**Solution:** UI will auto-refresh after sync via callback

---

### Issue: Update not syncing

**Cause:** Task ID not found in local storage

**Solution:** 
1. Check if task was deleted
2. Verify sync completed successfully
3. Check queue: `localService.getSyncQueue()`

---

### Issue: Duplicate tasks after sync

**Cause:** Task created both locally and on server

**Solution:**
- Repository handles this automatically
- Check `saveAllTasks()` - it clears old tasks first

---

### Issue: Sync takes too long

**Cause:** Too many operations in queue

**Solutions:**
1. Implement queue size limit
2. Add sync progress indicator
3. Consider batch operations
4. Use background sync

---

**Quick Start:**
1. Read `SYNC_LOGIC_EXPLANATION.md` for architecture
2. Check `CALLBACK_SYNC_PATTERN.md` for implementation
3. Use this file for quick lookups

**Last Updated:** November 27, 2024

