import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_entity.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/widgets/trial_notice_dialog.dart';

// ── Repository Provider ───────────────────────────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

// ── Auth State ────────────────────────────────────────────────────────────────
class AuthState {
  final UserEntity? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserEntity? user,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user:      clearUser  ? null : (user ?? this.user),
      isLoading: isLoading  ?? this.isLoading,
      error:     clearError ? null : (error ?? this.error),
    );
  }
}

// ── Auth Notifier ─────────────────────────────────────────────────────────────
class AuthNotifier extends AsyncNotifier<AuthState> {
  late AuthRepository _repo;

  @override
  Future<AuthState> build() async {
    _repo = ref.read(authRepositoryProvider);
    final user = await _repo.getCurrentUser();
    return AuthState(user: user);
  }

  /// Login with an optional role gate.
  ///
  /// [allowedRole] — when supplied, the login succeeds only if the returned
  /// user role matches.  If it doesn't match the session is cleared
  /// immediately (token never stays in storage) and an error is set.
  ///
  /// - Patient/nurse login screen passes `allowedRole: 'patient,nurse'`
  ///   (any value that is NOT 'admin') → admins are blocked.
  /// - Admin login screen passes `allowedRole: 'admin'` → only admins pass.
  Future<void> login({
    required String email,
    required String password,
    String? allowedRole,          // null = allow any role (legacy behaviour)
  }) async {
    state = const AsyncLoading();
    try {
      final user = await _repo.login(email: email, password: password);

      // ── Role gate ────────────────────────────────────────────────────────
      if (allowedRole != null) {
        final allowed = allowedRole.split(',').map((r) => r.trim()).toList();
        if (!allowed.contains(user.role)) {
          // Wrong portal — wipe the just-saved session immediately.
          await _repo.logout();

          final msg = user.role == 'admin'
              ? 'Admin accounts must sign in via the Admin Portal.'
              : 'This portal is for admin accounts only.';
          state = AsyncData(AuthState(error: msg));
          return;
        }
      }
      // ────────────────────────────────────────────────────────────────────

      state = AsyncData(AuthState(user: user));
    } catch (e) {
      state = AsyncData(AuthState(error: AppHelpers.friendlyError(e)));
    }
  }

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String address,
    required String city,
    String? state_,
    String? pincode,
    required String password,
    required String confirmPassword,
    required String role,
  }) async {
    state = const AsyncLoading();
    try {
      await _repo.register(
        firstName:       firstName,
        lastName:        lastName,
        email:           email,
        phone:           phone,
        address:         address,
        city:            city,
        state:           state_,
        pincode:         pincode,
        password:        password,
        confirmPassword: confirmPassword,
        role:            role,
      );
      state = const AsyncData(AuthState());
      return true;
    } catch (e) {
      state = AsyncData(AuthState(error: AppHelpers.friendlyError(e)));
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    // Reset the trial notice flag so it shows again on the next login.
    await clearTrialNoticeFlag();
    state = const AsyncData(AuthState());
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────
final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

/// Returns the login route for a given role.
/// Use this after logout so each role goes back to its own login screen.
///
/// ```dart
/// final route = logoutRoute(ref.read(authProvider).valueOrNull?.user?.role);
/// await ref.read(authProvider.notifier).logout();
/// if (context.mounted) context.go(route);
/// ```
String logoutRoute(String? role) {
  switch (role) {
    case 'admin': return '/admin-login';
    case 'nurse': return '/nurse-login';
    default:      return '/login';        // patient + any unknown role
  }
}
