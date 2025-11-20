import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:todo_api/models/task_model.dart';
import 'package:http/http.dart' as http;

class ApiService {
  String baseUrl = "https://task-manager-api3.p.rapidapi.com/";
  String apiHost = "task-manager-api3.p.rapidapi.com";
  String apiKey = "7d744c6ef6msh6295387dee9a9e0p1f763djsndf07a261252a";

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
  Future<void> deleteTask(String id) async {
    try {
      /// url contain id
      final url = Uri.parse(baseUrl);
      final response = await http.get(url, headers: apiHeader);
    } catch (e, stackTrace) {
      throw Exception(e);
    }
  }

  /// Update Task
}
