import 'package:flutter/material.dart';
import 'package:todo_api/models/task_model.dart';
import 'package:todo_api/repositories/task_repository.dart';

class TaskProvider extends ChangeNotifier {
  TaskRepository taskRepository = TaskRepository();

  /// define all state

  /// private, setter and getter
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMsg;
  String get errorMsg => _errorMsg ?? '';

  List<TaskModel> _taskList = [];

  List<TaskModel> get pendingTasks =>
      _taskList.where((task) => task.isPending).toList();

  List<TaskModel> get completedTasks =>
      _taskList.where((task) => task.isCompleted && task.id != null).toList();

  /// Validate -> enable or disable add button

  Future<void> init() async {
    await taskRepository.init();
    await getAllTasks();
  }

  /// Get All Tasks
  Future<void> getAllTasks() async {
    try {
      _setLoading(true);
      _taskList = await taskRepository.getAllTasks();
      notifyListeners();
    } catch (e, stackTrace) {
      _setErrorMsg(e.toString());
      debugPrint(
        'Error while getAllTasks in TaskProvider: $e, stackTrace: $stackTrace',
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Delete Task
  Future<void> deleteTask(String id) async {
    try {
      _setLoading(true);
      await taskRepository.deleteTaskByID(id);
      notifyListeners();

      _taskList.removeWhere((task) => task.id == id);
      notifyListeners();
    } catch (e, stackTrace) {
      _setErrorMsg(e.toString());
      debugPrint(
        'Error while deleteTask in TaskProvider: $e, stackTrace: $stackTrace',
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Create task
  Future<void> createTask(TaskModel task) async {
    try {
      _setLoading(true);

      /// Call api create task
      final createTask = await taskRepository.createTask(task);

      /// Api create success, add task created to _taskList
      /// TODO: Check flow create task again

      _taskList.add(createTask);
      notifyListeners();
    } catch (e, stackTrace) {
      _setErrorMsg(e.toString());
      debugPrint(
        'Error while createTask in TaskProvider: $e, stackTrace: $stackTrace',
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Update Task
  Future<void> updateTask(TaskModel task) async {
    try {
      _setLoading(true);
      await taskRepository.updateTask(task);

      /// Update _taskList
      final index = _taskList.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _taskList[index] = task;
      }
      notifyListeners();
    } catch (e, stackTrace) {
      _setErrorMsg(e.toString());
      debugPrint(
        'Error while updateTask in TaskProvider: $e, stackTrace: $stackTrace',
      );
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool isLoading) {
    if (isLoading == _isLoading) return;
    _isLoading = isLoading;
    notifyListeners();
  }

  void _setErrorMsg(String errorMsg) {
    _errorMsg = errorMsg;
    notifyListeners();
  }
}
