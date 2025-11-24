import 'package:flutter/material.dart';
import 'package:todo_api/models/task_model.dart';
import 'package:todo_api/services/api_service.dart';

class TaskRepository {
  ApiService apiService = ApiService();

  /// Get All Tasks
  Future<List<TaskModel>> getAllTasks() async {
    try {
      return await apiService.getAllTasks();
    } catch (e, stackTrace) {
      debugPrint(
        'Error getting allTasks in TaskRepository: $e, stackTrace: $stackTrace',
      );
      throw Exception(e);
    }
  }

  /// Delete Task
  Future<void> deleteTaskByID(String id) async {
    try {
      return await apiService.deleteTaskByID(id);
    } catch (e, stackTrace) {
      debugPrint(
        'Error deleting task in TaskRepository: $e, stackTrace: $stackTrace',
      );
      throw Exception(e);
    }
  }

  /// Update Task
  Future<TaskModel> updateTask(String id, TaskModel task) async {
    try {
      return await apiService.updateTask(id, task);
    } catch (e, stackTrace) {
      debugPrint(
        'Error updating task in TaskRepository: $e, stackTrace: $stackTrace',
      );
      throw Exception(e);
    }
  }

  /// Create Task
  Future<TaskModel> createTask(TaskModel task) async {
    try {
      return await apiService.createTask(task);
    } catch (e, stackTrace) {
      debugPrint(
        'Error creating task in TaskRepository: $e, stackTrace: $stackTrace',
      );
      throw Exception(e);
    }
  }

  /// Complete Task (Update Status)
  Future<TaskModel> updateCompleteTask(String id) async {
    try {
      return await apiService.updateCompleteTask(id);
    } catch (e, stackTrace) {
      debugPrint(
        'Error completing task in TaskRepository: $e, stackTrace: $stackTrace',
      );
      throw Exception(e);
    }
  }
}
