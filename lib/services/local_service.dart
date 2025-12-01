import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:hive/hive.dart';
import 'package:todo_api/models/task_model.dart';

class LocalService {
  static const String _taskBoxName = 'tasksBox';
  static const String _syncQueueBoxName = 'syncQueueBox';

  /// We have 2 boxes:
  /// 1. tasksBox: store all tasks locally
  /// 2. syncQueueBox: store all operations to sync with API later
  late Box<TaskModel> _taskBox;
  late Box<Map> _syncQueueBox;

  /// Initialize Hive boxes
  Future<void> init() async {
    debugPrint('Initializing LocalService...');
    _taskBox = await Hive.openBox<TaskModel>(_taskBoxName);
    _syncQueueBox = await Hive.openBox<Map>(_syncQueueBoxName);
    debugPrint('LocalService initialized.');
  }

  /// Get All Tasks from local storage
  Future<List<TaskModel>> getAllTasks() async {
    debugPrint('Fetching all tasks from local storage...');
    debugPrint('Total tasks found: ${_taskBox.length}');
    return _taskBox.values.toList();
  }

  /// Get Task by ID from local storage
  ///
  /// Returns the task if found, null otherwise.
  /// This is used during sync to get the current task ID
  /// (which might have changed from local ID to server ID)
  Future<TaskModel?> getTaskById(String id) async {
    return _taskBox.get(id);
  }

  /// Save All Tasks to local storage
  Future<void> saveAllTasks(List<TaskModel> tasks) async {
    debugPrint('Saving all tasks to local storage...');
    await _taskBox.clear();
    for (var task in tasks) {
      await _taskBox.put(task.id, task);
      debugPrint('Task with ID ${task.id} saved to local storage.');
    }
    debugPrint('All tasks saved to local storage.');
    debugPrint('Total tasks saved: ${_taskBox.length}');
  }

  /// Delete Task by ID from local storage
  Future<void> deleteTask(TaskModel task) async {
    await _taskBox.delete(task.id);
    debugPrint('Task with ID ${task.id} deleted from local storage.');
  }

  /// Save one Task to local storage
  Future<void> saveTask(TaskModel task) async {
    await _taskBox.put(
      task.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      task.copyWith(
        id: task.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      ),
    );
    debugPrint(
      'Task with ID ${task.id ?? DateTime.now().millisecondsSinceEpoch.toString()} saved to local storage.',
    );
  }

  /// Update Task in local storage
  Future<void> updateLocalTask(TaskModel task) async {
    if (task.id == null) {
      debugPrint("Cannot update local task without ID");
      return;
    }

    await _taskBox.put(task.id, task);
    debugPrint("Updated local task: ${task.id}");
  }

