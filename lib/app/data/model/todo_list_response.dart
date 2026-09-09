import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'todo_model.dart';

part 'todo_list_response.g.dart';

/// Paginated todo list response
@JsonSerializable()
class TodoListResponse extends Equatable {
  final List<TodoModel> todos;
  final int total;
  final int skip;
  final int limit;

  const TodoListResponse({
    required this.todos,
    required this.total,
    required this.skip,
    required this.limit,
  });

  factory TodoListResponse.fromJson(Map<String, dynamic> json) =>
      _$TodoListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TodoListResponseToJson(this);

  @override
  List<Object?> get props => [todos, total, skip, limit];
}
