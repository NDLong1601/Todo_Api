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

  Future<void> changeTaskIdFromSyncQueueBox({
    required String oldId,
    required String newId,
  }) async {
    final queueItem = _syncQueueBox.get(oldId);
    await _syncQueueBox.delete(oldId);
    if (queueItem != null) {
      await _syncQueueBox.put(newId, queueItem);
      debugPrint('Changed SyncQueueBox item ID from $oldId to $newId');
    }
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
  Future<void> addToSyncQueue({
    required String operation,
    required TaskModel task,
  }) async {
    if (task.id == null) {
      debugPrint("Cannot add to sync queue without task ID");

      task.copyWith(id: DateTime.now().millisecondsSinceEpoch.toString());
    }
    final payload = {
      "operation": operation,
      "task": task.toJson(),
      "timestamp": DateTime.now().toIso8601String(),
    };
    
    // await _syncQueueBox.add(value);

    await _syncQueueBox.put(task.id!, payload);
    debugPrint("_syncQueueBox length: ${_syncQueueBox.values.length}");
    debugPrint("Added to SyncQueue => OP: $operation | Task: ${task.id}");
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
