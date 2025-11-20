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
      _taskList.where((task) => task.isCompleted).toList();

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

  /// Update Task
}
