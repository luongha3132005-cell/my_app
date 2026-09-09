import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'login_request.g.dart';

/// Request payload for login endpoint
@JsonSerializable()
class LoginRequest extends Equatable {
  final String username;
  final String password;
  final int? expiresInMins;

  const LoginRequest({
    required this.username,
    required this.password,
    this.expiresInMins,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) => _$LoginRequestFromJson(json);

  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);

  @override
  List<Object?> get props => [username, password, expiresInMins];
}
