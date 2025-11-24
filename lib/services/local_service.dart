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
    }
    debugPrint('All tasks saved to local storage.');
    debugPrint('Total tasks saved: ${_taskBox.length}');
  }

  /// Delete Task by ID from local storage

  /// Save one Task to local storage

  /// Update Task in local storage

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
}
