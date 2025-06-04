import 'package:equatable/equatable.dart';

class TodoModel extends Equatable {
  final int id;
  final String todo;
  final bool completed;
  final int userId;

  const TodoModel({
    required this.id,
    required this.todo,
    required this.completed,
    required this.userId,
  });

  factory TodoModel.fromJson(Map<String, dynamic> json) {
    return TodoModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      todo: json['todo']?.toString() ?? '',
      completed: json['completed'] == true || json['completed'] == 1,
      userId: int.tryParse(json['userId']?.toString() ?? '') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'todo': todo,
      'completed': completed,
      'userId': userId,
    };
  }

  @override
  List<Object> get props => [id, todo, completed, userId];
}
