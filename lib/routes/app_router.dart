import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/admin_login_screen.dart';
import '../features/auth/presentation/screens/nurse_login_screen.dart';
import '../features/patient/presentation/screens/patient_shell.dart';
import '../features/patient/presentation/screens/request_service_screen.dart';
import '../features/admin/presentation/screens/admin_shell.dart';
import '../features/nurse/presentation/screens/nurse_shell.dart';
import '../features/nurse/presentation/screens/job_detail_screen.dart';
import '../shared/screens/server_settings_screen.dart';
import '../shared/widgets/mobile_web_frame.dart';

/// KLE HOMECARE — App Router
/// Role-based redirect guards:
/// - Unauthenticated → /login
/// - patient → /patient
/// - admin   → /admin
/// - nurse   → /nurse
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(ref),
    redirect: (context, state) async {
      final authState = ref.read(authProvider).valueOrNull;
      final isLoggedIn = authState?.isAuthenticated ?? false;
      final role = authState?.user?.role;
      final path = state.matchedLocation;

      // Not logged in → force to login
      if (!isLoggedIn) {
        if (path == '/login' ||
            path == '/register' ||
            path == '/admin-login' ||
            path == '/nurse-login') return null;
        return '/login';
      }

      // Logged in but on auth pages → redirect to role dashboard
      if (path == '/login' ||
          path == '/register' ||
          path == '/admin-login' ||
          path == '/nurse-login') {
        return _dashboardForRole(role);
      }

      // Role-based access control
      if (path.startsWith('/patient') && role != 'patient') {
        return _dashboardForRole(role);
      }
      if (path.startsWith('/admin') && role != 'admin') {
        return _dashboardForRole(role);
      }
      if (path.startsWith('/nurse') && role != 'nurse') {
        return _dashboardForRole(role);
      }

      return null; // No redirect needed
    },
    routes: [
      // ── Auth ──────────────────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (ctx, state) => const MobileWebFrame(child: LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        builder: (ctx, state) => const MobileWebFrame(child: RegisterScreen()),
      ),
      GoRoute(
        path: '/admin-login',
        builder: (ctx, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: '/nurse-login',
        builder: (ctx, state) => const MobileWebFrame(child: NurseLoginScreen()),
      ),

      // ── Server settings (accessible from any role) ─────────────────────
      GoRoute(
        path: '/settings/server',
        builder: (ctx, state) => const ServerSettingsScreen(),
      ),

      // ── Patient ───────────────────────────────────────────────────────────
      GoRoute(
        path: '/patient',
        builder: (ctx, state) => const MobileWebFrame(child: PatientShell()),
        routes: [
          GoRoute(
            path: 'new-request',
            builder: (ctx, state) => const MobileWebFrame(child: RequestServiceScreen()),
          ),
          GoRoute(
            path: 'requests/:id',
            builder: (ctx, state) {
              final id = state.pathParameters['id']!;
              return MobileWebFrame(child: _RequestDetailPlaceholder(requestId: id));
            },
          ),
          GoRoute(
            path: 'notifications',
            builder: (ctx, state) => const MobileWebFrame(
                child: _NotificationsPlaceholder(role: 'patient')),
          ),
        ],
      ),

      // ── Admin ─────────────────────────────────────────────────────────────
      GoRoute(
        path: '/admin',
        builder: (ctx, state) => const AdminShell(),
      ),

      // ── Nurse ─────────────────────────────────────────────────────────────
      GoRoute(
        path: '/nurse',
        builder: (ctx, state) => const MobileWebFrame(child: NurseShell()),
        routes: [
          GoRoute(
            path: 'jobs/:id',
            builder: (ctx, state) {
              final id = state.pathParameters['id']!;
              return MobileWebFrame(child: JobDetailScreen(assignmentId: id));
            },
          ),
          GoRoute(
            path: 'notifications',
            builder: (ctx, state) => const MobileWebFrame(
                child: _NotificationsPlaceholder(role: 'nurse')),
          ),
        ],
      ),
    ],
    errorBuilder: (ctx, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.matchedLocation}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ctx.go('/login'),
              child: const Text('Go to Login'),
            ),
          ],
        ),
      ),
    ),
  );
});

String _dashboardForRole(String? role) {
  switch (role) {
    case 'admin':   return '/admin';
    case 'nurse':   return '/nurse';
    default:        return '/patient';
  }
}

/// Placeholder for request detail screen
class _RequestDetailPlaceholder extends StatelessWidget {
  final String requestId;
  const _RequestDetailPlaceholder({required this.requestId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Detail')),
      body: Center(child: Text('Request ID: $requestId')),
    );
  }
}

/// Placeholder for notifications screen
class _NotificationsPlaceholder extends StatelessWidget {
  final String role;
  const _NotificationsPlaceholder({required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: const Center(child: Text('No notifications yet')),
    );
  }
}

/// Bridges Riverpod state changes to GoRouter's refresh mechanism.
/// Uses ProviderRef (from the Provider callback) to listen for auth changes.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Ref ref) {
    ref.listen<AsyncValue<AuthState>>(authProvider, (_, __) {
      notifyListeners();
    });
  }
}
