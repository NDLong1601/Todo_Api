# 📱 Offline-First Sync Logic Documentation

## 🎯 Overview

This document explains the offline-first synchronization logic implemented in the Todo API app. The system allows users to create, update, and delete tasks even when offline, then automatically syncs changes when connectivity is restored.

---

## 🏗️ Architecture Components

### 1. **TaskRepository** (`lib/repositories/task_repository.dart`)
- Central coordinator for all task operations
- Manages online/offline decision making
- Handles sync queue processing

### 2. **LocalService** (`lib/services/local_service.dart`)
- Manages Hive local storage
- Maintains two boxes:
  - `tasksBox`: Stores actual task data
  - `syncQueueBox`: Stores pending operations to sync

### 3. **ApiService** (`lib/services/api_service.dart`)
- Handles all HTTP requests to the backend
- CRUD operations: create, read, update, delete

---

## 🔄 Sync Queue Design

### Storage Structure

Each item in the sync queue is stored with the **task ID as the key**:

```dart
Key: task.id (String)
Value: {
  "operation": "create" | "update" | "delete",
  "task": { /* TaskModel.toJson() */ },
  "timestamp": "2024-10-01T12:34:56.789Z"
}
```

### Why Use Task ID as Key?

✅ **Ensures only ONE pending operation per task**
- New operations automatically replace old ones
- Prevents duplicate sync requests
- Enables intelligent operation merging

---

## 🧠 Smart Operation Merging

### Problem: Local ID vs Server ID Conflict

When a task is created offline:
1. System generates a **local ID** (timestamp-based)
2. Task is saved locally with this ID
3. When synced, server creates task with **new server ID**
4. Local ID ≠ Server ID → conflict!

### Solution: Intelligent Merging

The `addToSyncQueue()` method merges operations to prevent invalid API calls:

#### **Scenario 1: CREATE + UPDATE → CREATE**

```
Timeline:
├─ [OFFLINE] User creates task → id: "1234567890"
│  Queue: { "1234567890": { operation: "create", task: {...} } }
│
├─ [OFFLINE] User updates same task → id: "1234567890"
│  Queue: { "1234567890": { operation: "create", task: {updated...} } }
│  ⚡ Merged! Operation stays "create" but with latest data
│
└─ [ONLINE] Sync executes:
   ✅ POST /tasks with latest data
   ✅ Gets server ID: "serverABC123"
   ✅ Replaces local task "1234567890" with "serverABC123"
```

**Why?**
- Prevents sending `PUT /tasks/1234567890` to server
- Server doesn't know about local ID "1234567890"
- Would result in 404 or validation error

#### **Scenario 2: CREATE + DELETE → REMOVE**

```
Timeline:
├─ [OFFLINE] User creates task → id: "1234567890"
│  Queue: { "1234567890": { operation: "create", task: {...} } }
│
├─ [OFFLINE] User deletes same task → id: "1234567890"
│  Queue: { } ← Completely removed!
│
└─ [ONLINE] Sync executes:
   ✅ Nothing to do - task never existed on server
```

**Why?**
- Task was created and deleted before ever syncing
- No need to inform server about something it never knew
- Saves unnecessary API calls

#### **Scenario 3: Other Cases → REPLACE**

```
UPDATE + UPDATE → Latest UPDATE
UPDATE + DELETE → DELETE
DELETE + X → Not possible (task already deleted locally)
```

---

## 🚀 Sync Flow When Online

### Trigger Points

1. **App startup** → `init()` checks connectivity
2. **Connectivity restored** → `onConnectivityChanged` listener
3. **Manual refresh** → Pull-to-refresh gesture

### Sync Process (`syncPendingTasks()`)

```
For each item in sync queue:
┌──────────────────────────────────────────────┐
│  1. Get operation type and task data         │
│  2. Store ORIGINAL task ID                   │
│     (critical for removing from queue later) │
└──────────────────────────────────────────────┘
               ↓
        ┌──────┴──────┐
        │  Operation? │
        └──────┬──────┘
         ╱     │     ╲
    CREATE  UPDATE  DELETE
       │       │       │
       ↓       ↓       ↓
```

#### **CREATE Operation**

```dart
1. Call apiService.createTask(task)
   ↓ Returns TaskModel with server ID
2. Remove from queue using ORIGINAL local ID
   ↓ Must use local ID because that's the key in queue
3. Delete old task entry (local ID)
4. Save new task entry (server ID)
```

