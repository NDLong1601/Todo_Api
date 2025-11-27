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
        debugPrint('Device is online. You can implement sync logic here.');
        // try {
        //   final remoteTasks = await apiService.getAllTasks();
        //   await localService.saveAllTasks(remoteTasks);
        //   debugPrint('Local tasks synced with remote server.');
        // } catch (e) {
        //   debugPrint('Error during sync: $e');
        // }
        await syncPendingTasks();
        final remoteTasks = await apiService.getAllTasks();
        await localService.saveAllTasks(remoteTasks);
        debugPrint('Local refreshed from server');
      } else {
        /// We are offline now
        debugPrint("Offline mode enabled");
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
  Future<void> deleteTask(TaskModel task) async {
    try {
      /// isOnline -> get from API
      /// isOffline -> get from Local Storage
      if (await _isOnline()) {
        try {
          await apiService.deleteTask(task.id!);
          await localService.deleteTask(task);
          return;
        } catch (e, stackTrace) {
          debugPrint("DELETE online failed: $e\n$stackTrace");
          await _deleteTaskInLocal(task);
        }
      } else {
        // offline → lưu queue + local
        await _deleteTaskInLocal(task);
      }
    } catch (e, stackTrace) {
      debugPrint(
        'Error deleting task in TaskRepository: $e, stackTrace: $stackTrace',
      );
      throw Exception(e);
    }
  }

  Future<void> _deleteTaskInLocal(TaskModel task) async {
    await localService.addToSyncQueue(operation: "delete", task: task);
    await localService.deleteTask(task);
    //// 100 lines of code
    return;
  }

  /// UPDATE TASK
  Future<void> updateTask(TaskModel task) async {
    try {
      if (task.id == null) {
        throw Exception("Cannot update task without ID");
      }

      /// isOnline -> get from API
      /// isOffline -> get from Local Storage
      if (await _isOnline()) {
        try {
          await apiService.updateTask(task);

          // lưu local
          await localService.updateLocalTask(task);
        } catch (e, stackTrace) {
          debugPrint("UPDATE online failed: $e\n$stackTrace");

          // lưu vào queue
          await _updateTaskInLocal(task);
        }
      } else {
        // offline → lưu queue + local
        await _updateTaskInLocal(task);
      }
    } catch (e, strackTrace) {
      debugPrint("Error updateTask: $e\n$strackTrace");
      rethrow;
    }
  }

  Future<TaskModel> _updateTaskInLocal(TaskModel task) async {
    await localService.addToSyncQueue(operation: "update", task: task);

    await localService.updateLocalTask(task);

    return task;
  }

  /// Create Task
  Future<TaskModel> createTask(TaskModel task) async {
    try {
      /// isOnline -> get from API
      /// isOffline -> get from Local Storage
      if (task.id == null) {
        // ensure task has an ID for local storage
        task = task.copyWith(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
        );
      }
      if (await _isOnline()) {
        try {
          final created = await apiService.createTask(task);
          await localService.saveTask(created);

          ///
          await localService.changeTaskIdFromSyncQueueBox(
            oldId: task.id!,
            newId: created.id!,
          );
          return created;
        } catch (e, stackTrace) {
          debugPrint("CREATE online failed: $e\n$stackTrace");
          await _createTaskInLocal(task);
          return task;
        }
      } else {
        // offline → lưu queue + local
        await _createTaskInLocal(task);
        return task;
      }
    } catch (e, stackTrace) {
      debugPrint(
        'Error creating task in TaskRepository: $e, stackTrace: $stackTrace',
      );
      throw Exception(e);
    }
  }

  Future<void> _createTaskInLocal(TaskModel task) async {
    await localService.addToSyncQueue(operation: "create", task: task);
    await localService.saveTask(task);
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

  /// Sync pending tasks in the sync queue
  Future<void> syncPendingTasks() async {
    final online = await _isOnline();
    if (!online) return;

    final queue = await localService.getSyncQueue();
    if (queue.isEmpty) return;

    debugPrint("Syncing ${queue.length} pending operations...");

    final copiedQueue = List<Map>.from(queue);

    for (int i = 0; i < copiedQueue.length; i++) {
      final item = copiedQueue[i];

      try {
        final operation = item["operation"];
        final taskJson = Map<String, dynamic>.from(item["task"]);
        final task = TaskModel.fromJson(taskJson);

        if (operation == "create") {
          await createTask(task);
        } else if (operation == "update") {
          await apiService.updateTask(task);
          await localService.updateLocalTask(task);
        } else if (operation == "delete") {
          await apiService.deleteTask(task.id!);
          await localService.deleteTask(task);
        }

        await localService.removeFromSyncQueue(task.id!);
        debugPrint(
          " Sync item $i succeeded: $operation for Task ID ${task.id}",
        );
      } catch (e, st) {
        debugPrint(" Sync item $i failed: $e\n$st");
      }
    }

    debugPrint("Sync completed!");
  }
}
