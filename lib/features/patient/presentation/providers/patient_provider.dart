import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/service_request_model.dart';
import '../../data/repositories/patient_repository_impl.dart';
import '../../domain/repositories/patient_repository.dart';
import '../../../../core/utils/helpers.dart';

final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  return PatientRepositoryImpl();
});

// ── Service Requests State ────────────────────────────────────────────────────
class PatientRequestsState {
  final List<ServiceRequestModel> requests;
  final bool    isLoading;
  final String? error;
  final int     total;

  // ── Per-status counts (derived from the full unfiltered list) ─────────────
  final int totalAll;
  final int totalPending;
  final int totalAssigned;
  final int totalInProgress;
  final int totalCompleted;
  final int totalCancelled;

  const PatientRequestsState({
    this.requests       = const [],
    this.isLoading      = false,
    this.error,
    this.total          = 0,
    this.totalAll       = 0,
    this.totalPending   = 0,
    this.totalAssigned  = 0,
    this.totalInProgress = 0,
    this.totalCompleted = 0,
    this.totalCancelled = 0,
  });

  PatientRequestsState copyWith({
    List<ServiceRequestModel>? requests,
    bool?    isLoading,
    String?  error,
    int?     total,
    int?     totalAll,
    int?     totalPending,
    int?     totalAssigned,
    int?     totalInProgress,
    int?     totalCompleted,
    int?     totalCancelled,
    bool     clearError = false,
  }) {
    return PatientRequestsState(
      requests:        requests        ?? this.requests,
      isLoading:       isLoading       ?? this.isLoading,
      error:           clearError ? null : (error ?? this.error),
      total:           total           ?? this.total,
      totalAll:        totalAll        ?? this.totalAll,
      totalPending:    totalPending    ?? this.totalPending,
      totalAssigned:   totalAssigned   ?? this.totalAssigned,
      totalInProgress: totalInProgress ?? this.totalInProgress,
      totalCompleted:  totalCompleted  ?? this.totalCompleted,
      totalCancelled:  totalCancelled  ?? this.totalCancelled,
    );
  }
}

class PatientRequestsNotifier extends AsyncNotifier<PatientRequestsState> {
  late PatientRepository _repo;

  @override
  Future<PatientRequestsState> build() async {
    _repo = ref.read(patientRepositoryProvider);
    return _fetchRequests();
  }

  Future<PatientRequestsState> _fetchRequests({String? status}) async {
    try {
      // Always fetch ALL requests (no status filter) to compute stats counts.
      // Then apply the status filter locally for the visible list.
      // Backend enforces a max limit of 100 per request.
      final allRequests = await _repo.getRequests(limit: 100);

      // Compute counts from the full list
      final totalAll        = allRequests.length;
      final totalPending    = allRequests.where((r) => r.status == 'pending').length;
      final totalAssigned   = allRequests.where((r) => r.status == 'assigned').length;
      final totalInProgress = allRequests.where((r) => r.status == 'in_progress').length;
      final totalCompleted  = allRequests.where((r) => r.status == 'completed').length;
      final totalCancelled  = allRequests.where((r) => r.status == 'cancelled').length;

      // Apply status filter for the visible list
      final filtered = status == null
          ? allRequests
          : allRequests.where((r) => r.status == status).toList();

      return PatientRequestsState(
        requests:        filtered,
        total:           filtered.length,
        totalAll:        totalAll,
        totalPending:    totalPending,
        totalAssigned:   totalAssigned,
        totalInProgress: totalInProgress,
        totalCompleted:  totalCompleted,
        totalCancelled:  totalCancelled,
      );
    } catch (e) {
      return PatientRequestsState(error: AppHelpers.friendlyError(e));
    }
  }

  Future<void> refresh({String? status}) async {
    state = const AsyncLoading();
    state = AsyncData(await _fetchRequests(status: status));
  }

  Future<bool> createRequest(Map<String, dynamic> data) async {
    try {
      final created = await _repo.createRequest(data);
      // Refresh fully so counts stay accurate
      final current = state.valueOrNull ?? const PatientRequestsState();
      final allRequests = [created, ...current.requests];
      state = AsyncData(current.copyWith(
        requests:        allRequests,
        total:           allRequests.length,
        totalAll:        current.totalAll + 1,
        totalPending:    current.totalPending + 1,
      ));
      return true;
    } catch (e) {
      final current = state.valueOrNull ?? const PatientRequestsState();
      state = AsyncData(current.copyWith(error: AppHelpers.friendlyError(e)));
      return false;
    }
  }

  Future<bool> updateRequest(String id, Map<String, dynamic> data) async {
    try {
      final updated = await _repo.updateRequest(id, data);
      final current = state.valueOrNull ?? const PatientRequestsState();
      final newList = current.requests
          .map((r) => r.id == id ? updated : r)
          .toList();
      state = AsyncData(current.copyWith(requests: newList));
      return true;
    } catch (e) {
      final current = state.valueOrNull ?? const PatientRequestsState();
      state = AsyncData(current.copyWith(error: AppHelpers.friendlyError(e)));
      return false;
    }
  }

  Future<bool> cancelRequest(String id) async {
    try {
      await _repo.cancelRequest(id);
      final current = state.valueOrNull ?? const PatientRequestsState();

      // Find the old status to decrement the right counter
      final old = current.requests.firstWhere(
        (r) => r.id == id,
        orElse: () => ServiceRequestModel.fromJson(
            {'id': id, 'status': 'pending', 'patient_id': '', 'patient_name': '',
             'service_type': '', 'address': '', 'city': '', 'preferred_date': '',
             'num_days': 1, 'urgency_level': 'routine', 'created_at': '',
             'updated_at': ''}),
      );

      final updated = current.requests.map((r) {
        return r.id == id
            ? ServiceRequestModel.fromJson({...r.toJson(), 'status': 'cancelled'})
            : r;
      }).toList();

      state = AsyncData(current.copyWith(
        requests:       updated,
        totalCancelled: current.totalCancelled + 1,
        totalPending:   old.status == 'pending'
            ? current.totalPending - 1
            : current.totalPending,
        totalAssigned:  old.status == 'assigned'
            ? current.totalAssigned - 1
            : current.totalAssigned,
      ));
      return true;
    } catch (e) {
      final current = state.valueOrNull ?? const PatientRequestsState();
      state = AsyncData(current.copyWith(error: AppHelpers.friendlyError(e)));
      return false;
    }
  }
}

final patientRequestsProvider =
    AsyncNotifierProvider<PatientRequestsNotifier, PatientRequestsState>(
  PatientRequestsNotifier.new,
);
