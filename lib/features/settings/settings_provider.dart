import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/providers.dart';
import '../category/category_provider.dart';
import '../product/product_provider.dart';
import '../customer/customer_provider.dart';
import '../order/order_provider.dart';

class SettingsState {
  final Map<String, String> values;
  final bool isLoading;

  SettingsState({this.values = const {}, this.isLoading = false});

  SettingsState copyWith({Map<String, String>? values, bool? isLoading}) {
    return SettingsState(
      values: values ?? this.values,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final Ref _ref;

  SettingsNotifier(this._ref) : super(SettingsState(isLoading: true)) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true);
    try {
      final repo = _ref.read(settingsRepositoryProvider);
      final vals = await repo.getSettings();
      state = SettingsState(values: vals, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> updateSetting(String key, String value) async {
    state = state.copyWith(isLoading: true);
    try {
      final repo = _ref.read(settingsRepositoryProvider);
      await repo.updateSetting(key, value);
      final updatedValues = Map<String, String>.from(state.values);
      updatedValues[key] = value;
      state = SettingsState(values: updatedValues, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> wipeDatabase() async {
    state = state.copyWith(isLoading: true);
    try {
      final repo = _ref.read(settingsRepositoryProvider);
      await repo.resetDatabase();
      
      // Refresh all other lists
      _ref.read(categoryListProvider.notifier).fetchCategories();
      _ref.read(productListProvider.notifier).refresh();
      _ref.read(customerListProvider.notifier).refresh();
      _ref.read(orderListProvider.notifier).refresh();
      
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> seedDatabase() async {
    state = state.copyWith(isLoading: true);
    try {
      final repo = _ref.read(settingsRepositoryProvider);
      await repo.seedDatabase();
      
      // Refresh all lists
      _ref.read(categoryListProvider.notifier).fetchCategories();
      _ref.read(productListProvider.notifier).refresh();
      _ref.read(customerListProvider.notifier).refresh();
      _ref.read(orderListProvider.notifier).refresh();
      
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(ref);
});
