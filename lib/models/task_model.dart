// {
//     "id": "J1EPhUFqax9ZNgedu6Uu",
//     "description": "123123123",
//     "title": "123",
//     "status": "pendiente"
// },

import 'package:json_annotation/json_annotation.dart';

part 'task_model.g.dart';

/// DTO -> data transfer object
@JsonSerializable()
class TaskModel {
  final String? id;
  final String title;
  final String description;
  final String status;

  TaskModel({
    this.id,
    required this.title,
    required this.description,
    required this.status,
  });

  bool get isCompleted => status == 'completada';
  bool get isPending => status == 'pendiente';

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? status,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
    );
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) =>
      _$TaskModelFromJson(json);

  Map<String, dynamic> toJson() => _$TaskModelToJson(this);
}
