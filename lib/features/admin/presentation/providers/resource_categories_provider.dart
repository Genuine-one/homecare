import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/errors/exceptions.dart';

// ── State ─────────────────────────────────────────────────────────────────────
class ResourceCategoriesState {
  final List<Map<String, dynamic>> categories;
  final bool    isLoading;
  final String? error;
  final String? successMessage;

  const ResourceCategoriesState({
    this.categories     = const [],
    this.isLoading      = false,
    this.error,
    this.successMessage,
  });

  ResourceCategoriesState copyWith({
    List<Map<String, dynamic>>? categories,
    bool?    isLoading,
    String?  error,
    String?  successMessage,
    bool     clearMessages = false,
  }) =>
      ResourceCategoriesState(
        categories:     categories     ?? this.categories,
        isLoading:      isLoading      ?? this.isLoading,
        error:          clearMessages  ? null : (error          ?? this.error),
        successMessage: clearMessages  ? null : (successMessage ?? this.successMessage),
      );

  /// Only active category names as a sorted list — for dropdown use.
  List<String> get activeNames =>
      categories
          .where((c) => c['is_active'] == true)
          .map((c) => c['name'] as String)
          .toList()
        ..sort();
}

// ── Notifier ──────────────────────────────────────────────────────────────────
class ResourceCategoriesNotifier extends AsyncNotifier<ResourceCategoriesState> {
  // Use Dio directly — ApiService.get() only handles Map responses,
  // but categories returns a JSON array at the list endpoint.
  Dio get _dio => DioClient.instance.dio;

  @override
  Future<ResourceCategoriesState> build() => _load();

  Future<ResourceCategoriesState> _load() async {
    try {
      final resp = await _dio.get(ApiConstants.adminResourceCategories);
      final data = resp.data;

      List<Map<String, dynamic>> list;
      if (data is List) {
        // Raw array response
        list = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } else if (data is Map && data['categories'] is List) {
        // Wrapped {"categories": [...]} response
        list = (data['categories'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } else {
        list = [];
      }
      return ResourceCategoriesState(categories: list);
    } on DioException catch (e) {
      return ResourceCategoriesState(
          error: AppHelpers.friendlyError(mapDioException(e)));
    } catch (e) {
      return ResourceCategoriesState(error: AppHelpers.friendlyError(e));
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _load());
  }

  ResourceCategoriesState get _cur =>
      state.valueOrNull ?? const ResourceCategoriesState();

  // ── Create ─────────────────────────────────────────────────────────────────
  Future<bool> createCategory(String name, {String? description}) async {
    state = AsyncData(_cur.copyWith(isLoading: true, clearMessages: true));
    try {
      final resp = await _dio.post(
        ApiConstants.adminResourceCategories,
        data: {
          'name': name.trim(),
          if (description != null && description.trim().isNotEmpty)
            'description': description.trim(),
          'is_active': true,
        },
      );
      final created = Map<String, dynamic>.from(resp.data as Map);
      final updated = [created, ..._cur.categories];
      state = AsyncData(ResourceCategoriesState(
        categories:     updated,
        successMessage: 'Category "${created['name']}" created.',
      ));
      return true;
    } on DioException catch (e) {
      state = AsyncData(_cur.copyWith(
        isLoading: false,
        error: AppHelpers.friendlyError(mapDioException(e)),
      ));
      return false;
    } catch (e) {
      state = AsyncData(_cur.copyWith(
        isLoading: false,
        error: AppHelpers.friendlyError(e),
      ));
      return false;
    }
  }

  // ── Update ─────────────────────────────────────────────────────────────────
  Future<bool> updateCategory(
    String id, {
    String? name,
    String? description,
    bool?   isActive,
  }) async {
    state = AsyncData(_cur.copyWith(isLoading: true, clearMessages: true));
    try {
      final body = <String, dynamic>{};
      if (name        != null) body['name']        = name.trim();
      if (description != null) body['description'] = description.trim();
      if (isActive    != null) body['is_active']   = isActive;

      final resp = await _dio.patch(
        ApiConstants.adminResourceCategory(id),
        data: body,
      );
      final updated = Map<String, dynamic>.from(resp.data as Map);
      final newList = [
        for (final c in _cur.categories)
          if (c['id'] == id) updated else c,
      ];
      state = AsyncData(ResourceCategoriesState(
        categories:     newList,
        successMessage: 'Category updated.',
      ));
      return true;
    } on DioException catch (e) {
      state = AsyncData(_cur.copyWith(
        isLoading: false,
        error: AppHelpers.friendlyError(mapDioException(e)),
      ));
      return false;
    } catch (e) {
      state = AsyncData(_cur.copyWith(
        isLoading: false,
        error: AppHelpers.friendlyError(e),
      ));
      return false;
    }
  }

  // ── Delete ─────────────────────────────────────────────────────────────────
  Future<bool> deleteCategory(String id, String name) async {
    try {
      await _dio.delete(ApiConstants.adminResourceCategory(id));
      final newList = _cur.categories.where((c) => c['id'] != id).toList();
      state = AsyncData(_cur.copyWith(
        categories:     newList,
        successMessage: 'Category "$name" deleted.',
      ));
      return true;
    } on DioException catch (e) {
      state = AsyncData(_cur.copyWith(
          error: AppHelpers.friendlyError(mapDioException(e))));
      return false;
    } catch (e) {
      state = AsyncData(_cur.copyWith(error: AppHelpers.friendlyError(e)));
      return false;
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────
final resourceCategoriesProvider =
    AsyncNotifierProvider<ResourceCategoriesNotifier, ResourceCategoriesState>(
  ResourceCategoriesNotifier.new,
);

/// Convenience provider that returns only active category names for dropdowns.
/// Automatically loads if not yet fetched.
final activeCategoryNamesProvider = Provider<List<String>>((ref) {
  final state = ref.watch(resourceCategoriesProvider).valueOrNull;
  return state?.activeNames ?? [];
});
