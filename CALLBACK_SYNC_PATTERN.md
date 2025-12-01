# 🔄 Callback-Based Sync Pattern

## Problem with Fixed Delay Approach

### ❌ Previous Implementation (Bad)

```dart
// TaskProvider
void _setupConnectivityListener() {
  taskRepository.connectivity.onConnectivityChanged.listen((result) async {
    if (!result.contains(ConnectivityResult.none)) {
      await Future.delayed(const Duration(seconds: 2)); // ← Fixed 2 second delay
      await getAllTasks();
    }
  });
}
```

**Issues:**
- ❌ **Fixed delay is unreliable**: 2 seconds might be too short for 100 tasks or too long for 1 task
- ❌ **Wastes time**: User waits unnecessarily if sync completes in 500ms
- ❌ **Race conditions**: If sync takes 5 seconds, UI refreshes before sync completes
- ❌ **Poor UX**: User sees stale data during the delay
- ❌ **Not scalable**: Delay doesn't adapt to sync workload

---

## ✅ Solution: Callback Pattern

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      TaskProvider                           │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │  1. Register callback on init:                      │    │
│  │     taskRepository.onSyncCompleted = _onSyncCompleted │  │
│  └────────────────────────────────────────────────────┘    │
│                          ↓                                   │
│  ┌────────────────────────────────────────────────────┐    │
│  │  2. When callback invoked:                          │    │
│  │     → Refresh task list from local storage          │    │
│  │     → Update UI with latest server IDs              │    │
│  └────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                          ↑
                          │ Callback invoked when sync completes
                          │
┌─────────────────────────────────────────────────────────────┐
│                    TaskRepository                           │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │  Connectivity Listener:                             │    │
│  │  1. Device comes online                             │    │
│  │  2. Sync pending tasks (may take 100ms to 10s+)    │    │
│  │  3. Fetch tasks from server                         │    │
│  │  4. Update local storage                            │    │
│  │  5. Call onSyncCompleted?.call() ← Immediate!      │    │
│  └────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

---

## Implementation Details

### 1. TaskRepository: Define Callback

```dart
class TaskRepository {
  // Callback to notify when sync completes
  // This allows UI to refresh after sync without using fixed delays
  VoidCallback? onSyncCompleted;
  
  void _setupConnectivityListener() {
    connectivity.onConnectivityChanged.listen((result) async {
      if (!result.contains(ConnectivityResult.none)) {
        try {
          // Sync can take varying time depending on queue size
          await syncPendingTasks();
          
          // Refresh from server
          final remoteTasks = await apiService.getAllTasks();
          await localService.saveAllTasks(remoteTasks);
          
          // Immediately notify listeners - no fixed delay!
          onSyncCompleted?.call();
        } catch (e) {
          // Still notify even on error
          onSyncCompleted?.call();
        }
      }
    });
  }
  
  // Manual sync for pull-to-refresh
  Future<bool> manualSync() async {
    if (!await _isOnline()) return false;
    
    try {
      await syncPendingTasks();
      final remoteTasks = await apiService.getAllTasks();
      await localService.saveAllTasks(remoteTasks);
      
      onSyncCompleted?.call();
      return true;
    } catch (e) {
      onSyncCompleted?.call();
      return false;
    }
  }
}
```

### 2. TaskProvider: Register Callback

```dart
class TaskProvider extends ChangeNotifier {
  TaskRepository taskRepository = TaskRepository();
  
  Future<void> init() async {
    await taskRepository.init();
    
    // Register callback - will be called when sync completes
    taskRepository.onSyncCompleted = _onSyncCompleted;
    
    await getAllTasks();
  }
  
  // Callback handler - invoked immediately when sync completes
  void _onSyncCompleted() {
    debugPrint('Sync completed, refreshing task list...');
    getAllTasks(); // Refresh UI with updated data
  }
  
  // Manual sync for pull-to-refresh
  Future<bool> syncTasks() async {
    try {
      _setLoading(true);
      final bool success = await taskRepository.manualSync();
      // Task list will be refreshed via onSyncCompleted callback
      return success;
    } finally {
      _setLoading(false);
    }
  }
}
```

