import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/constants/api_constants.dart';

/// Lightweight model for a catalogue service (patient read-only view).
class CatalogueService {
  final String id;
  final String name;
  final String description;
  final String category;
  final bool   isActive;

  const CatalogueService({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.isActive,
  });

  factory CatalogueService.fromJson(Map<String, dynamic> j) => CatalogueService(
        id:          j['id']          as String,
        name:        j['name']        as String,
        description: j['description'] as String,
        category:    j['category']    as String,
        isActive:    j['is_active']   as bool,
      );
}

// ── Internal fetch function ───────────────────────────────────────────────────
Future<List<CatalogueService>> _fetchCatalogue() async {
  final resp = await ApiService.instance.get(
    ApiConstants.services,
    queryParams: {'is_active': true, 'limit': 100},
  );
  final list = resp['services'] as List<dynamic>;
  return list
      .map((e) => CatalogueService.fromJson(e as Map<String, dynamic>))
      .toList();
}

// ── Provider ──────────────────────────────────────────────────────────────────
//
// Uses autoDispose so the cache is DISCARDED as soon as the request screen
// is popped. The next time the screen opens, Riverpod rebuilds the provider
// from scratch → always hits the network → always gets the latest services.
//
// ref.invalidate(catalogueProvider) in initState is an extra safety net that
// forces a fresh fetch even if the provider somehow stayed alive.
final catalogueProvider =
    AsyncNotifierProvider.autoDispose<CatalogueNotifier, List<CatalogueService>>(
  CatalogueNotifier.new,
);

class CatalogueNotifier
    extends AutoDisposeAsyncNotifier<List<CatalogueService>> {
  @override
  Future<List<CatalogueService>> build() => _fetchCatalogue();

  /// Call this to manually re-fetch (e.g. from the Retry button).
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchCatalogue);
  }
}
