import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _deliveryChargeController;
  late TextEditingController _freeDeliveryThresholdController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _deliveryChargeController = TextEditingController();
    _freeDeliveryThresholdController = TextEditingController();
    
    // Populate controllers once values are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(settingsProvider).values;
      _nameController.text = settings['store_name'] ?? '';
      _phoneController.text = settings['store_phone'] ?? '';
      _addressController.text = settings['store_address'] ?? '';
      _deliveryChargeController.text = settings['delivery_charge'] ?? '30';
      _freeDeliveryThresholdController.text = settings['free_delivery_threshold'] ?? '300';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _deliveryChargeController.dispose();
    _freeDeliveryThresholdController.dispose();
    super.dispose();
  }

  void _saveStoreDetails() async {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Updating store configuration...')),
      );
      try {
        await Future.wait([
          ref.read(settingsProvider.notifier).updateSetting('store_name', _nameController.text.trim()),
          ref.read(settingsProvider.notifier).updateSetting('store_phone', _phoneController.text.trim()),
          ref.read(settingsProvider.notifier).updateSetting('store_address', _addressController.text.trim()),
          ref.read(settingsProvider.notifier).updateSetting('delivery_charge', _deliveryChargeController.text.trim()),
          ref.read(settingsProvider.notifier).updateSetting('free_delivery_threshold', _freeDeliveryThresholdController.text.trim()),
        ]);
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Store configuration updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update configuration: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    // If data updates in background, keep controllers in sync
    ref.listen<SettingsState>(settingsProvider, (previous, next) {
      if (previous?.isLoading == true && !next.isLoading) {
        _nameController.text = next.values['store_name'] ?? '';
        _phoneController.text = next.values['store_phone'] ?? '';
        _addressController.text = next.values['store_address'] ?? '';
        _deliveryChargeController.text = next.values['delivery_charge'] ?? '30';
        _freeDeliveryThresholdController.text = next.values['free_delivery_threshold'] ?? '300';
      }
    });

    return Scaffold(
      body: settingsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Store Configuration Form Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Store Configuration',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const Divider(height: 24),
                            
                            // Store Name
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Store Name',
                                prefixIcon: Icon(Icons.store_rounded),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Please enter store name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Contact Phone
                            TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'Contact Phone Number',
                                prefixIcon: Icon(Icons.phone_rounded),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Please enter phone number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Address
                            TextFormField(
                              controller: _addressController,
                              decoration: const InputDecoration(
                                labelText: 'Store Address',
                                prefixIcon: Icon(Icons.location_on_rounded),
                              ),
                              maxLines: 2,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Please enter store address';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Delivery Charge
                            TextFormField(
                              controller: _deliveryChargeController,
                              decoration: const InputDecoration(
                                labelText: 'Delivery Charge (₹)',
                                prefixIcon: Icon(Icons.delivery_dining_rounded),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Please enter delivery charge';
                                }
                                if (double.tryParse(val.trim()) == null) {
                                  return 'Please enter a valid amount';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Free Delivery Threshold
                            TextFormField(
                              controller: _freeDeliveryThresholdController,
                              decoration: const InputDecoration(
                                labelText: 'Free Delivery Threshold (₹)',
                                prefixIcon: Icon(Icons.local_offer_rounded),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Please enter free delivery threshold';
                                }
                                if (double.tryParse(val.trim()) == null) {
                                  return 'Please enter a valid amount';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            
                            // Save Button
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: _saveStoreDetails,
                                icon: const Icon(Icons.save_rounded),
                                label: const Text('SAVE STORE CONFIG'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Data Administration Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Database Administration',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.red[800],
                            ),
                          ),
                          const Divider(height: 24),
                          Text(
                            'Use these commands to set up mock data for testing or clear database collections.',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              // Seed Database button
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[700],
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Seed Database'),
                                        content: const Text('Are you sure you want to insert mock products and customers into the LIVE Supabase production database? This will mix test data with your real customer records.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              ref.read(settingsProvider.notifier).seedDatabase();
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Mock database seeded successfully!')),
                                              );
                                            },
                                            child: const Text('Seed Data'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.playlist_add_check_rounded),
                                  label: const Text('SEED MOCK DATA'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Clear Database button
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red[700],
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Wipe Database'),
                                        content: const Text('Are you sure you want to permanently clear all categories, products, orders, and customer logs from the LIVE Supabase database? This action is IRREVERSIBLE and will delete all real customer records!'),
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
                                            onPressed: () {
                                              Navigator.pop(context);
                                              ref.read(settingsProvider.notifier).wipeDatabase();
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Database cleared successfully')),
                                              );
                                            },
                                            child: const Text('Wipe All'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.delete_sweep_rounded),
                                  label: const Text('CLEAR ALL DATA'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
