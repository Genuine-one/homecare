/// KLE HOMECARE — User Domain Entity
/// Pure Dart class — no JSON, no framework dependencies.
class UserEntity {
  final String id;
  final String fullName;
  final String email;
  final String role;

  const UserEntity({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
  });

  bool get isPatient => role == 'patient';
  bool get isAdmin   => role == 'admin';
  bool get isNurse   => role == 'nurse';
}
