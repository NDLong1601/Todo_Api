import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:todo_api/models/task_model.dart';
import 'package:todo_api/services/api_service.dart';
import 'package:todo_api/services/local_service.dart';

class TaskRepository {
  ApiService apiService = ApiService();
  LocalService localService = LocalService();
  Connectivity connectivity = Connectivity();

  Future<void> init() async {
    await localService.init();
    _setupConnectivityListener();
  }

  /// Set up connectivity listener to trigger sync when online
  void _setupConnectivityListener() {
    /// Listen to connectivity changes
    /// example: from offline to online or from online to offline
    connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> result,
    ) async {
      if (!result.contains(ConnectivityResult.none)) {
        /// If we are online now, trigger sync
        // await _syncPendingTasks();
      } else {
        /// We are offline now
      }
    });
  }

  /// Get All Tasks
  Future<List<TaskModel>> getAllTasks() async {
    try {
      /// isOnline -> get from API
      /// isOffline -> get from Local Storage
      if (await _isOnline()) {
        /// If online, fetch from API
        final tasks = await apiService.getAllTasks();

        /// Save fetched tasks to local storage
        await localService.saveAllTasks(tasks);
        return tasks;
      } else {
        return await localService.getAllTasks();
      }
    } catch (e, stackTrace) {
      debugPrint(
        'Error getting allTasks in TaskRepository: $e, stackTrace: $stackTrace',
      );
      return await localService.getAllTasks();
    }
  }

  /// Delete Task
  Future<void> deleteTaskByID(String id) async {
    try {
      /// isOnline -> get from API
      /// isOffline -> get from Local Storage
      return await apiService.deleteTaskByID(id);
    } catch (e, stackTrace) {
      debugPrint(
        'Error deleting task in TaskRepository: $e, stackTrace: $stackTrace',
      );
      throw Exception(e);
    }
  }

  /// Update Task
  Future<void> updateTask(TaskModel task) async {
    try {
      /// isOnline -> get from API
      /// isOffline -> get from Local Storage
      await apiService.updateTask(task);
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
      /// isOnline -> get from API
      /// isOffline -> get from Local Storage
      return await apiService.createTask(task);
    } catch (e, stackTrace) {
      debugPrint(
        'Error creating task in TaskRepository: $e, stackTrace: $stackTrace',
      );
      throw Exception(e);
    }
  }

  Future<bool> _isOnline() async {
    try {
      final connectivityResult = await connectivity.checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return false;
      } else {
        return true;
      }
    } catch (e, stackTrace) {
      debugPrint(
        'Error checking online status in TaskRepository: $e, stackTrace: $stackTrace',
      );
      return false;
    }
  }
}
