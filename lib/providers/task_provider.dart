import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:provider/provider.dart';
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

  /// Get All Tasks
  Future<void> getAllTasks() async {
    try {
      _isLoading = true;
      notifyListeners();
      _taskList = await taskRepository.getAllTasks();
      notifyListeners();
    } catch (e, stackTrace) {
      _errorMsg = e.toString();
      debugPrint(
        'Error while getAllTasks in TaskProvider: $e, stackTrace: $stackTrace',
      );
    } finally {
      _isLoading = false;
    }
  }

  /// Delete Task
  Future<void> deleteTask(String id) async {
    try {
      _isLoading = true;
      notifyListeners();
      await taskRepository.deleteTaskByID(id);
      notifyListeners();

      _taskList.removeWhere((task) => task.id == id);
      notifyListeners();
    } catch (e, stackTrace) {
      _errorMsg = e.toString();
      debugPrint(
        'Error while deleteTask in TaskProvider: $e, stackTrace: $stackTrace',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update Task
  Future<void> updateTask(String id, TaskModel task) async {
    try {
      _isLoading = true;
      notifyListeners();

      final updateTask = await taskRepository.updateTask(id, task);
      final index = _taskList.indexWhere((t) => t.id == id);
      if (index != -1) {
        _taskList[index] = updateTask;
      }

      notifyListeners();
    } catch (e, stackTrace) {
      _errorMsg = e.toString();
      debugPrint(
        'Error while updateTask in TaskProvider: $e, stackTrace: $stackTrace',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create task
  Future<void> createTask(TaskModel task) async {
    try {
      _isLoading = true;
      notifyListeners();

      final createTask = await taskRepository.createTask(task);
      _taskList.add(createTask);
      notifyListeners();
    } catch (e, stackTrace) {
      _errorMsg = e.toString();
      debugPrint(
        'Error while createTask in TaskProvider: $e, stackTrace: $stackTrace',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update Complete Task
  Future<void> updateCompleteTask(String id) async {
    try {
      _isLoading = true;
      notifyListeners();

      final updateCompletedTask = await taskRepository.updateCompleteTask(id);
      final index = _taskList.indexWhere((t) => t.id == id);
      if (index != -1) {
        _taskList[index] = updateCompletedTask;
      }
    } catch (e, stackTrace) {
      _errorMsg = e.toString();
      debugPrint(
        'Error while completeTask in TaskProvider: $e, stackTrace: $stackTrace',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> returnTask(TaskModel task) async {
    final updated = task.copyWith(status: "pendiente");

    await taskRepository.updateTask(updated.id!, updated);

    await getAllTasks();
    _isLoading = true;
  }

  Future<void> markCompleted(String id) async {
    await updateCompleteTask(id);
    await getAllTasks();
  }
}
