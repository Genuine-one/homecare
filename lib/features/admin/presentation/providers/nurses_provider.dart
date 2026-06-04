import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/helpers.dart';

// ── State ─────────────────────────────────────────────────────────────────────
class NursesState {
  final List<Map<String, dynamic>> nurses;
  final bool   isLoading;
  final String? error;
  final String? successMessage;

  const NursesState({
    this.nurses         = const [],
    this.isLoading      = false,
    this.error,
    this.successMessage,
  });

  NursesState copyWith({
    List<Map<String, dynamic>>? nurses,
    bool?   isLoading,
    String? error,
    String? successMessage,
    bool    clearMessages = false,
  }) =>
      NursesState(
        nurses:         nurses         ?? this.nurses,
        isLoading:      isLoading      ?? this.isLoading,
        error:          clearMessages  ? null : (error          ?? this.error),
        successMessage: clearMessages  ? null : (successMessage ?? this.successMessage),
      );

  int get total    => nurses.length;
  int get active   => nurses.where((n) => n['is_active'] == true).length;
  int get inactive => nurses.where((n) => n['is_active'] != true).length;
}

// ── Notifier ──────────────────────────────────────────────────────────────────
class NursesNotifier extends AsyncNotifier<NursesState> {
  final _api = ApiService.instance;

  @override
  Future<NursesState> build() => _load();

  Future<NursesState> _load() async {
    try {
      final resp = await _api.get(
        ApiConstants.adminNurses,
        queryParams: {'limit': 100},
      );
      final list = List<Map<String, dynamic>>.from(resp['nurses'] ?? []);
      return NursesState(nurses: list);
    } catch (e) {
      return NursesState(error: AppHelpers.friendlyError(e));
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _load());
  }

  NursesState get _current => state.valueOrNull ?? const NursesState();

  // ── Create resource (admin) ────────────────────────────────────────────────
  Future<bool> createNurse({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String address,
    required String city,
    String? nurseState,
    String? pincode,
    String? category,
    required String password,
  }) async {
    final cur = _current;
    state = AsyncData(cur.copyWith(isLoading: true, clearMessages: true));
    try {
      final resp = await _api.post(
        ApiConstants.adminCreateNurse,
        data: {
          'first_name': firstName.trim(),
          'last_name':  lastName.trim(),
          'email':      email.trim(),
          'phone':      phone.trim(),
          'address':    address.trim(),
          'city':       city.trim(),
          if (nurseState != null && nurseState.trim().isNotEmpty)
            'state': nurseState.trim(),
          if (pincode != null && pincode.trim().isNotEmpty)
            'pincode': pincode.trim(),
          if (category != null && category.trim().isNotEmpty)
            'category': category.trim(),
          'password':   password,
        },
      );
      final newNurse = Map<String, dynamic>.from(resp as Map);
      final updated  = [newNurse, ...cur.nurses];
      state = AsyncData(NursesState(
        nurses:         updated,
        successMessage: 'Resource "${newNurse['first_name']} ${newNurse['last_name']}" created.',
      ));
      return true;
    } catch (e) {
      state = AsyncData(cur.copyWith(
        isLoading: false,
        error: AppHelpers.friendlyError(e),
      ));
      return false;
    }
  }

  // ── Update resource ─────────────────────────────────────────────────────
  Future<bool> updateNurse(String id, Map<String, dynamic> fields) async {
    final cur = _current;
    state = AsyncData(cur.copyWith(isLoading: true, clearMessages: true));
    try {
      final resp = await _api.patch(
        ApiConstants.adminNurse(id),
        data: fields,
      );
      final updated = Map<String, dynamic>.from(resp as Map);
      final newList = [
        for (final n in cur.nurses) if (n['id'] == id) updated else n,
      ];
      state = AsyncData(NursesState(
        nurses:         newList,
        successMessage: 'Resource "${updated['first_name']} ${updated['last_name']}" updated.',
      ));
      return true;
    } catch (e) {
      state = AsyncData(cur.copyWith(
        isLoading: false,
        error: AppHelpers.friendlyError(e),
      ));
      return false;
    }
  }

  // ── Toggle active / inactive ────────────────────────────────────────────
  Future<void> toggleNurse(String id) async {
    try {
      await _api.patch(ApiConstants.adminNurseToggle(id), data: {});
      final updated = _current.nurses.map((n) {
        if (n['id'] == id) {
          return {...n, 'is_active': !(n['is_active'] as bool? ?? false)};
        }
        return n;
      }).toList();
      state = AsyncData(_current.copyWith(
          nurses: updated, successMessage: 'Resource status updated.'));
    } catch (e) {
      state = AsyncData(_current.copyWith(error: AppHelpers.friendlyError(e)));
    }
  }

  // ── Delete resource ──────────────────────────────────────────────────────
  Future<void> deleteNurse(String id, String name) async {
    try {
      await _api.delete(ApiConstants.adminNurse(id));
      final updated = _current.nurses.where((n) => n['id'] != id).toList();
      state = AsyncData(_current.copyWith(
          nurses: updated, successMessage: 'Resource "$name" deleted.'));
    } catch (e) {
      state = AsyncData(_current.copyWith(error: AppHelpers.friendlyError(e)));
    }
  }
}

final nursesProvider =
    AsyncNotifierProvider<NursesNotifier, NursesState>(NursesNotifier.new);
