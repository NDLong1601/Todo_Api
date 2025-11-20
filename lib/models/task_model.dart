class TaskModel {
  final int id;
  final String tilte;
  final String detail;
  final String completed;

  TaskModel({
    required this.id,
    required this.tilte,
    required this.detail,
    required this.completed,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'],
      tilte: json['title'],
      detail: json['detail'],
      completed: json['completed'] ?? false,
    );
  }
}