**⚠️ Critical:** We call `apiService.createTask()` directly, NOT `repository.createTask()`!
- `repository.createTask()` would add to queue again → infinite loop
- Direct API call bypasses queue logic

#### **UPDATE Operation**

```dart
1. Call apiService.updateTask(task)
2. Remove from queue using task ID
3. Update local storage with same task
```

#### **DELETE Operation**

```dart
1. Call apiService.deleteTask(task.id)
2. Remove from queue using task ID
3. Delete from local storage
```

---

## 🎬 Complete User Scenarios

### Scenario A: Simple Offline Create

```
Step 1: User creates task "Buy milk" (offline)
├─ Generate local ID: "1701234567890"
├─ Save to tasksBox with local ID
└─ Add to syncQueueBox:
   {
     "1701234567890": {
       "operation": "create",
       "task": { "id": "1701234567890", "title": "Buy milk", ... }
     }
   }

Step 2: Device comes online
├─ syncPendingTasks() triggered
├─ Process queue item:
│  ├─ POST /tasks { "title": "Buy milk", ... }
│  ├─ Server responds with ID "abc123xyz"
│  ├─ Remove "1701234567890" from syncQueueBox
│  ├─ Delete task "1701234567890" from tasksBox
│  └─ Save task "abc123xyz" to tasksBox
└─ ✅ Sync complete!
```

### Scenario B: Offline Create + Update (The Bug You Reported)

```
Step 1: User creates task "Buy milk" (offline)
├─ Local ID: "1701234567890"
└─ syncQueueBox: { "1701234567890": { operation: "create", ... } }

Step 2: User edits to "Buy organic milk" (still offline)
├─ Update local task "1701234567890"
├─ Call addToSyncQueue("update", task)
├─ ⚡ Merge logic detects existing "create" operation
├─ Keep operation as "create" but update task data
└─ syncQueueBox: { "1701234567890": { operation: "create", task: "Buy organic milk" } }

Step 3: Device comes online
├─ syncPendingTasks() processes:
│  ├─ Operation: "create" (not "update"!)
│  ├─ POST /tasks { "title": "Buy organic milk", ... }
│  ├─ Server creates with ID "abc123xyz"
│  ├─ Remove "1701234567890" from queue
│  └─ Replace local task
└─ ✅ Success! No "update with local ID" error!
```

**Before Fix:** Would have sent `PUT /tasks/1701234567890` → 404 Error
**After Fix:** Sends `POST /tasks` → Success!

### Scenario C: Offline Create + Delete

```
Step 1: User creates task "Test task" (offline)
└─ syncQueueBox: { "1701234567890": { operation: "create", ... } }

Step 2: User deletes it (still offline)
├─ Delete from tasksBox
├─ Call addToSyncQueue("delete", task)
├─ ⚡ Merge logic detects "delete" on "create"
└─ syncQueueBox: { } ← Entry completely removed!

Step 3: Device comes online
└─ ✅ Nothing to sync - queue is empty!
```

---

## 🛡️ Error Handling

### Individual Operation Failures

```dart
try {
  // Process sync operation
} catch (e, st) {
  debugPrint("Sync item $i failed: $e\n$st");
  // Continue with next item - don't stop entire sync!
}
```

**Strategy:** Fail gracefully
- One failed operation doesn't block others
- Failed operations remain in queue
- Will retry on next sync attempt

### API Call Failures During Regular Operations

```dart
if (await _isOnline()) {
  try {
    await apiService.updateTask(task);
  } catch (e) {
    // API failed even though we're "online"
    // Fall back to offline behavior
    await _updateTaskInLocal(task); // Add to queue
  }
}
```

**Strategy:** Automatic fallback to offline mode
- Network can be unreliable even when "connected"
- If API call fails, treat as offline
- Operation goes into queue for later retry

---

## 🔍 Key Implementation Details

### 1. Why Copy the Queue Before Processing?

```dart
final queue = await localService.getSyncQueue();
final copiedQueue = List<Map>.from(queue);

for (var item in copiedQueue) { ... }
```

**Reason:** Avoid concurrent modification
- Original queue might change during iteration
- Sync process modifies the queue (removes items)
- Copy ensures stable iteration

