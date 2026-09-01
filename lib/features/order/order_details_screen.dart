import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'order_provider.dart';

class OrderDetailsScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(orderDetailsProvider(orderId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: detailsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading order details: $err')),
        data: (details) {
          final order = details.order;
          final items = details.items;
          
          final orderDate = (DateTime.tryParse(order['order_date'] ?? '') ?? DateTime.now()).toLocal();
          final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(orderDate);
          final currentStatus = order['status'] ?? 'Pending';
          
          final List<String> statusOptions = [
            'Pending',
            'Confirmed',
            'Preparing',
            'Out for Delivery',
            'Delivered',
            'Cancelled',
          ];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Status & Number Row
                Card(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order['order_number'] ?? '',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Placed on $formattedDate',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                        // Status changer dropdown
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: currentStatus,
                              items: statusOptions.map((status) {
                                return DropdownMenuItem<String>(
                                  value: status,
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: _getStatusColor(status),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (newStatus) async {
                                if (newStatus != null) {
                                  final error = await ref.read(orderListProvider.notifier).updateStatus(orderId, newStatus);
                                  if (context.mounted) {
                                    if (error == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Order status updated to $newStatus')),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to update status: $error'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Customer & Delivery Details
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Customer Details',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const Divider(),
                              const SizedBox(height: 8),
                              Text(
                                order['customer_name'] ?? 'N/A',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Phone: ${order['customer_phone'] ?? 'N/A'}',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Delivery Address',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const Divider(),
                              const SizedBox(height: 8),
                              Text(
                                order['delivery_address'] ?? 'N/A',
                                style: TextStyle(color: Colors.grey[800], height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Order Schedule Info
                if (order['order_type'] != null || order['delivery_date'] != null)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.schedule_rounded, color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Order Schedule',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const Spacer(),
                              if (order['order_type'] != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: order['order_type'] == 'Pre-Order'
                                        ? Colors.orange[50]
                                        : Colors.green[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: order['order_type'] == 'Pre-Order'
                                          ? Colors.orange
                                          : Colors.green,
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    order['order_type'] ?? 'Normal',
                                    style: TextStyle(
                                      color: order['order_type'] == 'Pre-Order'
                                          ? Colors.orange[800]
                                          : Colors.green[800],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            children: [
                              if (order['order_taking_date'] != null) ...[
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Order-Taking Date', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatScheduleDate(order['order_taking_date'].toString()),
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (order['delivery_date'] != null) ...[
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Delivery Date', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatScheduleDate(order['delivery_date'].toString()),
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 8),

                // Order Items Table
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Items',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(height: 24),
                        Table(
                          columnWidths: const {
                            0: FlexColumnWidth(4), // Item Name
                            1: FlexColumnWidth(2), // Price
                            2: FlexColumnWidth(2), // Quantity
                            3: FlexColumnWidth(2), // Total
                          },
                          children: [
                            TableRow(
                              children: [
                                _buildTableHeader('Item Name'),
                                _buildTableHeader('Price'),
                                _buildTableHeader('Qty / Unit'),
                                _buildTableHeader('Total'),
                              ],
                            ),
                            ...items.map((item) {
                              return TableRow(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                                    child: Text(
                                      item['product_name'] ?? 'N/A',
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                                    child: Text('₹${(item['price'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                                    child: Text(_formatQuantity((item['quantity'] as num?)?.toDouble() ?? 0.0, item['unit'] ?? '')),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                                    child: Text(
                                      '₹${(item['total_price'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                        const Divider(height: 32),
                        // Grand Total Summary
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            width: 250,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Grand Total:',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  '₹${(order['total_amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatScheduleDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('EEEE, d MMM yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  Widget _buildTableHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.amber[800]!;
      case 'Confirmed':
        return Colors.blue[700]!;
      case 'Preparing':
        return Colors.purple[700]!;
      case 'Out for Delivery':
        return Colors.teal[700]!;
      case 'Delivered':
        return Colors.green[700]!;
      case 'Cancelled':
        return Colors.red[700]!;
      default:
        return Colors.grey;
    }
  }

  String _formatQuantity(double qty, String unit) {
    final unitLower = unit.toLowerCase();
    if (unitLower == 'kg') {
      if (qty == 0.25) return '250 g';
      if (qty == 0.5) return '500 g';
      if (qty == 0.75) return '750 g';
      final s = qty.toString();
      if (s.endsWith('.0')) {
        return '${qty.toInt()} kg';
      }
      return '$qty kg';
    } else if (unitLower == 'g' || unitLower == 'gram' || unitLower == 'grams') {
      return '${qty.toInt()} g';
    } else {
      if (qty == qty.toInt()) {
        return '${qty.toInt()} $unit';
      }
      return '${qty.toStringAsFixed(1)} $unit';
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Order'),
        content: const Text('Are you sure you want to permanently delete this order? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              final success = await ref.read(orderListProvider.notifier).deleteOrder(orderId);
              if (context.mounted) {
                if (success) {
                  Navigator.pop(context); // Go back to orders list
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Order deleted successfully')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to delete order'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
}
