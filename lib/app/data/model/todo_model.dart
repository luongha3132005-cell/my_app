import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'todo_model.g.dart';

/// Todo item entity
@JsonSerializable()
class TodoModel extends Equatable {
  final int id;
  final String todo;
  final bool completed;
  final int? userId;

  const TodoModel({
    required this.id,
    required this.todo,
    required this.completed,
    this.userId,
  });

  /// Create a modified copy
  TodoModel copyWith({
    int? id,
    String? todo,
    bool? completed,
    int? userId,
  }) {
    return TodoModel(
      id: id ?? this.id,
      todo: todo ?? this.todo,
      completed: completed ?? this.completed,
      userId: userId ?? this.userId,
    );
  }

  factory TodoModel.fromJson(Map<String, dynamic> json) => _$TodoModelFromJson(json);

  Map<String, dynamic> toJson() => _$TodoModelToJson(this);

  @override
  List<Object?> get props => [id, todo, completed, userId];
}
