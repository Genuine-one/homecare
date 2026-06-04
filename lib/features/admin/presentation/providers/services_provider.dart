import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/service_model.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/helpers.dart';

// ── State ─────────────────────────────────────────────────────────────────────
class ServicesState {
  final List<ServiceModel> services;
  final List<String>       categories;
  final bool               isLoading;
  final String?            error;
  final String?            successMessage;

  const ServicesState({
    this.services       = const [],
    this.categories     = const [],
    this.isLoading      = false,
    this.error,
    this.successMessage,
  });

  ServicesState copyWith({
    List<ServiceModel>? services,
    List<String>?       categories,
    bool?               isLoading,
    String?             error,
    String?             successMessage,
    bool                clearMessages = false,
  }) =>
      ServicesState(
        services:       services       ?? this.services,
        categories:     categories     ?? this.categories,
        isLoading:      isLoading      ?? this.isLoading,
        error:          clearMessages  ? null : (error          ?? this.error),
        successMessage: clearMessages  ? null : (successMessage ?? this.successMessage),
      );

  /// Group services by category, sorted alphabetically within each group.
  Map<String, List<ServiceModel>> get grouped {
    final Map<String, List<ServiceModel>> map = {};
    for (final s in services) {
      map.putIfAbsent(s.category, () => []).add(s);
    }
    // Sort each group by name
    for (final key in map.keys) {
      map[key]!.sort((a, b) => a.name.compareTo(b.name));
    }
    return map;
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────
class ServicesNotifier extends AsyncNotifier<ServicesState> {
  final _api = ApiService.instance;

  @override
  Future<ServicesState> build() => _load();

  // ── Internal fetch ────────────────────────────────────────────────────────
  Future<ServicesState> _load() async {
    try {
      // Fetch services list (all, including inactive so admin can manage them)
      final resp = await _api.get(
        ApiConstants.services,
        queryParams: {'limit': 100},
      );
      final services = (resp['services'] as List<dynamic>)
          .map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
          .toList();

      // Fetch distinct categories
      List<String> categories = [];
      try {
        final catResp = await _api.get(ApiConstants.serviceCategories);
        categories = List<String>.from(catResp as List? ?? []);
      } catch (_) {
        // categories are optional — derive from loaded services if API fails
        categories = services.map((s) => s.category).toSet().toList()..sort();
      }

      return ServicesState(services: services, categories: categories);
    } catch (e) {
      return ServicesState(error: AppHelpers.friendlyError(e));
    }
  }

  // ── Refresh ───────────────────────────────────────────────────────────────
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _load());
  }

  // ── Create ────────────────────────────────────────────────────────────────
  Future<bool> createService({
    required String name,
    required String description,
    required String category,
    String?         icon,
    bool            isActive = true,
  }) async {
    final cur = state.valueOrNull ?? const ServicesState();
    state = AsyncData(cur.copyWith(isLoading: true, clearMessages: true));
    try {
      final resp = await _api.post(
        ApiConstants.services,
        data: {
          'name':        name.trim(),
          'description': description.trim(),
          'category':    category.trim(),
          if (icon != null) 'icon': icon,
          'is_active':   isActive,
        },
      );
      final created = ServiceModel.fromJson(resp);
      final updated = [created, ...cur.services];
      // Rebuild categories
      final cats = updated.map((s) => s.category).toSet().toList()..sort();
      state = AsyncData(ServicesState(
        services:       updated,
        categories:     cats,
        successMessage: 'Service "${created.name}" created successfully.',
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

  // ── Update ────────────────────────────────────────────────────────────────
  Future<bool> updateService(
    String serviceId, {
    String? name,
    String? description,
    String? category,
    String? icon,
    bool?   isActive,
  }) async {
    final cur = state.valueOrNull ?? const ServicesState();
    state = AsyncData(cur.copyWith(isLoading: true, clearMessages: true));
    try {
      final body = <String, dynamic>{};
      if (name        != null) body['name']        = name.trim();
      if (description != null) body['description'] = description.trim();
      if (category    != null) body['category']    = category.trim();
      if (icon        != null) body['icon']        = icon;
      if (isActive    != null) body['is_active']   = isActive;

      final resp = await _api.patch(
        ApiConstants.service(serviceId),
        data: body,
      );
      final updated = ServiceModel.fromJson(resp);
      final newList = [
        for (final s in cur.services)
          if (s.id == serviceId) updated else s,
      ];
      final cats = newList.map((s) => s.category).toSet().toList()..sort();
      state = AsyncData(ServicesState(
        services:       newList,
        categories:     cats,
        successMessage: 'Service "${updated.name}" updated.',
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

  // ── Toggle active/inactive ────────────────────────────────────────────────
  Future<bool> toggleService(String serviceId) async {
    final cur = state.valueOrNull ?? const ServicesState();
    try {
      final resp = await _api.patch(
        ApiConstants.serviceToggle(serviceId),
        data: {},
      );
      final toggled = ServiceModel.fromJson(resp);
      final newList = [
        for (final s in cur.services)
          if (s.id == serviceId) toggled else s,
      ];
      state = AsyncData(cur.copyWith(services: newList, clearMessages: true));
      return true;
    } catch (e) {
      state = AsyncData(cur.copyWith(error: AppHelpers.friendlyError(e)));
      return false;
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────
  Future<bool> deleteService(String serviceId, String serviceName) async {
    final cur = state.valueOrNull ?? const ServicesState();
    try {
      await _api.delete(ApiConstants.service(serviceId));
      final newList = cur.services.where((s) => s.id != serviceId).toList();
      final cats    = newList.map((s) => s.category).toSet().toList()..sort();
      state = AsyncData(ServicesState(
        services:       newList,
        categories:     cats,
        successMessage: 'Service "$serviceName" deleted.',
      ));
      return true;
    } catch (e) {
      state = AsyncData(cur.copyWith(error: AppHelpers.friendlyError(e)));
      return false;
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────
final servicesProvider =
    AsyncNotifierProvider<ServicesNotifier, ServicesState>(
  ServicesNotifier.new,
);
