import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/providers.dart';

class CustomerSearchNotifier extends StateNotifier<String> {
  CustomerSearchNotifier() : super('');

  void setSearch(String search) {
    state = search;
  }
}

final customerSearchProvider = StateNotifierProvider<CustomerSearchNotifier, String>((ref) {
  return CustomerSearchNotifier();
});

class CustomerListNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final Ref _ref;
  Timer? _pollTimer;

  CustomerListNotifier(this._ref) : super(const AsyncValue.loading()) {
    _ref.listen<String>(customerSearchProvider, (previous, next) {
      fetchCustomers(next);
    });
    fetchCustomers(_ref.read(customerSearchProvider));

    // Setup periodic polling every 10 seconds to auto-refresh customers list!
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      silentRefresh();
    });

    _ref.onDispose(() {
      _pollTimer?.cancel();
    });
  }

  Future<void> fetchCustomers(String search) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(customerRepositoryProvider);
      final list = await repo.getCustomers(search: search);
      state = AsyncValue.data(list);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> refresh() async {
    await fetchCustomers(_ref.read(customerSearchProvider));
  }

  Future<void> silentRefresh() async {
    try {
      final search = _ref.read(customerSearchProvider);
      final repo = _ref.read(customerRepositoryProvider);
      final list = await repo.getCustomers(search: search);
      state = AsyncValue.data(list);
    } catch (_) {
      // Ignore background refresh errors
    }
  }

  Future<void> updateCustomer(String id, String name, String phone, String address, {String? areaId, String? roadId, String? subRoadId}) async {
    try {
      final repo = _ref.read(customerRepositoryProvider);
      await repo.updateCustomer(id, name, phone, address, areaId: areaId, roadId: roadId, subRoadId: subRoadId);
      await refresh();
      _ref.invalidate(customerDetailsProvider(id));
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteCustomer(String id) async {
    try {
      final repo = _ref.read(customerRepositoryProvider);
      await repo.deleteCustomer(id);
      await refresh();
      _ref.invalidate(customerDetailsProvider(id));
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }
}

final customerListProvider = StateNotifierProvider<CustomerListNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return CustomerListNotifier(ref);
});

// A provider family to load detailed information of a single customer, including history
class CustomerDetails {
  final Map<String, dynamic> customer;
  final List<Map<String, dynamic>> orderHistory;

  CustomerDetails({required this.customer, required this.orderHistory});
}

final customerDetailsProvider = FutureProvider.family<CustomerDetails, String>((ref, customerId) async {
  // Watch customerListProvider so details automatically re-evaluates when customer is updated/polled/deleted!
  ref.watch(customerListProvider);
  
  final customerRepo = ref.read(customerRepositoryProvider);
  
  final customer = await customerRepo.getCustomerById(customerId);
  if (customer == null) throw Exception('Customer not found');

  final history = await customerRepo.getCustomerOrderHistory(customerId);

  return CustomerDetails(customer: customer, orderHistory: history);
});
