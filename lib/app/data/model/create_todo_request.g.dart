// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_todo_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateTodoRequest _$CreateTodoRequestFromJson(Map<String, dynamic> json) =>
    CreateTodoRequest(
      todo: json['todo'] as String,
      completed: json['completed'] as bool? ?? false,
      userId: (json['userId'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$CreateTodoRequestToJson(CreateTodoRequest instance) =>
    <String, dynamic>{
      'todo': instance.todo,
      'completed': instance.completed,
      'userId': instance.userId,
    };
