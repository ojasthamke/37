import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';
import '../auth/login_screen.dart';
import '../settings/settings_provider.dart';
import 'dashboard_screen.dart';
import '../category/categories_screen.dart';
import '../product/products_screen.dart';
import '../customer/customers_screen.dart';
import '../order/orders_screen.dart';
import '../notification/notifications_screen.dart';
import '../settings/settings_screen.dart';
import '../area/areas_screen.dart';

class MainNavigationShell extends ConsumerStatefulWidget {
  const MainNavigationShell({super.key});

  @override
  ConsumerState<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    OrdersScreen(),
    ProductsScreen(),
    AreasScreen(),
    CategoriesScreen(),
    CustomersScreen(),
    NotificationsScreen(),
    SettingsScreen(),
  ];

  final List<String> _titles = const [
    'Dashboard',
    'Orders',
    'Products',
    'Areas',
    'Categories',
    'Customers',
    'Notifications',
    'Delivery & Settings',
  ];

  void _onSelectScreen(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);
    final storeName = settingsState.values['store_name'] ?? 'ApliBhaji Admin';
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      drawer: !isDesktop
          ? Drawer(
              child: SafeArea(
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withValues(alpha: 0.85),
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Image.asset(
                                'assets/logo.jpg',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(Icons.storefront_rounded, size: 32, color: Color(0xFF1B3624)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            storeName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Store Admin Panel',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: [
                          _buildDrawerItem(Icons.dashboard_rounded, 'Dashboard', 0),
                          _buildDrawerItem(Icons.receipt_long_rounded, 'Orders', 1),
                          const Divider(height: 16),
                          _buildDrawerItem(Icons.shopping_bag_rounded, 'Products', 2),
                          _buildDrawerItem(Icons.map_rounded, 'Areas & Routes', 3),
                          _buildDrawerItem(Icons.category_rounded, 'Categories', 4),
                          _buildDrawerItem(Icons.people_rounded, 'Customers', 5),
                          const Divider(height: 16),
                          _buildDrawerItem(Icons.local_shipping_rounded, 'Delivery & Settings', 7),
                          _buildDrawerItem(Icons.notifications_rounded, 'Notifications', 6),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) {
            return PopupMenuButton<int>(
              tooltip: 'Navigation Menu',
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.more_vert_rounded,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
              ),
              onSelected: _onSelectScreen,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 0,
                  child: Row(
                    children: [
                      Icon(Icons.dashboard_rounded, color: Color(0xFF2E6F40), size: 20),
                      SizedBox(width: 12),
                      Text('Dashboard', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 1,
                  child: Row(
                    children: [
                      Icon(Icons.receipt_long_rounded, color: Color(0xFF2E6F40), size: 20),
                      SizedBox(width: 12),
                      Text('Orders', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 2,
                  child: Row(
                    children: [
                      Icon(Icons.shopping_bag_rounded, color: Color(0xFF2E6F40), size: 20),
                      SizedBox(width: 12),
                      Text('Products', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 3,
                  child: Row(
                    children: [
                      Icon(Icons.map_rounded, color: Color(0xFF2E6F40), size: 20),
                      SizedBox(width: 12),
                      Text('Areas & Routes', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 4,
                  child: Row(
                    children: [
                      Icon(Icons.category_rounded, color: Color(0xFF2E6F40), size: 20),
                      SizedBox(width: 12),
                      Text('Categories', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 5,
                  child: Row(
                    children: [
                      Icon(Icons.people_rounded, color: Color(0xFF2E6F40), size: 20),
                      SizedBox(width: 12),
                      Text('Customers', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 7,
                  child: Row(
                    children: [
                      Icon(Icons.local_shipping_rounded, color: Color(0xFF2E6F40), size: 20),
                      SizedBox(width: 12),
                      Text('Delivery & Settings', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 6,
                  child: Row(
                    children: [
                      Icon(Icons.notifications_rounded, color: Color(0xFF2E6F40), size: 20),
                      SizedBox(width: 12),
                      Text('Notifications', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        title: Text(
          '$storeName — ${_titles[_selectedIndex]}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          if (_selectedIndex > 1)
            IconButton(
              tooltip: 'Home Dashboard',
              icon: const Icon(Icons.home_rounded),
              onPressed: () => _onSelectScreen(0),
            ),
          // Log Out button
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to log out of admin?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          if (isDesktop) ...[
            NavigationRail(
              extended: true,
              minWidth: 72,
              selectedIndex: _selectedIndex,
              backgroundColor: theme.colorScheme.surfaceContainerLow,
              onDestinationSelected: _onSelectScreen,
              leading: Column(
                children: [
                  const SizedBox(height: 16),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Image.asset(
                        'assets/logo.jpg',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.storefront_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long_rounded),
                  label: Text('Orders'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.shopping_bag_outlined),
                  selectedIcon: Icon(Icons.shopping_bag_rounded),
                  label: Text('Products'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.map_outlined),
                  selectedIcon: Icon(Icons.map_rounded),
                  label: Text('Areas'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.category_outlined),
                  selectedIcon: Icon(Icons.category_rounded),
                  label: Text('Categories'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people_outline_rounded),
                  selectedIcon: Icon(Icons.people_rounded),
                  label: Text('Customers'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.notifications_outlined),
                  selectedIcon: Icon(Icons.notifications_rounded),
                  label: Text('Notifications'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.local_shipping_outlined),
                  selectedIcon: Icon(Icons.local_shipping_rounded),
                  label: Text('Delivery & Settings'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
          ],
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
      bottomNavigationBar: !isDesktop
          ? Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: NavigationBar(
                selectedIndex: _selectedIndex <= 1 ? _selectedIndex : 0,
                onDestinationSelected: (int index) {
                  _onSelectScreen(index);
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard_rounded),
                    label: 'Dashboard',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.receipt_long_outlined),
                    selectedIcon: Icon(Icons.receipt_long_rounded),
                    label: 'Orders',
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    final isSelected = _selectedIndex == index;
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? theme.colorScheme.primary : const Color(0xFF64748B),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? theme.colorScheme.primary : const Color(0xFF1E293B),
        ),
      ),
      selected: isSelected,
      selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onTap: () {
        Navigator.pop(context);
        _onSelectScreen(index);
      },
    );
  }
}
