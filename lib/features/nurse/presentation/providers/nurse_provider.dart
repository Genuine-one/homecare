import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/helpers.dart';

class NurseJobsState {
  final List<Map<String, dynamic>> jobs;
  final bool isLoading;
  final String? error;
  final int total;

  const NurseJobsState({
    this.jobs      = const [],
    this.isLoading = false,
    this.error,
    this.total     = 0,
  });

  int get pending    => jobs.where((j) => j['status'] == 'assigned').length;
  int get inProgress => jobs.where((j) => j['status'] == 'in_progress' || j['status'] == 'accepted').length;
  int get completed  => jobs.where((j) => j['status'] == 'completed').length;

  NurseJobsState copyWith({
    List<Map<String, dynamic>>? jobs,
    bool? isLoading,
    String? error,
    int? total,
    bool clearError = false,
  }) {
    return NurseJobsState(
      jobs:      jobs      ?? this.jobs,
      isLoading: isLoading ?? this.isLoading,
      error:     clearError ? null : (error ?? this.error),
      total:     total     ?? this.total,
    );
  }
}

class NurseNotifier extends AsyncNotifier<NurseJobsState> {
  final ApiService _api = ApiService.instance;

  @override
  Future<NurseJobsState> build() async {
    return _fetchJobs();
  }

  Future<NurseJobsState> _fetchJobs({String? status}) async {
    try {
      final resp = await _api.get(
        ApiConstants.nurseAlerts,
        queryParams: {if (status != null) 'status': status},
      );
      final jobs = List<Map<String, dynamic>>.from(resp['jobs'] ?? []);
      return NurseJobsState(jobs: jobs, total: resp['total'] as int? ?? jobs.length);
    } catch (e) {
      return NurseJobsState(error: AppHelpers.friendlyError(e));
    }
  }

  Future<void> refresh({String? status}) async {
    state = const AsyncLoading();
    state = AsyncData(await _fetchJobs(status: status));
  }

  Future<bool> updateJobStatus(
    String assignmentId,
    String status, {
    String? nurseNotes,
  }) async {
    try {
      await _api.patch(
        ApiConstants.nurseJobStatus(assignmentId),
        data: {
          'status': status,
          if (nurseNotes != null) 'nurse_notes': nurseNotes,
        },
      );
      // Update local state
      final current = state.valueOrNull ?? const NurseJobsState();
      final updated = current.jobs.map((j) {
        if (j['id'] == assignmentId) {
          return {...j, 'status': status};
        }
        return j;
      }).toList();
      state = AsyncData(current.copyWith(jobs: updated));
      return true;
    } catch (e) {
      final current = state.valueOrNull ?? const NurseJobsState();
      state = AsyncData(current.copyWith(error: AppHelpers.friendlyError(e)));
      return false;
    }
  }
}

final nurseProvider = AsyncNotifierProvider<NurseNotifier, NurseJobsState>(
  NurseNotifier.new,
);
