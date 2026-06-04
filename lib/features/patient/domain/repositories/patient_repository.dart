import '../../../patient/data/models/service_request_model.dart';

abstract class PatientRepository {
  Future<ServiceRequestModel> createRequest(Map<String, dynamic> data);
  Future<List<ServiceRequestModel>> getRequests({String? status, int skip = 0, int limit = 20});
  Future<ServiceRequestModel> getRequestById(String id);
  Future<ServiceRequestModel> updateRequest(String id, Map<String, dynamic> data);
  Future<void> cancelRequest(String id);
  Future<Map<String, dynamic>> getNotifications({bool? isRead, int skip = 0, int limit = 20});
}
