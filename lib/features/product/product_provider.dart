import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/providers.dart';

class ProductFilter {
  final String search;
  final String? categoryId;

  ProductFilter({this.search = '', this.categoryId});

  ProductFilter copyWith({String? search, String? categoryId, bool clearCategory = false}) {
    return ProductFilter(
      search: search ?? this.search,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
    );
  }
}

class ProductFilterNotifier extends StateNotifier<ProductFilter> {
  ProductFilterNotifier() : super(ProductFilter());

  void setSearch(String search) {
    state = state.copyWith(search: search);
  }

  void setCategory(String? categoryId) {
    if (categoryId == null) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(categoryId: categoryId);
    }
  }

  void clearFilters() {
    state = ProductFilter();
  }
}

final productFilterProvider = StateNotifierProvider<ProductFilterNotifier, ProductFilter>((ref) {
  return ProductFilterNotifier();
});

class ProductListNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final Ref _ref;
  Timer? _pollTimer;

  ProductListNotifier(this._ref) : super(const AsyncValue.loading()) {
    // Listen to filter changes and reload products
    _ref.listen<ProductFilter>(productFilterProvider, (previous, next) {
      fetchProducts(search: next.search, categoryId: next.categoryId);
    });
    
    // Initial fetch
    final filters = _ref.read(productFilterProvider);
    fetchProducts(search: filters.search, categoryId: filters.categoryId);

    // Setup periodic polling every 10 seconds to auto-refresh products list!
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      silentRefresh();
    });

    _ref.onDispose(() {
      _pollTimer?.cancel();
    });
  }

  Future<void> fetchProducts({String? search, String? categoryId}) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(productRepositoryProvider);
      final list = await repo.getProducts(search: search, categoryId: categoryId);
      state = AsyncValue.data(list);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> refresh() async {
    final filters = _ref.read(productFilterProvider);
    await fetchProducts(search: filters.search, categoryId: filters.categoryId);
  }

  Future<void> silentRefresh() async {
    try {
      final filters = _ref.read(productFilterProvider);
      final repo = _ref.read(productRepositoryProvider);
      final list = await repo.getProducts(search: filters.search, categoryId: filters.categoryId);
      state = AsyncValue.data(list);
    } catch (_) {
      // Ignore background refresh errors
    }
  }

  Future<bool> addProduct({
    required String name,
    required String? categoryId,
    required String description,
    required double price,
    required String unit,
    required bool isAvailable,
    required bool isEnabled,
    String? imagePath,
    double costPrice = 0.0,
    double marketPrice = 0.0,
    double stock = 0.0,
    double minStock = 0.0,
    String barcode = '',
    double weightPerPiece = 0.25,
    int sequenceNo = 0,
    String expiryDate = '',
    String batchNumber = '',
    bool prescriptionRequired = false,
    String dosageInfo = '',
    String bestBefore = '',
    String packDate = '',
  }) async {
    try {
      final repo = _ref.read(productRepositoryProvider);
      await repo.addProduct(
        name: name,
        categoryId: categoryId,
        description: description,
        price: price,
        unit: unit,
        isAvailable: isAvailable,
        isEnabled: isEnabled,
        imagePath: imagePath,
        costPrice: costPrice,
        marketPrice: marketPrice,
        stock: stock,
        minStock: minStock,
        barcode: barcode,
        weightPerPiece: weightPerPiece,
        sequenceNo: sequenceNo,
        expiryDate: expiryDate,
        batchNumber: batchNumber,
        prescriptionRequired: prescriptionRequired,
        dosageInfo: dosageInfo,
        bestBefore: bestBefore,
        packDate: packDate,
      );
      await refresh();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateProduct({
    required String id,
    required String name,
    required String? categoryId,
    required String description,
    required double price,
    required String unit,
    required bool isAvailable,
    required bool isEnabled,
    String? imagePath,
    double costPrice = 0.0,
    double marketPrice = 0.0,
    double stock = 0.0,
    double minStock = 0.0,
    String barcode = '',
    double weightPerPiece = 0.25,
    int sequenceNo = 0,
    String expiryDate = '',
    String batchNumber = '',
    bool prescriptionRequired = false,
    String dosageInfo = '',
    String bestBefore = '',
    String packDate = '',
  }) async {
    try {
      final repo = _ref.read(productRepositoryProvider);
      await repo.updateProduct(
        id: id,
        name: name,
        categoryId: categoryId,
        description: description,
        price: price,
        unit: unit,
        isAvailable: isAvailable,
        isEnabled: isEnabled,
        imagePath: imagePath,
        costPrice: costPrice,
        marketPrice: marketPrice,
        stock: stock,
        minStock: minStock,
        barcode: barcode,
        weightPerPiece: weightPerPiece,
        sequenceNo: sequenceNo,
        expiryDate: expiryDate,
        batchNumber: batchNumber,
        prescriptionRequired: prescriptionRequired,
        dosageInfo: dosageInfo,
        bestBefore: bestBefore,
        packDate: packDate,
      );
      await refresh();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      final repo = _ref.read(productRepositoryProvider);
      await repo.deleteProduct(id);
      await refresh();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> toggleProduct(String id, bool isEnabled) async {
    try {
      final repo = _ref.read(productRepositoryProvider);
      await repo.toggleProduct(id, isEnabled);
      state.whenData((products) {
        final updated = products.map((prod) {
          if (prod['id'] == id) {
            return {...prod, 'is_enabled': isEnabled};
          }
          return prod;
        }).toList();
        state = AsyncValue.data(updated);
      });
    } catch (e) {
      await refresh();
    }
  }

  Future<void> toggleAvailability(String id, bool isAvailable) async {
    try {
      final repo = _ref.read(productRepositoryProvider);
      await repo.toggleAvailability(id, isAvailable);
      state.whenData((products) {
        final updated = products.map((prod) {
          if (prod['id'] == id) {
            return {...prod, 'is_available': isAvailable};
          }
          return prod;
        }).toList();
        state = AsyncValue.data(updated);
      });
    } catch (e) {
      await refresh();
    }
  }
}

final productListProvider = StateNotifierProvider<ProductListNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return ProductListNotifier(ref);
});
