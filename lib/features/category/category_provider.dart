import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/providers.dart';

class CategoryListNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final Ref _ref;
  Timer? _pollTimer;

  CategoryListNotifier(this._ref) : super(const AsyncValue.loading()) {
    fetchCategories();

    // Setup periodic polling every 10 seconds to auto-refresh categories list!
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      silentRefresh();
    });

    _ref.onDispose(() {
      _pollTimer?.cancel();
    });
  }

  Future<void> fetchCategories() async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(categoryRepositoryProvider);
      final list = await repo.getCategories();
      state = AsyncValue.data(list);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> silentRefresh() async {
    try {
      final repo = _ref.read(categoryRepositoryProvider);
      final list = await repo.getCategories();
      state = AsyncValue.data(list);
    } catch (_) {
      // Ignore background refresh errors
    }
  }

  Future<void> addCategory(String name, bool isEnabled) async {
    try {
      final repo = _ref.read(categoryRepositoryProvider);
      await repo.addCategory(name, isEnabled);
      await fetchCategories();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> updateCategory(String id, String name, bool isEnabled) async {
    try {
      final repo = _ref.read(categoryRepositoryProvider);
      await repo.updateCategory(id, name, isEnabled);
      await fetchCategories();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      final repo = _ref.read(categoryRepositoryProvider);
      await repo.deleteCategory(id);
      await fetchCategories();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> toggleCategory(String id, bool isEnabled) async {
    try {
      final repo = _ref.read(categoryRepositoryProvider);
      await repo.toggleCategory(id, isEnabled);
      // Optimistic update of local state to prevent laggy UI
      state.whenData((categories) {
        final updated = categories.map((cat) {
          if (cat['id'] == id) {
            return {...cat, 'is_enabled': isEnabled};
          }
          return cat;
        }).toList();
        state = AsyncValue.data(updated);
      });
    } catch (e) {
      await fetchCategories(); // Re-sync on failure
    }
  }
}

final categoryListProvider = StateNotifierProvider<CategoryListNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return CategoryListNotifier(ref);
});
