// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_list_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TodoListResponse _$TodoListResponseFromJson(Map<String, dynamic> json) =>
    TodoListResponse(
      todos: (json['todos'] as List<dynamic>)
          .map((e) => TodoModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      skip: (json['skip'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
    );

Map<String, dynamic> _$TodoListResponseToJson(TodoListResponse instance) =>
    <String, dynamic>{
      'todos': instance.todos,
      'total': instance.total,
      'skip': instance.skip,
      'limit': instance.limit,
    };
