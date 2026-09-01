import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/database/providers.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/admin_push_service.dart';

class OrderFilter {
  final String status;
  final String search;
  final bool preordersOnly;

  OrderFilter({this.status = 'All', this.search = '', this.preordersOnly = false});

  OrderFilter copyWith({String? status, String? search, bool? preordersOnly}) {
    return OrderFilter(
      status: status ?? this.status,
      search: search ?? this.search,
      preordersOnly: preordersOnly ?? this.preordersOnly,
    );
  }
}

class OrderFilterNotifier extends StateNotifier<OrderFilter> {
  OrderFilterNotifier() : super(OrderFilter());

  void setStatus(String status) {
    state = state.copyWith(status: status);
  }

  void setSearch(String search) {
    state = state.copyWith(search: search);
  }

  void setPreordersOnly(bool val) {
    state = state.copyWith(preordersOnly: val);
  }

  void clearFilters() {
    state = OrderFilter();
  }
}

final orderFilterProvider = StateNotifierProvider<OrderFilterNotifier, OrderFilter>((ref) {
  return OrderFilterNotifier();
});

class OrderListNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final Ref _ref;
  Timer? _pollTimer;
  final Set<String> _seenOrderIds = {};
  RealtimeChannel? _channel;

  OrderListNotifier(this._ref) : super(const AsyncValue.loading()) {
    _ref.listen<OrderFilter>(orderFilterProvider, (previous, next) {
      fetchOrders(status: next.status, search: next.search, preordersOnly: next.preordersOnly);
    });
    final filters = _ref.read(orderFilterProvider);
    fetchOrders(status: filters.status, search: filters.search, preordersOnly: filters.preordersOnly);

    // Setup periodic polling every 10 seconds to auto-refresh orders list!
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      silentRefresh();
    });

    // Realtime changes listener for orders table
    try {
      final client = Supabase.instance.client;
      _channel = client.channel('orders-realtime-changes');
      _channel!.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'orders',
        callback: (payload) {
          debugPrint('Realtime order change detected: ${payload.eventType}');
          silentRefresh();
        },
      ).subscribe();
    } catch (e) {
      debugPrint('Failed to initialize admin realtime orders subscription: $e');
    }

    _ref.onDispose(() {
      _pollTimer?.cancel();
      if (_channel != null) {
        try {
          Supabase.instance.client.removeChannel(_channel!);
        } catch (_) {}
      }
    });
  }

  void _triggerNewOrderNotification(Map<String, dynamic> ord) {
    final String orderId = ord['id'] as String;
    final customerName = ord['customer_name'] ?? 'Customer';
    final customerPhone = ord['customer_phone'] ?? '';
    final totalAmount = (ord['total_amount'] as num?)?.toDouble() ?? 0.0;

    try {
      NotificationService.instance.showNotification(
        id: orderId.hashCode,
        title: 'New Store Order Received!',
        body: 'Order #$orderId from $customerName ($customerPhone) for ₹${totalAmount.toStringAsFixed(2)}',
        payload: 'order_$orderId',
      );
    } catch (e) {
      debugPrint('Failed to trigger admin notification: $e');
    }
  }

  Future<void> fetchOrders({required String status, required String search, bool preordersOnly = false}) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(orderRepositoryProvider);
      final list = await repo.getOrders(status: status, search: search, preordersOnly: preordersOnly);
      
      final isInitialLoad = _seenOrderIds.isEmpty;
      for (final ord in list) {
        final id = ord['id'] as String;
        if (!_seenOrderIds.contains(id)) {
          if (!isInitialLoad) {
            _triggerNewOrderNotification(ord);
          }
          _seenOrderIds.add(id);
        }
      }

      state = AsyncValue.data(list);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> refresh() async {
    final filters = _ref.read(orderFilterProvider);
    await fetchOrders(status: filters.status, search: filters.search, preordersOnly: filters.preordersOnly);
  }

  Future<void> silentRefresh() async {
    try {
      final filters = _ref.read(orderFilterProvider);
      final repo = _ref.read(orderRepositoryProvider);
      final list = await repo.getOrders(status: filters.status, search: filters.search, preordersOnly: filters.preordersOnly);
      
      final isInitialLoad = _seenOrderIds.isEmpty;
      for (final ord in list) {
        final id = ord['id'] as String;
        if (!_seenOrderIds.contains(id)) {
          if (!isInitialLoad) {
            _triggerNewOrderNotification(ord);
          }
          _seenOrderIds.add(id);
        }
      }

      state = AsyncValue.data(list);
    } catch (_) {
      // Ignore background refresh errors
    }
  }

  Future<String?> updateStatus(String orderId, String newStatus) async {
    try {
      final repo = _ref.read(orderRepositoryProvider);
      await repo.updateOrderStatus(orderId, newStatus);

      // Dispatch high-priority push notification directly to customer device
      try {
        final order = await repo.getOrderById(orderId);
        if (order != null) {
          final customerId = (order['customer_id'] ?? '').toString();
          final orderNo = (order['order_number'] ?? order['offline_order_no'] ?? '').toString();
          if (customerId.isNotEmpty) {
            await AdminPushService.instance.sendOrderStatusPush(
              customerId: customerId,
              orderNo: orderNo.isNotEmpty ? orderNo : orderId.substring(0, 8),
              status: newStatus,
            );
          }
        }
      } catch (pushErr) {
        debugPrint('Order status push dispatch notice: $pushErr');
      }

      await refresh();
      // Also refresh the specific details if anyone is listening
      _ref.invalidate(orderDetailsProvider(orderId));
      return null;
    } catch (e) {
      return e.toString().replaceAll('PostgrestException: ', '').replaceAll('AuthException: ', '');
    }
  }

  Future<bool> deleteOrder(String orderId) async {
    try {
      final repo = _ref.read(orderRepositoryProvider);
      await repo.deleteOrder(orderId);
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final orderListProvider = StateNotifierProvider<OrderListNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return OrderListNotifier(ref);
});

class OrderFullDetails {
  final Map<String, dynamic> order;
  final List<Map<String, dynamic>> items;

  OrderFullDetails({required this.order, required this.items});
}

final orderDetailsProvider = FutureProvider.family<OrderFullDetails, String>((ref, orderId) async {
  // Watch orderListProvider so orderDetails automatically re-evaluates when orders are updated/polled!
  ref.watch(orderListProvider);
  
  final repo = ref.read(orderRepositoryProvider);
  final order = await repo.getOrderById(orderId);
  if (order == null) throw Exception('Order not found');
  final items = await repo.getOrderItems(orderId);
  return OrderFullDetails(order: order, items: items);
});
