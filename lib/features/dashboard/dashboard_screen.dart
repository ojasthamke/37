import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/database/providers.dart';
import '../order/order_provider.dart';
import '../order/order_details_screen.dart';
import '../product/product_provider.dart';
import '../customer/customer_provider.dart';

// Dashboard statistics model
class DashboardStats {
  final int totalOrders;
  final int todaysOrders;
  final int pendingOrders;
  final int completedOrders;
  final int totalCustomers;
  final int totalProducts;
  final List<Map<String, dynamic>> recentOrders;

  DashboardStats({
    required this.totalOrders,
    required this.todaysOrders,
    required this.pendingOrders,
    required this.completedOrders,
    required this.totalCustomers,
    required this.totalProducts,
    required this.recentOrders,
  });
}

// Stats provider that recalculates whenever orders, products, or customers lists are updated
final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final orderRepo = ref.read(orderRepositoryProvider);
  final productRepo = ref.read(productRepositoryProvider);
  final customerRepo = ref.read(customerRepositoryProvider);

  // Watch providers to trigger rebuild when lists are updated in providers
  ref.watch(orderListProvider);
  ref.watch(productListProvider);
  ref.watch(customerListProvider);

  // 1. Fetch products
  final productsList = await productRepo.getProducts();
  final totalProducts = productsList.length;

  // 2. Fetch customers
  final customersList = await customerRepo.getCustomers();
  final totalCustomers = customersList.length;

  // 3. Fetch orders
  final ordersList = await orderRepo.getOrders();
  final totalOrders = ordersList.length;

  // 4. Calculate today's orders count
  final todayStr = DateTime.now().toIso8601String().substring(0, 10);
  final todaysOrders = ordersList.where((o) {
    final dateStr = o['order_date']?.toString();
    return dateStr != null && dateStr.startsWith(todayStr);
  }).length;

  // 5. Calculate pending orders count
  final pendingStatuses = {'Pending', 'Confirmed', 'Preparing', 'Out for Delivery'};
  final pendingOrders = ordersList.where((o) {
    return pendingStatuses.contains(o['status']);
  }).length;

  // 6. Calculate completed orders count
  final completedOrders = ordersList.where((o) {
    return o['status'] == 'Delivered';
  }).length;

  // 7. Get recent orders (last 5)
  final sortedOrders = List<Map<String, dynamic>>.from(ordersList);
  sortedOrders.sort((a, b) {
    final aDate = DateTime.tryParse(a['order_date']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bDate = DateTime.tryParse(b['order_date']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bDate.compareTo(aDate);
  });
  
  final recentOrders = sortedOrders.take(5).map((o) {
    final map = Map<String, dynamic>.from(o);
    if (map['customers'] != null && map['customers']['name'] != null) {
      map['customer_name'] = map['customers']['name'];
    }
    return map;
  }).toList();

  return DashboardStats(
    totalOrders: totalOrders,
    todaysOrders: todaysOrders,
    pendingOrders: pendingOrders,
    completedOrders: completedOrders,
    totalCustomers: totalCustomers,
    totalProducts: totalProducts,
    recentOrders: recentOrders,
  );
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading stats: $err')),
        data: (stats) {
          final isLargeScreen = MediaQuery.of(context).size.width >= 600;
          return RefreshIndicator(
            onRefresh: () => ref.refresh(dashboardStatsProvider.future),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, Admin!',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Here is what is happening at ApliBhaji today:',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  
                  // Statistics Grid
                  GridView.count(
                    crossAxisCount: isLargeScreen ? 3 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: isLargeScreen ? 1.6 : 1.3,
                    children: [
                      _buildStatCard(
                        context,
                        title: 'Total Orders',
                        value: stats.totalOrders.toString(),
                        icon: Icons.receipt_long_rounded,
                        color: Colors.blue,
                      ),
                      _buildStatCard(
                        context,
                        title: "Today's Orders",
                        value: stats.todaysOrders.toString(),
                        icon: Icons.today_rounded,
                        color: Colors.orange,
                      ),
                      _buildStatCard(
                        context,
                        title: 'Pending Orders',
                        value: stats.pendingOrders.toString(),
                        icon: Icons.pending_actions_rounded,
                        color: Colors.amber[700]!,
                      ),
                      _buildStatCard(
                        context,
                        title: 'Completed Orders',
                        value: stats.completedOrders.toString(),
                        icon: Icons.task_alt_rounded,
                        color: Colors.green,
                      ),
                      _buildStatCard(
                        context,
                        title: 'Total Customers',
                        value: stats.totalCustomers.toString(),
                        icon: Icons.people_rounded,
                        color: Colors.purple,
                      ),
                      _buildStatCard(
                        context,
                        title: 'Total Products',
                        value: stats.totalProducts.toString(),
                        icon: Icons.shopping_basket_rounded,
                        color: Colors.teal,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Recent Orders Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Recent Orders',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Icon(Icons.history_rounded, color: Colors.grey),
                            ],
                          ),
                          const Divider(height: 24),
                          if (stats.recentOrders.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24.0),
                              child: Center(
                                child: Text(
                                  'No orders placed yet.',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: stats.recentOrders.length,
                              separatorBuilder: (context, index) => const Divider(),
                              itemBuilder: (context, index) {
                                final order = stats.recentOrders[index];
                                final orderDate = DateTime.tryParse(order['order_date'] ?? '') ?? DateTime.now();
                                final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(orderDate);
                                final status = order['status'] ?? 'Pending';
                                
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Row(
                                    children: [
                                      Text(
                                        order['order_number'] ?? '',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildStatusChip(status),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    key: ValueKey(order['id']),
                                    child: Text(
                                      '${order['customer_name'] ?? 'Guest'} • $formattedDate',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '₹${(order['total_amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => OrderDetailsScreen(orderId: order['id']),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'Pending':
        color = Colors.amber[800]!;
        break;
      case 'Confirmed':
        color = Colors.blue;
        break;
      case 'Preparing':
        color = Colors.purple;
        break;
      case 'Out for Delivery':
        color = Colors.teal;
        break;
      case 'Delivered':
        color = Colors.green;
        break;
      case 'Cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5), width: 0.5),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
