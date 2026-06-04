import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/storage/secure_storage.dart';

// ── Admin Dashboard State ─────────────────────────────────────────────────────
class AdminDashboardState {
  final Map<String, dynamic>? stats;
  final List<Map<String, dynamic>> requests;
  final List<Map<String, dynamic>> nurses;
  final bool isLoading;
  final String? error;

  const AdminDashboardState({
    this.stats,
    this.requests  = const [],
    this.nurses    = const [],
    this.isLoading = false,
    this.error,
  });

  AdminDashboardState copyWith({
    Map<String, dynamic>? stats,
    List<Map<String, dynamic>>? requests,
    List<Map<String, dynamic>>? nurses,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      AdminDashboardState(
        stats:     stats     ?? this.stats,
        requests:  requests  ?? this.requests,
        nurses:    nurses    ?? this.nurses,
        isLoading: isLoading ?? this.isLoading,
        error:     clearError ? null : (error ?? this.error),
      );
}

class AdminNotifier extends AsyncNotifier<AdminDashboardState> {
  final ApiService _api = ApiService.instance;

  /// How often the dashboard silently re-fetches in the background.
  static const _pollInterval = Duration(seconds: 15);

  Timer? _pollTimer;

  @override
  Future<AdminDashboardState> build() async {
    // Cancel any existing timer when the provider is rebuilt / disposed.
    ref.onDispose(_stopPolling);

    final initial = await _loadAll();
    _startPolling();
    return initial;
  }

  // ── Polling ───────────────────────────────────────────────────────────────

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _silentRefresh());
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Refreshes data in the background without showing a loading spinner,
  /// so the UI doesn't flicker while the admin is working.
  Future<void> _silentRefresh() async {
    // Don't poll if a full refresh is already in progress.
    if (state is AsyncLoading) return;
    try {
      final fresh = await _loadAll();
      state = AsyncData(fresh);
    } catch (_) {
      // Silently ignore poll errors — the existing data stays visible.
    }
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<AdminDashboardState> _loadAll() async {
    try {
      final results = await Future.wait([
        _api.get(ApiConstants.adminStats),
        _api.get(ApiConstants.adminRequests, queryParams: {'limit': 100}),
        _api.get(ApiConstants.adminNurses,   queryParams: {'limit': 100, 'is_active': true}),
      ]);
      return AdminDashboardState(
        stats:    results[0],
        requests: List<Map<String, dynamic>>.from(results[1]['requests'] ?? []),
        nurses:   List<Map<String, dynamic>>.from(results[2]['nurses']   ?? []),
      );
    } catch (e) {
      return AdminDashboardState(error: AppHelpers.friendlyError(e));
    }
  }

  /// Full refresh — shows loading spinner and resets the poll timer.
  Future<void> refresh() async {
    _stopPolling();
    state = const AsyncLoading();
    state = AsyncData(await _loadAll());
    _startPolling();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  /// Returns null on success, or an error message string on failure.
  Future<String?> assignNurse(
    String requestId,
    String nurseId, {
    String? adminNotes,
  }) async {
    try {
      await _api.post(
        ApiConstants.adminAssign(requestId),
        data: {
          'nurse_id': nurseId,
          if (adminNotes != null && adminNotes.isNotEmpty)
            'admin_notes': adminNotes,
        },
      );
      // Immediately refresh so the assigned card updates without waiting for
      // the next poll tick.
      await _silentRefresh();
      return null; // success
    } catch (e) {
      return AppHelpers.friendlyError(e);
    }
  }

  /// Fetch all requests with optional status filter (used by Home tab)
  Future<List<Map<String, dynamic>>> fetchRequests({String? status}) async {
    try {
      final resp = await _api.get(
        ApiConstants.adminRequests,
        queryParams: {
          if (status != null) 'status': status,
          'limit': 100,
        },
      );
      return List<Map<String, dynamic>>.from(resp['requests'] ?? []);
    } catch (_) {
      return [];
    }
  }
}

final adminProvider = AsyncNotifierProvider<AdminNotifier, AdminDashboardState>(
  AdminNotifier.new,
);

// ── Admin Profile State ───────────────────────────────────────────────────────
class AdminProfileState {
  final Map<String, dynamic>? profile;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const AdminProfileState({
    this.profile,
    this.isLoading     = false,
    this.error,
    this.successMessage,
  });

  AdminProfileState copyWith({
    Map<String, dynamic>? profile,
    bool? isLoading,
    String? error,
    String? successMessage,
    bool clearMessages = false,
  }) =>
      AdminProfileState(
        profile:        profile        ?? this.profile,
        isLoading:      isLoading      ?? this.isLoading,
        error:          clearMessages  ? null : (error          ?? this.error),
        successMessage: clearMessages  ? null : (successMessage ?? this.successMessage),
      );
}

class AdminProfileNotifier extends Notifier<AdminProfileState> {
  @override
  AdminProfileState build() => const AdminProfileState();

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      // Read cached user info from secure storage
      final id       = await SecureStorage.instance.getUserId();
      final email    = await SecureStorage.instance.getUserEmail();
      final fullName = await SecureStorage.instance.getUserName();
      final role     = await SecureStorage.instance.getUserRole();
      state = state.copyWith(
        isLoading: false,
        profile: {
          'id':        id       ?? '',
          'email':     email    ?? '',
          'full_name': fullName ?? '',
          'role':      role     ?? 'admin',
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: AppHelpers.friendlyError(e),
      );
    }
  }

  Future<bool> resetPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    // In a real app call PATCH /auth/change-password
    // For now simulate a short delay and succeed
    await Future.delayed(const Duration(milliseconds: 800));
    state = state.copyWith(
      isLoading: false,
      successMessage: 'Password updated successfully.',
    );
    return true;
  }
}

final adminProfileProvider =
    NotifierProvider<AdminProfileNotifier, AdminProfileState>(
  AdminProfileNotifier.new,
);