  /// Sync Queue Operations -> sync all local Task from _syncQueueBoxName to API
  /// Save Map to syncQueueBox
  /// Map structure:
  /// status operation: 'create' | 'update' | 'delete'
  /// task data: TaskModel.toJson()
  /// timestamp: DateTime.now().toIso8601String()
  /// example:
  /// {
  ///   "operation": "create",
  ///   "task": {...},
  ///   "timestamp": "2024-10-01T12:34:56.789Z"
  /// }
  ///
  /// Add operation to sync queue for later synchronization with API
  ///
  /// This method manages the sync queue intelligently by merging operations
  /// to prevent conflicts when syncing local-only tasks with the server.
  ///
  /// **Operation Types:**
  /// - `create`: Task was created locally and needs to be posted to API
  /// - `update`: Task exists on server and needs to be updated
  /// - `delete`: Task needs to be deleted from server
  ///
  /// **Smart Operation Merging:**
  /// The method merges operations to avoid sending invalid requests to the API:
  ///
  /// 1. **CREATE + UPDATE = CREATE**
  ///    - When a task is created offline (with local ID) and then updated
  ///    - The queue keeps only the CREATE operation with latest data
  ///    - Prevents sending UPDATE with local ID that doesn't exist on server
  ///    - Example:
  ///      * Offline: create task (id: "local123")
  ///      * Offline: update task (id: "local123")
  ///      * Sync: sends only CREATE with latest data, gets real server ID
  ///
  /// 2. **CREATE + DELETE = REMOVE**
  ///    - When a task is created offline and deleted before sync
  ///    - The operation is removed from queue entirely
  ///    - Prevents unnecessary API calls for tasks that never existed on server
  ///    - Example:
  ///      * Offline: create task (id: "local456")
  ///      * Offline: delete task (id: "local456")
  ///      * Sync: nothing to do, operation removed from queue
  ///
  /// 3. **Other cases: REPLACE**
  ///    - UPDATE + UPDATE = Latest UPDATE
  ///    - UPDATE + DELETE = DELETE
  ///    - DELETE + anything = Not possible (task already deleted locally)
  ///
  /// **Parameters:**
  /// - [operation]: The operation type ("create", "update", or "delete")
  /// - [task]: The task model to be synced
  ///
  /// **Storage Structure:**
  /// Each item in sync queue is stored as:
  /// ```dart
  /// {
  ///   "operation": "create" | "update" | "delete",
  ///   "task": { TaskModel.toJson() },
  ///   "timestamp": "2024-10-01T12:34:56.789Z"
  /// }
  /// ```
  ///
  /// **Key Strategy:**
  /// - Uses task.id as the key in _syncQueueBox
  /// - This ensures only one pending operation per task
  /// - New operations replace or merge with existing ones
  ///
  /// **Example Usage:**
  /// ```dart
  /// // Scenario 1: Offline create then update
  /// await addToSyncQueue(operation: "create", task: newTask);
  /// // Queue: { "local123": { operation: "create", ... } }
  ///
  /// await addToSyncQueue(operation: "update", task: updatedTask);
  /// // Queue: { "local123": { operation: "create", task: updatedTask } }
  /// // Merged! Still CREATE but with updated data
  ///
  /// // Scenario 2: Offline create then delete
  /// await addToSyncQueue(operation: "create", task: newTask);
  /// await addToSyncQueue(operation: "delete", task: newTask);
  /// // Queue: empty - operation removed
  /// ```
  Future<void> addToSyncQueue({
    required String operation,
    required TaskModel task,
  }) async {
    // Ensure task has an ID before adding to queue
    // If no ID exists, generate a local ID using current timestamp
    TaskModel ensuredTask = task;
    if (ensuredTask.id == null) {
      final String generatedId = DateTime.now().millisecondsSinceEpoch
          .toString();
      ensuredTask = ensuredTask.copyWith(id: generatedId);
      debugPrint("Generated local ID $generatedId for sync queue task");
    }

    // Check if there's already a pending operation for this task
    // This is the key to merging operations intelligently
    final Map<dynamic, dynamic>? existingRaw = _syncQueueBox.get(
      ensuredTask.id,
    );

    final String currentTimestamp = DateTime.now().toIso8601String();
    Map<String, dynamic> payload;

    if (existingRaw != null) {
      // Found existing operation - need to decide how to merge

      // Convert to strongly-typed Map for safe access
      final Map<String, dynamic> existing = existingRaw.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      final String? existingOperation = existing["operation"] as String?;

      // CASE 1: UPDATE on top of CREATE
      // Keep CREATE operation but update the task data
      // This prevents sending UPDATE with local ID to server
      if (operation == "update" && existingOperation == "create") {
        payload = {
          "operation": "create", // Keep as CREATE!
          "task": ensuredTask.toJson(), // Use latest task data
          "timestamp": currentTimestamp,
        };
        debugPrint(
          "Merged UPDATE into existing CREATE for task ${ensuredTask.id} in SyncQueue",
        );
      }
      // CASE 2: DELETE on top of CREATE
      // Task was created locally and deleted before sync
      // Remove from queue entirely - no need to sync with server
      else if (operation == "delete" && existingOperation == "create") {
        await _syncQueueBox.delete(ensuredTask.id);
        debugPrint(
          "Removed CREATE operation from SyncQueue for task ${ensuredTask.id} because task was deleted before sync",
        );
        return; // Exit early - nothing to add
      }
      // CASE 3: All other combinations
      // Simply replace with new operation
      else {
        payload = {
          "operation": operation,
          "task": ensuredTask.toJson(),
          "timestamp": currentTimestamp,
        };
      }
    } else {
      // No existing operation - create new entry
      payload = {
        "operation": operation,
        "task": ensuredTask.toJson(),
        "timestamp": currentTimestamp,
      };
    }

    // Save to sync queue using task ID as key
    // This automatically replaces any existing operation for this task
    await _syncQueueBox.put(ensuredTask.id!, payload);
    debugPrint("_syncQueueBox length: ${_syncQueueBox.values.length}");
    debugPrint(
      "Added to SyncQueue => OP: $operation | Task: ${ensuredTask.id}",
    );
  }

  Future<List<Map>> getSyncQueue() async {
    return _syncQueueBox.values.toList();
  }

  Future<void> clearSyncQueue() async {
    await _syncQueueBox.clear();
    debugPrint("Cleared SyncQueue");
  }

  Future<void> removeFromSyncQueue(String key) async {
    await _syncQueueBox.delete(key);
    debugPrint("Removed item with key $key from SyncQueue");
  }
}