### 3. UI: Pull-to-Refresh Integration

```dart
// HomeScreen
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        return RefreshIndicator(
          onRefresh: () async {
            // Triggers manual sync, which calls callback on completion
            await taskProvider.syncTasks();
          },
          child: ListView.builder(
            itemCount: taskProvider.pendingTasks.length,
            itemBuilder: (context, index) {
              return TaskItem(task: taskProvider.pendingTasks[index]);
            },
          ),
        );
      },
    ),
  );
}
```

---

## Benefits of Callback Approach

### ✅ **1. Adaptive Timing**

```
Scenario A: 1 task in queue
├─ Sync takes: 200ms
└─ UI refreshes: Immediately after 200ms ✓

Scenario B: 100 tasks in queue
├─ Sync takes: 8 seconds
└─ UI refreshes: Immediately after 8 seconds ✓

vs Fixed Delay:
├─ Scenario A: Wastes 1.8 seconds waiting
└─ Scenario B: UI refreshes before sync completes (stale data!)
```

### ✅ **2. No Race Conditions**

```dart
// Callback pattern guarantees order:
1. Sync starts
2. Sync completes (all data updated)
3. Callback invoked
4. UI refreshes with correct data

// Fixed delay has race condition:
1. Sync starts
2. Timer starts (2 seconds)
3. Timer expires → UI refreshes (but sync might not be done!)
4. Sync completes (too late, UI has wrong data)
```

### ✅ **3. Better User Experience**

| Metric | Fixed Delay | Callback |
|--------|-------------|----------|
| **Min wait time** | 2 seconds | ~200ms |
| **Max wait time** | 2 seconds (even if sync takes 5s!) | Actual sync time |
| **Data freshness** | Potentially stale | Always fresh |
| **Reliability** | Low | High |
| **Scalability** | Poor | Excellent |

### ✅ **4. Easy to Extend**

Adding more listeners is trivial:

```dart
// Multiple listeners pattern
class TaskRepository {
  final List<VoidCallback> _syncCallbacks = [];
  
  void addSyncListener(VoidCallback callback) {
    _syncCallbacks.add(callback);
  }
  
  void _notifySyncCompleted() {
    for (var callback in _syncCallbacks) {
      callback.call();
    }
  }
}

// Usage:
taskRepository.addSyncListener(() => print('Listener 1'));
taskRepository.addSyncListener(() => updateUI());
taskRepository.addSyncListener(() => sendAnalytics());
```

---

## Advanced: Stream-Based Pattern (Alternative)

For more complex scenarios, use Dart Streams:

### Repository Implementation

```dart
class TaskRepository {
  // Stream controller for sync events
  final StreamController<SyncStatus> _syncStatusController = 
      StreamController<SyncStatus>.broadcast();
  
  // Public stream
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;
  
  void _setupConnectivityListener() {
    connectivity.onConnectivityChanged.listen((result) async {
      if (!result.contains(ConnectivityResult.none)) {
        try {
          _syncStatusController.add(SyncStatus.started);
          
          await syncPendingTasks();
          final remoteTasks = await apiService.getAllTasks();
          await localService.saveAllTasks(remoteTasks);
          
          _syncStatusController.add(SyncStatus.completed);
        } catch (e) {
          _syncStatusController.add(SyncStatus.failed);
        }
      }
    });
  }
  
  void dispose() {
    _syncStatusController.close();
  }
}

enum SyncStatus {
  idle,
  started,
  completed,
  failed,
}
```

### Provider Implementation

