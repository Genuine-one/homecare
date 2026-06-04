import 'package:dio/dio.dart';
import 'dio_client.dart';
import '../errors/exceptions.dart';

/// KLE HOMECARE — Generic API Service
/// Wraps Dio calls with consistent error handling.
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  Dio get _dio => DioClient.instance.dio;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final resp = await _dio.get(path, queryParameters: queryParams);
      return resp.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<Map<String, dynamic>> post(
    String path, {
    required Map<String, dynamic> data,
  }) async {
    try {
      final resp = await _dio.post(path, data: data);
      return resp.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    required Map<String, dynamic> data,
  }) async {
    try {
      final resp = await _dio.patch(path, data: data);
      return resp.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> delete(String path) async {
    try {
      await _dio.delete(path);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
