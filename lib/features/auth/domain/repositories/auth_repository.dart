import '../entities/user_entity.dart';

/// KLE HOMECARE — Auth Repository Interface (Domain Layer)
abstract class AuthRepository {
  Future<UserEntity> login({
    required String email,
    required String password,
  });

  Future<UserEntity> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String address,
    required String city,
    String? state,
    String? pincode,
    required String password,
    required String confirmPassword,
    required String role,
  });

  Future<void> logout();

  Future<UserEntity?> getCurrentUser();

  Future<bool> isLoggedIn();
}
