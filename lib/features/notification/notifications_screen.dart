import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../customer/customer_provider.dart';

enum NotificationTargetMode { broadcast, byArea, byCustomer }

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _customerSearchController = TextEditingController();

  NotificationTargetMode _targetMode = NotificationTargetMode.broadcast;
  String? _selectedAreaId;
  final Set<String> _selectedCustomerIds = <String>{};
  String _customerSearchQuery = '';

  List<Map<String, dynamic>> _areas = [];
  Map<String, int> _areaCustomerCounts = {};
  bool _isLoadingAreas = false;

  bool _isSending = false;
  List<Map<String, dynamic>> _sentHistory = [];
  bool _isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
    _loadAreasAndCounts();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _customerSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadAreasAndCounts() async {
    setState(() {
      _isLoadingAreas = true;
    });
    try {
      final client = Supabase.instance.client;
      final List<dynamic> areasRes = await client
          .from('areas')
          .select('id, name')
          .order('name', ascending: true);

      final List<dynamic> customersRes = await client
          .from('customers')
          .select('id, area_id');

      final Map<String, int> counts = {};
      for (var c in customersRes) {
        final aId = c['area_id']?.toString();
        if (aId != null && aId.isNotEmpty) {
          counts[aId] = (counts[aId] ?? 0) + 1;
        }
      }

      setState(() {
        _areas = List<Map<String, dynamic>>.from(areasRes);
        _areaCustomerCounts = counts;
        if (_selectedAreaId == null && _areas.isNotEmpty) {
          _selectedAreaId = _areas.first['id'].toString();
        }
      });
    } catch (e) {
      debugPrint('Error loading areas for notifications: $e');
    } finally {
      setState(() {
        _isLoadingAreas = false;
      });
    }
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoadingHistory = true;
    });
    try {
      final client = Supabase.instance.client;
      final res = await client
          .from('notifications')
          .select('*')
          .order('created_at', ascending: false)
          .limit(50);
      setState(() {
        _sentHistory = List<Map<String, dynamic>>.from(res);
      });
    } catch (e) {
      debugPrint('Error fetching notification history: $e');
    } finally {
      setState(() {
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _deleteHistoryItem(String id) async {
    try {
      final client = Supabase.instance.client;
      await client.from('notifications').delete().eq('id', id);
      setState(() {
        _sentHistory.removeWhere((item) => item['id'] == id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification removed from history.')),
        );
      }
    } catch (e) {
      debugPrint('Failed to delete history item: $e');
    }
  }

  void _applyTemplate(String title, String body) {
    setState(() {
      _titleController.text = title;
      _bodyController.text = body;
    });
  }

  Future<void> _sendNotification(List<Map<String, dynamic>> allCustomers) async {
    if (!_formKey.currentState!.validate()) return;

    if (_targetMode == NotificationTargetMode.byArea && (_selectedAreaId == null || _selectedAreaId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a target delivery area.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_targetMode == NotificationTargetMode.byCustomer && _selectedCustomerIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one customer name.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    final client = Supabase.instance.client;
    final nowIso = DateTime.now().toUtc().toIso8601String();

    try {
      if (_targetMode == NotificationTargetMode.broadcast) {
        // 1. BROADCAST TO ALL — Database trigger trg_dispatch_push_notification dispatches push automatically
        await client.from('notifications').insert({
          'title': title,
          'body': body,
          'customer_id': null,
          'area_id': null,
          'target_type': 'broadcast',
          'created_at': nowIso,
        });

      } else if (_targetMode == NotificationTargetMode.byArea) {
        // 2. TARGET BY AREA — Database trigger trg_dispatch_push_notification dispatches push automatically
        await client.from('notifications').insert({
          'title': title,
          'body': body,
          'customer_id': null,
          'area_id': _selectedAreaId,
          'target_type': 'area',
          'created_at': nowIso,
        });

      } else if (_targetMode == NotificationTargetMode.byCustomer) {
        // 3. TARGET BY CUSTOMER NAMES — Database trigger trg_dispatch_push_notification dispatches push automatically
        final customerIdsList = _selectedCustomerIds.toList();
        for (final custId in customerIdsList) {
          final matched = allCustomers.firstWhere(
            (c) => c['id'].toString() == custId,
            orElse: () => <String, dynamic>{},
          );
          final areaId = matched['area_id']?.toString();

          await client.from('notifications').insert({
            'title': title,
            'body': body,
            'customer_id': custId,
            'area_id': areaId,
            'target_type': 'customer',
            'created_at': nowIso,
          });
        }
      }

      _titleController.clear();
      _bodyController.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Notification delivered successfully 24/7!'),
          backgroundColor: Colors.green,
        ),
      );
      _fetchHistory();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customerListProvider);
    final theme = Theme.of(context);
    final List<Map<String, dynamic>> customersList = (customersAsync.value ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .where((c) => c['name'] != null && c['name'].toString().trim().isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Advanced Notification Dispatch Hub'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh History & Areas',
            onPressed: () {
              _fetchHistory();
              _loadAreasAndCounts();
            },
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Notification Composer Form
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Badge: 24/7 Delivery
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBAE6FD)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.bolt_rounded, color: Color(0xFF0284C7), size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '⚡ 24/7 Guaranteed Delivery: Notifications reach customer devices immediately, even if the store is currently closed.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF0369A1),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Target Selector Mode
                    Text(
                      '1. Select Target Audience',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildModeCard(
                          mode: NotificationTargetMode.broadcast,
                          icon: Icons.campaign_rounded,
                          title: 'All Customers',
                          subtitle: 'Broadcast to everyone',
                          color: Colors.green,
                        ),
                        const SizedBox(width: 12),
                        _buildModeCard(
                          mode: NotificationTargetMode.byArea,
                          icon: Icons.location_on_rounded,
                          title: 'By Area',
                          subtitle: 'Target specific delivery route',
                          color: Colors.purple,
                        ),
                        const SizedBox(width: 12),
                        _buildModeCard(
                          mode: NotificationTargetMode.byCustomer,
                          icon: Icons.people_alt_rounded,
                          title: 'By Customer Name',
                          subtitle: 'Search & pick individual names',
                          color: Colors.blue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Target Configuration Section
                    if (_targetMode == NotificationTargetMode.byArea)
                      _buildAreaSelectorCard()
                    else if (_targetMode == NotificationTargetMode.byCustomer)
                      _buildCustomerSelectorCard(customersList),

                    const SizedBox(height: 24),

                    // Quick Templates
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '2. Compose Notification',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Quick Templates:',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.storefront_outlined, size: 16, color: Colors.deepOrange),
                          label: const Text('Store Closed / Pre-Orders Open', style: TextStyle(fontSize: 12)),
                          onPressed: () => _applyTemplate(
                            'Store Update: Pre-Orders Open! 🛒',
                            'Our physical counter is closed today, but scheduled pre-orders for our next morning delivery are open in your app!',
                          ),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.eco_outlined, size: 16, color: Colors.green),
                          label: const Text('Fresh Harvest Arrived', style: TextStyle(fontSize: 12)),
                          onPressed: () => _applyTemplate(
                            'Fresh Farm Vegetables Just Arrived! 🥦',
                            'Farm-fresh vegetables, leafy greens, and seasonal fruits have been stocked. Order now for doorstep delivery!',
                          ),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.local_shipping_outlined, size: 16, color: Colors.blue),
                          label: const Text('Delivery Route Out', style: TextStyle(fontSize: 12)),
                          onPressed: () => _applyTemplate(
                            'Delivery Route Dispatched! 🚚',
                            'Our delivery vehicle is out on the route today. Please keep your phone accessible for doorstep handover.',
                          ),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.access_time_rounded, size: 16, color: Colors.purple),
                          label: const Text('Cutoff Reminder', style: TextStyle(fontSize: 12)),
                          onPressed: () => _applyTemplate(
                            'Night Cutoff Reminder ⏰',
                            'Remember to confirm your vegetable orders before 11:59 PM tonight for tomorrow morning delivery!',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Notification Title',
                        hintText: 'e.g. Fresh Tomatoes in stock!',
                        prefixIcon: const Icon(Icons.title_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Body
                    TextFormField(
                      controller: _bodyController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Message Body',
                        hintText: 'Type your announcement or message here...',
                        alignLabelWithHint: true,
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 60.0),
                          child: Icon(Icons.message_outlined),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'Message body is required' : null,
                    ),
                    const SizedBox(height: 28),

                    // Send Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B3624),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        icon: _isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.send_rounded),
                        label: Text(
                          _isSending ? 'DISPATCHING NOTIFICATION...' : 'SEND HIGH-PRIORITY NOTIFICATION',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        onPressed: _isSending ? null : () => _sendNotification(customersList),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const VerticalDivider(width: 1, thickness: 1),

          // Right: Sent History Panel
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sent History',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${_sentHistory.length} recorded alerts',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded),
                        tooltip: 'Refresh',
                        onPressed: _fetchHistory,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _isLoadingHistory
                      ? const Center(child: CircularProgressIndicator())
                      : _sentHistory.isEmpty
                          ? const Center(
                              child: Text(
                                'No notification history yet.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _sentHistory.length,
                              padding: const EdgeInsets.all(16.0),
                              itemBuilder: (context, index) {
                                final notif = _sentHistory[index];
                                final notifId = notif['id'].toString();
                                final targetType = notif['target_type']?.toString() ?? 'broadcast';
                                final areaId = notif['area_id']?.toString();
                                final custId = notif['customer_id']?.toString();

                                String badgeText = 'Broadcast';
                                Color badgeColor = Colors.green;
                                IconData badgeIcon = Icons.campaign_rounded;

                                if (targetType == 'area' || (areaId != null && custId == null)) {
                                  final areaMatch = _areas.firstWhere(
                                    (a) => a['id'].toString() == areaId,
                                    orElse: () => {'name': 'Area'},
                                  );
                                  badgeText = 'Area: ${areaMatch['name']}';
                                  badgeColor = Colors.purple;
                                  badgeIcon = Icons.location_on_rounded;
                                } else if (targetType == 'customer' || custId != null) {
                                  final custMatch = customersList.firstWhere(
                                    (c) => c['id'].toString() == custId,
                                    orElse: () => {'name': 'Customer'},
                                  );
                                  badgeText = 'To: ${custMatch['name']}';
                                  badgeColor = Colors.blue;
                                  badgeIcon = Icons.person_rounded;
                                }

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12.0),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 1,
                                  child: Padding(
                                    padding: const EdgeInsets.all(14.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                notif['title'] ?? '',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                                              tooltip: 'Delete',
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              onPressed: () => _deleteHistoryItem(notifId),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          notif['body'] ?? '',
                                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: badgeColor.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(badgeIcon, size: 12, color: badgeColor),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    badgeText,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: badgeColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              _formatDate(notif['created_at']),
                                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard({
    required NotificationTargetMode mode,
    required IconData icon,
    required String title,
    required String subtitle,
    required MaterialColor color,
  }) {
    final isSelected = _targetMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _targetMode = mode;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 28, color: isSelected ? color : Colors.grey[700]),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? color[900] : Colors.black87,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAreaSelectorCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.map_rounded, color: Colors.purple, size: 20),
                SizedBox(width: 8),
                Text(
                  'Select Target Delivery Area',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _isLoadingAreas
                ? const LinearProgressIndicator()
                : DropdownButtonFormField<String>(
                    value: _selectedAreaId,
                    decoration: InputDecoration(
                      labelText: 'Delivery Area',
                      prefixIcon: const Icon(Icons.location_city_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: _areas.map((a) {
                      final id = a['id'].toString();
                      final name = a['name']?.toString() ?? 'Area';
                      final count = _areaCustomerCounts[id] ?? 0;
                      return DropdownMenuItem<String>(
                        value: id,
                        child: Text('$name ($count registered customers)'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedAreaId = val;
                      });
                    },
                  ),
            const SizedBox(height: 10),
            Text(
              '🎯 Only customers residing in the selected area will receive this push alert and see it in their app.',
              style: TextStyle(fontSize: 12, color: Colors.purple[800], fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSelectorCard(List<Map<String, dynamic>> customersList) {
    final filtered = customersList.where((c) {
      final name = (c['name'] ?? '').toString().toLowerCase();
      final phone = (c['phone'] ?? c['phone1'] ?? '').toString();
      final code = (c['customer_code'] ?? '').toString().toLowerCase();
      final q = _customerSearchQuery.toLowerCase();
      return name.contains(q) || phone.contains(q) || code.contains(q);
    }).toList();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_search_rounded, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Select Customers (${_selectedCustomerIds.length} chosen)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                if (_selectedCustomerIds.isNotEmpty)
                  TextButton.icon(
                    icon: const Icon(Icons.clear_all_rounded, size: 16),
                    label: const Text('Clear All', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      setState(() {
                        _selectedCustomerIds.clear();
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Search input
            TextField(
              controller: _customerSearchController,
              decoration: InputDecoration(
                hintText: 'Search by customer name, phone, or code...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _customerSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _customerSearchController.clear();
                          setState(() {
                            _customerSearchQuery = '';
                          });
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (val) {
                setState(() {
                  _customerSearchQuery = val;
                });
              },
            ),

            // Chips of chosen customers
            if (_selectedCustomerIds.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                constraints: const BoxConstraints(maxHeight: 90),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _selectedCustomerIds.map((cId) {
                      final cust = customersList.firstWhere(
                        (c) => c['id'].toString() == cId,
                        orElse: () => {'name': 'Customer'},
                      );
                      return Chip(
                        avatar: const Icon(Icons.check_circle_rounded, size: 16, color: Colors.green),
                        label: Text(cust['name'] ?? '', style: const TextStyle(fontSize: 12)),
                        deleteIcon: const Icon(Icons.cancel_rounded, size: 16),
                        onDeleted: () {
                          setState(() {
                            _selectedCustomerIds.remove(cId);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Filtered Customer Pick List
            Container(
              height: 220,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(10),
              ),
              child: filtered.isEmpty
                  ? const Center(
                      child: Text('No customers match your search.', style: TextStyle(color: Colors.grey)),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, idx) {
                        final cust = filtered[idx];
                        final cId = cust['id'].toString();
                        final name = cust['name']?.toString() ?? 'Unnamed';
                        final phone = (cust['phone'] ?? cust['phone1'] ?? '').toString();
                        final hasToken = cust['fcm_token'] != null && cust['fcm_token'].toString().isNotEmpty;
                        final isSelected = _selectedCustomerIds.contains(cId);

                        return CheckboxListTile(
                          dense: true,
                          value: isSelected,
                          activeColor: const Color(0xFF1B3624),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: hasToken ? Colors.green[50] : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  hasToken ? 'App Active' : 'Offline/Web',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: hasToken ? Colors.green[800] : Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            phone.isNotEmpty ? phone : 'No phone',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                          onChanged: (bool? checked) {
                            setState(() {
                              if (checked == true) {
                                _selectedCustomerIds.add(cId);
                              } else {
                                _selectedCustomerIds.remove(cId);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dtStr) {
    if (dtStr == null) return '';
    try {
      final dt = DateTime.parse(dtStr).toLocal();
      return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}
