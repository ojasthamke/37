import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../customer/customer_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  
  String? _selectedCustomerId; // Null means "All Customers"
  bool _isSending = false;
  List<Map<String, dynamic>> _sentHistory = [];
  bool _isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoadingHistory = true;
    });
    try {
      final client = Supabase.instance.client;
      final res = await client
          .from('notifications')
          .select('*, customers(name, phone)')
          .order('created_at', ascending: false);
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

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSending = true;
    });

    try {
      final client = Supabase.instance.client;
      await client.from('notifications').insert({
        'title': _titleController.text.trim(),
        'body': _bodyController.text.trim(),
        'customer_id': _selectedCustomerId,
      });

      _titleController.clear();
      _bodyController.clear();
      setState(() {
        _selectedCustomerId = null;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification sent successfully!'),
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
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customerListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compose Notification Section
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Compose Push Notification',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Send real-time updates, announcements, or custom offers to customer devices.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Notification Title',
                        hintText: 'e.g. Fresh Tomatoes in stock!',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title_rounded),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Title is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Body
                    TextFormField(
                      controller: _bodyController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Message Body',
                        hintText: 'Type your announcement here...',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 60.0),
                          child: Icon(Icons.message_outlined),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Message body is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Target Customer dropdown
                    customersAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => const Text('Error loading customers'),
                      data: (customers) {
                        // Filter out ghost houses
                        final realCustomers = customers
                            .where((c) => c['name'] != null && c['name'].toString().trim().isNotEmpty)
                            .toList();

                        return DropdownButtonFormField<String?>(
                          value: _selectedCustomerId,
                          decoration: const InputDecoration(
                            labelText: 'Send To',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.people_alt_rounded),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('All Customers (Broadcast)'),
                            ),
                            ...realCustomers.map((c) {
                              return DropdownMenuItem<String?>(
                                value: c['id'] as String,
                                child: Text('${c['name']} (${c['phone1'] ?? ''})'),
                              );
                            }),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _selectedCustomerId = val;
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    // Send Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: _isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.send_rounded),
                        label: Text(
                          _isSending ? 'Sending alert...' : 'SEND REAL-TIME NOTIFICATION',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        onPressed: _isSending ? null : _sendNotification,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const VerticalDivider(width: 1, thickness: 1),

          // Notification History Sidebar
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sent History',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded),
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
                                'No notifications sent yet.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _sentHistory.length,
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              itemBuilder: (context, index) {
                                final notif = _sentHistory[index];
                                final cust = notif['customers'] as Map<String, dynamic>?;
                                final targetLabel = cust != null
                                    ? 'To: ${cust['name']}'
                                    : 'To: All Customers';

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12.0),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                notif['title'] ?? '',
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: cust != null ? Colors.blue[50] : Colors.green[50],
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                cust != null ? 'Direct' : 'Broadcast',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: cust != null ? Colors.blue[800] : Colors.green[800],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          notif['body'] ?? '',
                                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              targetLabel,
                                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                                            ),
                                            Text(
                                              _formatDate(notif['created_at']),
                                              style: const TextStyle(fontSize: 10, color: Colors.grey),
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
