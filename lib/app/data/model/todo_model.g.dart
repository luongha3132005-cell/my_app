// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TodoModel _$TodoModelFromJson(Map<String, dynamic> json) => TodoModel(
  id: (json['id'] as num).toInt(),
  todo: json['todo'] as String,
  completed: json['completed'] as bool,
  userId: (json['userId'] as num?)?.toInt(),
);

Map<String, dynamic> _$TodoModelToJson(TodoModel instance) => <String, dynamic>{
  'id': instance.id,
  'todo': instance.todo,
  'completed': instance.completed,
  'userId': instance.userId,
};