### 2. Store Original ID Before Processing

```dart
final task = TaskModel.fromJson(taskJson);
final String originalTaskId = task.id!; // ← Store it!

// ... later ...
await localService.removeFromSyncQueue(originalTaskId);
```

**Reason:** Task ID might change during sync
- CREATE operations get new server ID
- Must use original ID to find item in queue
- Queue key is the original local ID

### 3. Order of Operations in CREATE Sync

```dart
// ✅ Correct order:
await localService.removeFromSyncQueue(originalTaskId);  // 1. Remove from queue first
await localService.deleteTask(task);                     // 2. Delete old local entry
await localService.saveTask(createdTask);                // 3. Save new server entry

// ❌ Wrong order:
await localService.saveTask(createdTask);                // Overwrites task in tasksBox
await localService.removeFromSyncQueue(originalTaskId);  // Can't find old ID!
```

**Reason:** Maintain data consistency
- Remove from queue immediately after API success
- Then clean up and update local storage
- Prevents partial state if operation is interrupted

---

## 📊 Benefits of This Design

### ✅ Offline-First User Experience
- App works seamlessly without internet
- No blocking or error messages
- Changes appear instant to user

### ✅ Data Consistency
- Smart merging prevents invalid requests
- Automatic ID mapping (local → server)
- No duplicate operations

### ✅ Fault Tolerance
- Individual failures don't stop sync
- Automatic retry on next connectivity
- Graceful degradation

### ✅ Efficient API Usage
- Merged operations reduce API calls
- CREATE+DELETE scenarios avoid unnecessary sync
- Only latest state is synced

---

## 🔧 Testing Scenarios

### Manual Testing Checklist

- [ ] **Offline Create → Online Sync**
  - Create task offline
  - Go online
  - Verify task appears with server ID

- [ ] **Offline Create + Update → Online Sync**
  - Create task offline
  - Edit task offline (multiple times)
  - Go online
  - Verify only one CREATE with latest data

- [ ] **Offline Create + Delete → Online Sync**
  - Create task offline
  - Delete task offline
  - Go online
  - Verify no API calls made (check logs)

- [ ] **Offline Update → Online Sync**
  - Create task online
  - Go offline
  - Edit task
  - Go online
  - Verify UPDATE succeeds

- [ ] **Offline Delete → Online Sync**
  - Create task online
  - Go offline
  - Delete task
  - Go online
  - Verify DELETE succeeds

- [ ] **Network Failure During Operation**
  - Go online
  - Create/update/delete task
  - Simulate network failure during API call
  - Verify operation goes to queue

---

## 🐛 Common Pitfalls Avoided

### ❌ Pitfall 1: Calling `repository.createTask()` from Sync

```dart
// WRONG:
if (operation == "create") {
  await createTask(task); // ← Adds to queue again!
}
```

**Problem:** Infinite loop - sync creates queue entry, which gets synced, which creates queue entry...

**Solution:** Call `apiService.createTask()` directly in sync logic.

### ❌ Pitfall 2: Removing from Queue with Wrong ID

```dart
// WRONG:
if (operation == "create") {
  final TaskModel created = await apiService.createTask(task);
  await localService.removeFromSyncQueue(created.id!); // ← New server ID!
}
```

**Problem:** Queue key is the original local ID, not the new server ID.

**Solution:** Store original ID before any changes, use it for removal.

### ❌ Pitfall 3: Not Merging CREATE + UPDATE

```dart
// WRONG:
await _syncQueueBox.put(task.id, {
  "operation": operation, // ← Always replace with new operation
  "task": task.toJson(),
});
```

**Problem:** UPDATE with local ID gets sent to server → 404 error.

**Solution:** Check existing operation, merge intelligently.

---

## 📝 Summary

This offline-first sync implementation provides:

1. **Seamless UX:** Users never wait for network
2. **Intelligent Merging:** Prevents invalid API calls
3. **Robust Error Handling:** Graceful failure recovery
4. **Efficient Syncing:** Minimal API calls
5. **Data Consistency:** Proper ID mapping and state management

The key insight is treating the sync queue as a **state machine** where operations can be merged based on context, rather than a simple queue where all operations are independent.

---

**Last Updated:** November 27, 2024  
**Version:** 1.0  
**Author:** Development Team

