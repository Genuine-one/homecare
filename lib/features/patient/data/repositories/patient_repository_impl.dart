import '../../domain/repositories/patient_repository.dart';
import '../models/service_request_model.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/constants/api_constants.dart';

class PatientRepositoryImpl implements PatientRepository {
  final ApiService _api;
  PatientRepositoryImpl({ApiService? api}) : _api = api ?? ApiService.instance;

  @override
  Future<ServiceRequestModel> createRequest(Map<String, dynamic> data) async {
    final resp = await _api.post(ApiConstants.patientRequests, data: data);
    return ServiceRequestModel.fromJson(resp);
  }

  @override
  Future<List<ServiceRequestModel>> getRequests({
    String? status,
    int skip = 0,
    int limit = 20,
  }) async {
    final resp = await _api.get(
      ApiConstants.patientRequests,
      queryParams: {
        if (status != null) 'status': status,
        'skip': skip,
        'limit': limit,
      },
    );
    final list = resp['requests'] as List<dynamic>;
    return list.map((e) => ServiceRequestModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<ServiceRequestModel> getRequestById(String id) async {
    final resp = await _api.get(ApiConstants.patientRequest(id));
    return ServiceRequestModel.fromJson(resp);
  }

  @override
  Future<ServiceRequestModel> updateRequest(String id, Map<String, dynamic> data) async {
    final resp = await _api.patch(ApiConstants.patientRequest(id), data: data);
    return ServiceRequestModel.fromJson(resp);
  }

  @override
  Future<void> cancelRequest(String id) async {
    await _api.delete(ApiConstants.patientRequest(id));
  }

  @override
  Future<Map<String, dynamic>> getNotifications({
    bool? isRead,
    int skip = 0,
    int limit = 20,
  }) async {
    return _api.get(
      ApiConstants.patientNotifications,
      queryParams: {
        if (isRead != null) 'is_read': isRead,
        'skip': skip,
        'limit': limit,
      },
    );
  }
}
