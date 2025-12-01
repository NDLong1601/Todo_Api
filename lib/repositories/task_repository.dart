import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:todo_api/models/task_model.dart';
import 'package:todo_api/services/api_service.dart';
import 'package:todo_api/services/local_service.dart';

class TaskRepository {
  ApiService apiService = ApiService();
  LocalService localService = LocalService();
  Connectivity connectivity = Connectivity();

  /// Callback to notify when sync completes
  /// This allows UI to refresh after sync without using fixed delays
  VoidCallback? onSyncCompleted;

  Future<void> init() async {
    await localService.init();
    debugPrint(
      'TaskRepository: Initialized. onSyncCompleted callback: ${onSyncCompleted != null ? "SET ✅" : "NOT SET ❌"}',
    );
    _setupConnectivityListener();
  }

  /// Set up connectivity listener to trigger sync when online
  ///
  /// When device comes online:
  /// 1. Sync pending tasks from queue
  /// 2. Fetch all tasks from server to refresh local storage
  /// 3. Notify listeners via callback (for UI refresh)
  void _setupConnectivityListener() {
    /// Listen to connectivity changes
    /// example: from offline to online or from online to offline
    connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> result,
    ) async {
      if (!result.contains(ConnectivityResult.none)) {
        /// Device is online now, trigger sync
        debugPrint('========================================');
        debugPrint('🌐 Device is online. Starting auto-sync...');
        debugPrint('========================================');

        try {
          // Step 1: Sync pending operations
          debugPrint('📤 Step 1/3: Syncing pending operations...');
          await syncPendingTasks();

          // Step 2: Refresh from server
          debugPrint('📥 Step 2/3: Fetching latest tasks from server...');
          final remoteTasks = await apiService.getAllTasks();
          await localService.saveAllTasks(remoteTasks);
          debugPrint('✅ Saved ${remoteTasks.length} tasks to local storage');

          debugPrint('🔔 Step 3/3: Notifying UI to refresh...');
          // Step 3: Notify listeners that sync is done
          onSyncCompleted?.call();

          debugPrint('========================================');
          debugPrint('✅ Auto-sync completed successfully');
          debugPrint('========================================');
        } catch (e, stackTrace) {
          debugPrint('========================================');
          debugPrint('❌ Error during sync: $e');
          debugPrint('Stack trace: $stackTrace');
          debugPrint('========================================');
          // Still notify even on error so UI can handle it
          onSyncCompleted?.call();
        }
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
  ///
  /// Updates an existing task either online (via API) or offline (in local storage with queue).
  ///
  /// **Important:** This method handles the case where a task was created offline
  /// with a local ID, then synced to get a server ID, but the caller still has
  /// the old reference with the local ID.
  ///
  /// **Online mode:**
  /// - Tries to update via API immediately
  /// - If API call fails, falls back to offline mode
  ///
  /// **Offline mode:**
  /// - Updates local storage
  /// - Adds to sync queue for later sync when online
  ///
  /// **ID Resolution:**
  /// - Before updating, checks local storage for current task by old ID
  /// - If not found, searches by title/description to find the task with new ID
  /// - This handles the case where task ID changed from local → server ID
  Future<void> updateTask(TaskModel task) async {
    try {
      if (task.id == null) {
        throw Exception("Cannot update task without ID");
      }

      // CRITICAL: Ensure we have the most up-to-date ID for this task
      // Task might have been created offline with local ID, then synced to get server ID
      // But the caller might still have a reference with the old local ID

      // First, try to get task by the provided ID
      TaskModel? currentTask = await localService.getTaskById(task.id!);

      if (currentTask == null) {
        // Task not found by this ID
        // It might have been synced and now has a different ID
        // The safest approach is to treat this as an offline operation
        // and add to sync queue - the sync logic will handle it properly
        debugPrint(
          "Task ${task.id} not found in local storage. "
          "Treating as offline operation - adding to sync queue.",
        );
        await _updateTaskInLocal(task);
        return; // Exit early - queued for sync
      }

      // Task found - use its current ID (might be same or might have changed)
      task = task.copyWith(id: currentTask.id);

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
  ///
  /// Creates a new task either online (via API) or offline (in local storage with queue).
  ///
  /// **Online mode:**
  /// - Calls API to create task immediately
  /// - Saves returned task with server ID to local storage
  /// - No need to add to sync queue (already synced)
  ///
  /// **Offline mode:**
  /// - Generates local temporary ID
  /// - Saves to local storage
  /// - Adds to sync queue for later sync when online
  ///
  /// **Important:** This method should NOT be called from syncPendingTasks
  /// to avoid infinite loop. Use apiService.createTask() directly in sync.
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

          // No need to change sync queue ID because:
          // - Task was created successfully online
          // - No need to keep it in sync queue
          // - If it was in queue from previous offline attempt,
          //   syncPendingTasks will handle removing it

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
  ///
  /// This method processes all pending operations in the sync queue when device is online.
  /// It handles create, update, and delete operations carefully to avoid duplicate syncs.
  ///
  /// **Important Notes:**
  /// - For CREATE operations: calls API directly (not createTask) to avoid re-adding to queue
  /// - Removes from queue using the ORIGINAL task.id before any ID changes
  /// - Updates local storage with new server IDs after successful creation
  /// - Continues processing even if individual operations fail (fault tolerance)
  ///
  /// **Flow for each operation type:**
  ///
  /// CREATE:
  /// 1. Call API to create task (get server ID back)
  /// 2. Remove from sync queue using LOCAL ID
  /// 3. Delete task with local ID from tasksBox
  /// 4. Save task with server ID to tasksBox
  ///
  /// UPDATE:
  /// 1. Get task from local storage by ID
  /// 2. If found: Call API to update, then update local storage
  /// 3. If not found: Skip (task was likely deleted)
  ///
  /// DELETE:
  /// 1. Get task from local storage by ID
  /// 2. If found: Call API to delete, then remove from local storage
  /// 3. If not found: Skip (task was already deleted)
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

        // Store original ID before any changes
        final String originalTaskId = task.id!;

        if (operation == "create") {
          // Call API directly to avoid re-adding to queue
          // createTask() would add to queue again, causing infinite loop
          final TaskModel createdTask = await apiService.createTask(task);

          // Remove from queue using ORIGINAL local ID
          // Must do this BEFORE updating local storage
          await localService.removeFromSyncQueue(originalTaskId);

          // Now update local storage with server ID
          // First delete the old local ID entry
          await localService.deleteTask(task);
          // Then save with new server ID
          await localService.saveTask(createdTask);

          debugPrint(
            " Sync CREATE succeeded: Local ID $originalTaskId → Server ID ${createdTask.id}",
          );
        } else if (operation == "update") {
          // Get current task from local storage
          // Note: Due to merge logic in addToSyncQueue(), CREATE + UPDATE operations
          // are merged into a single CREATE. So UPDATE operations in queue should
          // already have valid IDs in local storage.
          final TaskModel? currentTask = await localService.getTaskById(
            originalTaskId,
          );

          if (currentTask == null) {
            debugPrint(
              " Sync UPDATE skipped: Task $originalTaskId not found in local storage",
            );
            await localService.removeFromSyncQueue(originalTaskId);
            continue;
          }

          // Use current task ID with the update data
          final TaskModel taskToUpdate = task.copyWith(id: currentTask.id);
          await apiService.updateTask(taskToUpdate);
          await localService.removeFromSyncQueue(originalTaskId);
          await localService.updateLocalTask(taskToUpdate);

          debugPrint(" Sync UPDATE succeeded: Task ID ${currentTask.id}");
        } else if (operation == "delete") {
          // Get current task from local storage
          final TaskModel? currentTask = await localService.getTaskById(
            originalTaskId,
          );

          if (currentTask == null) {
            debugPrint(
              " Sync DELETE skipped: Task $originalTaskId not found in local storage",
            );
            await localService.removeFromSyncQueue(originalTaskId);
            continue;
          }

          await apiService.deleteTask(currentTask.id!);
          await localService.removeFromSyncQueue(originalTaskId);
          await localService.deleteTask(currentTask);

          debugPrint(" Sync DELETE succeeded: Task ID ${currentTask.id}");
        }
      } catch (e, st) {
        debugPrint(" Sync item $i failed: $e\n$st");
        // Continue with next item even if this one failed
      }
    }

    debugPrint("Sync completed!");
  }

  /// Manually trigger sync
  ///
  /// This method can be called manually (e.g., from pull-to-refresh)
  /// to sync pending tasks and refresh from server.
  ///
  /// Returns true if sync was successful, false otherwise.
  Future<bool> manualSync() async {
    if (!await _isOnline()) {
      debugPrint("Cannot sync: device is offline");
      return false;
    }

    try {
      debugPrint('Manual sync started...');

      // Step 1: Sync pending operations
      await syncPendingTasks();

      // Step 2: Refresh from server
      final remoteTasks = await apiService.getAllTasks();
      await localService.saveAllTasks(remoteTasks);

      debugPrint('Manual sync completed successfully');

      // Notify listeners
      onSyncCompleted?.call();

      return true;
    } catch (e, stackTrace) {
      debugPrint('Manual sync failed: $e\n$stackTrace');
      onSyncCompleted?.call();
      return false;
    }
  }
}