```dart
class TaskProvider extends ChangeNotifier {
  StreamSubscription<SyncStatus>? _syncSubscription;
  
  Future<void> init() async {
    await taskRepository.init();
    
    // Listen to sync status stream
    _syncSubscription = taskRepository.syncStatusStream.listen((status) {
      switch (status) {
        case SyncStatus.started:
          debugPrint('Sync started...');
          break;
        case SyncStatus.completed:
          debugPrint('Sync completed!');
          getAllTasks(); // Refresh UI
          break;
        case SyncStatus.failed:
          debugPrint('Sync failed!');
          _setErrorMsg('Sync failed');
          break;
        default:
          break;
      }
    });
    
    await getAllTasks();
  }
  
  @override
  void dispose() {
    _syncSubscription?.cancel();
    super.dispose();
  }
}
```

**Benefits of Stream pattern:**
- More granular status updates (started, progress, completed, failed)
- Multiple listeners without managing list manually
- Can emit sync progress: `_syncStatusController.add(SyncProgress(5, 100))`
- Better error handling with different event types

---

## Comparison: All Approaches

| Feature | Fixed Delay | Callback | Stream |
|---------|-------------|----------|--------|
| **Complexity** | Low | Low | Medium |
| **Timing Accuracy** | Poor | Excellent | Excellent |
| **Multiple Listeners** | No | Manual | Built-in |
| **Status Granularity** | None | Complete/Error | Custom events |
| **Memory Overhead** | Minimal | Minimal | Small (stream) |
| **Best For** | Never | Simple apps | Complex apps |

---

## Recommended Pattern by App Size

### Small Apps (< 5 screens)
✅ **Use: Simple Callback**
```dart
taskRepository.onSyncCompleted = _onSyncCompleted;
```

### Medium Apps (5-20 screens)
✅ **Use: Callback with Multiple Listeners**
```dart
taskRepository.addSyncListener(() => updateUI());
taskRepository.addSyncListener(() => showNotification());
```

### Large Apps (20+ screens)
✅ **Use: Stream Pattern**
```dart
taskRepository.syncStatusStream.listen((status) { ... });
```

---

## Testing

### Test Callback Invocation

```dart
test('onSyncCompleted is called after sync', () async {
  final repository = TaskRepository();
  bool callbackInvoked = false;
  
  repository.onSyncCompleted = () {
    callbackInvoked = true;
  };
  
  await repository.manualSync();
  
  expect(callbackInvoked, true);
});
```

### Test Timing

```dart
test('UI refreshes immediately after sync completes', () async {
  final stopwatch = Stopwatch()..start();
  
  // Sync 50 tasks
  await repository.syncPendingTasks();
  final syncTime = stopwatch.elapsedMilliseconds;
  
  // Reset stopwatch
  stopwatch.reset();
  
  // Callback should be invoked immediately (< 10ms overhead)
  bool called = false;
  repository.onSyncCompleted = () {
    called = true;
  };
  
  await repository.manualSync();
  final callbackTime = stopwatch.elapsedMilliseconds;
  
  expect(called, true);
  expect(callbackTime - syncTime, lessThan(10)); // < 10ms overhead
});
```

---

## Migration Guide

### Step 1: Update Repository

```dart
// Add callback property
VoidCallback? onSyncCompleted;

// Call it after sync
onSyncCompleted?.call();
```

### Step 2: Update Provider

```dart
// Remove fixed delay listener
// taskRepository.connectivity.onConnectivityChanged.listen(...);

// Register callback instead
taskRepository.onSyncCompleted = _onSyncCompleted;
```

### Step 3: Test

1. Create task offline
2. Go online
3. Check logs: "Sync completed, refreshing task list..."
4. Verify UI updates immediately

---

## Conclusion

**Key Takeaway:** Always prefer **event-driven** patterns over **time-driven** patterns for asynchronous operations.

The callback pattern:
- ✅ Adapts to actual operation duration
- ✅ Eliminates race conditions
- ✅ Improves user experience
- ✅ Scales with data volume
- ✅ Simple to implement and maintain

**Current Implementation:**
- Repository: Defines `onSyncCompleted` callback
- Provider: Registers callback, refreshes on invocation
- UI: Uses `RefreshIndicator` for manual sync

---

**Last Updated:** November 27, 2024  
**Pattern:** Callback-based sync notification  
**Status:** Implemented ✅

