import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'login_response.g.dart';

/// Response payload from login endpoint
@JsonSerializable()
class LoginResponse extends Equatable {
  final int id;
  final String username;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? gender;
  final String? image;
  @JsonKey(name: 'accessToken')
  final String? accessToken;
  @JsonKey(name: 'token')
  final String? token;

  const LoginResponse({
    required this.id,
    required this.username,
    this.email,
    this.firstName,
    this.lastName,
    this.gender,
    this.image,
    this.accessToken,
    this.token,
  });

  /// Guaranteed token accessor
  String get authToken => accessToken ?? token ?? '';

  factory LoginResponse.fromJson(Map<String, dynamic> json) => _$LoginResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LoginResponseToJson(this);

  @override
  List<Object?> get props => [
        id,
        username,
        email,
        firstName,
        lastName,
        gender,
        image,
        accessToken,
        token,
      ];
}
