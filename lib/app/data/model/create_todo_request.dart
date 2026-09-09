import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_todo_request.g.dart';

/// Request payload to add a new todo
@JsonSerializable()
class CreateTodoRequest extends Equatable {
  final String todo;
  final bool completed;
  final int userId;

  const CreateTodoRequest({
    required this.todo,
    this.completed = false,
    this.userId = 1,
  });

  factory CreateTodoRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateTodoRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateTodoRequestToJson(this);

  @override
  List<Object?> get props => [todo, completed, userId];
}
