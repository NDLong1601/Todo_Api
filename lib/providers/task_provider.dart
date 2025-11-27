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
  String _addTitle = '';
  String get addTitle => _addTitle;

  String _addDetail = '';
  String get addDetail => _addDetail;

  void setAddTitle(String title) {
    _addTitle = title;
    notifyListeners();
  }

  void setAddDetail(String detail) {
    _addDetail = detail;
    notifyListeners();
  }

  bool get isAddValid {
    final title = _addTitle.trim();
    final detail = _addDetail.trim();
    return title.isNotEmpty &&
        title.length <= 100 &&
        detail.isNotEmpty &&
        detail.length <= 500;
  }

  bool _isAdding = false;
  bool get isAdding => _isAdding;
  void setIsAdding(bool isAdding) {
    _isAdding = isAdding;
    notifyListeners();
  }

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
  Future<void> deleteTask(TaskModel task) async {
    try {
      _setLoading(true);
      await taskRepository.deleteTask(task);
      notifyListeners();

      _taskList.removeWhere((t) => t.id == task.id);
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
      setIsAdding(true);
      final createTask = await taskRepository.createTask(task);

      _taskList.add(createTask);
      notifyListeners();
    } catch (e, stackTrace) {
      _setErrorMsg(e.toString());
      debugPrint(
        'Error while createTask in TaskProvider: $e, stackTrace: $stackTrace',
      );
    } finally {
      _setLoading(false);
      setIsAdding(false);
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
