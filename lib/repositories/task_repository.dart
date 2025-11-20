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

  /// Update Task
}
