import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

/// User entity model
@JsonSerializable()
class UserModel extends Equatable {
  final int id;
  final String username;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? gender;
  final String? image;

  const UserModel({
    required this.id,
    required this.username,
    this.email,
    this.firstName,
    this.lastName,
    this.gender,
    this.image,
  });

  /// Full name helper
  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  @override
  List<Object?> get props => [id, username, email, firstName, lastName, gender, image];
}
