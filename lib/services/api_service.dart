import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:todo_api/models/task_model.dart';
import 'package:http/http.dart' as http;

class ApiService {
  String baseUrl = "https://task-manager-api3.p.rapidapi.com/";
  String apiHost = "task-manager-api3.p.rapidapi.com";
  String apiKey = "9c017ff99cmsh5fd9b3ead41068ep106e77jsnbf756e75c3d8";

  Map<String, String> apiHeader = {
    'Content-Type': 'application/json',
    'x-rapidapi-host': 'task-manager-api3.p.rapidapi.com',
    'x-rapidapi-key': '7d744c6ef6msh6295387dee9a9e0p1f763djsndf07a261252a',
  };

  /// Get all tasks
  Future<List<TaskModel>> getAllTasks() async {
    try {
      final url = Uri.parse(baseUrl);
      final response = await http.get(url, headers: apiHeader);
      debugPrint('Method: GET');
      debugPrint('GET All Tasks: $url');
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      if (response.statusCode == 200) {
        /// success -> return data
        /// response.body -> JSON String -> "{}"
        /// convert JSON String to JSON by jsonDecode
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['data'] != null) {
          final allTasks = jsonResponse['data'] as List;

          /// item in allTasks -> JSON
          /// convert JSON -> Object TaskModel
          return allTasks
              .map((taskJson) => TaskModel.fromJson(taskJson))
              .where((task) => task.id != null)
              .toList();
        } else {
          throw Exception("Api get all tasks don't have any data");
        }
      } else {
        debugPrint("Can't get all tasks from api server");
        throw Exception("Can't get all tasks from api");
      }
    } catch (e, stackTrace) {
      debugPrint(
        'Error while getting All Tasks in ApiService: $e, stackTrace: $stackTrace',
      );
      throw Exception(e);
    }
  }

  /// Delete Task
  Future<void> deleteTaskByID(String id) async {
    try {
      /// url contain id
      final url = Uri.parse('$baseUrl$id');
      final response = await http.delete(url, headers: apiHeader);
      debugPrint('Method: DELETE');
      debugPrint('DELETE Task: $url');
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        debugPrint('Task deleted successfully');
        return;
      } else {
        debugPrint('Failed to delete task (status ${response.statusCode})');
        throw Exception("Failed to delete task");
      }
    } catch (e, stackTrace) {
      debugPrint(
        'Error while deleting Task in ApiService: $e, stackTrace: $stackTrace',
      );
      throw Exception(e);
    }
  }

  /// Update Task
  Future<void> updateTask(TaskModel task) async {
    try {
      final url = Uri.parse("$baseUrl${task.id}");

      final response = await http.put(
        url,
        headers: apiHeader,
        body: jsonEncode(task.toJson()),
      );

      debugPrint('Method: PUT');
      debugPrint('PUT Task: $url');
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        debugPrint('Task updated successfully');
      } else {
        throw Exception(
          'Failed to update task: '
          '${response.statusCode} - ${response.body}',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error while updating Task in ApiService: $e');
      debugPrint('StackTrace: $stackTrace');
      throw Exception(e);
    }
  }

  /// Create Task
  Future<TaskModel> createTask(TaskModel task) async {
    try {
      final url = Uri.parse(baseUrl);

      final response = await http.post(
        url,
        headers: apiHeader,
        body: jsonEncode(task.toJson()),
      );

      debugPrint('Method: POST');
      debugPrint('POST Task: $url');
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonRespone = jsonDecode(response.body);
        final newID = jsonRespone["data"]["id"];
        if (newID == null) {
          throw Exception('API return null ID when creating task');
        }
        return task.copyWith(id: newID);
      } else {
        throw Exception(
          'Failed to create task: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error while creating task in ApiService: $e');
      debugPrint('StackTrace: $stackTrace');
      throw Exception(e);
    }
  }
}
