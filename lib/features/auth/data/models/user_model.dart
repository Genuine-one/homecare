import '../../domain/entities/user_entity.dart';

/// KLE HOMECARE — User Data Model
/// Handles JSON serialization from API responses.
/// All MongoDB ObjectIds are received as plain strings.
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.fullName,
    required super.email,
    required super.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id:       json['id'] as String,
      fullName: json['full_name'] as String,
      email:    json['email'] as String,
      role:     json['role'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id':        id,
    'full_name': fullName,
    'email':     email,
    'role':      role,
  };
}

/// Model for the full login response
class LoginResponseModel {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final UserModel user;

  const LoginResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.user,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      accessToken:  json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenType:    json['token_type'] as String? ?? 'bearer',
      user:         UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

/// Model for registration response (slim)
class RegisterResponseModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String role;

  const RegisterResponseModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
  });

  factory RegisterResponseModel.fromJson(Map<String, dynamic> json) {
    return RegisterResponseModel(
      id:        json['id'] as String,
      firstName: json['first_name'] as String,
      lastName:  json['last_name'] as String,
      email:     json['email'] as String,
      role:      json['role'] as String,
    );
  }
}
