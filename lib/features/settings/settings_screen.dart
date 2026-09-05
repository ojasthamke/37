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
        const SnackBar(content: Text('Updating store & delivery configuration...')),
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
            const SnackBar(content: Text('Configuration saved successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Store Information Form Card
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.storefront_rounded, color: theme.colorScheme.primary),
                                const SizedBox(width: 10),
                                Text(
                                  'Store Information',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
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
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Delivery & Charges Configuration Card
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.local_shipping_rounded, color: theme.colorScheme.primary),
                                const SizedBox(width: 10),
                                Text(
                                  'Delivery & Shipping Charges',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),

                            // Standard Delivery Section Header
                            Text(
                              'Standard Delivery (Home Orders)',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _deliveryChargeController,
                                    decoration: const InputDecoration(
                                      labelText: 'Delivery Charge (₹)',
                                      prefixIcon: Icon(Icons.delivery_dining_rounded),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Required';
                                      }
                                      if (double.tryParse(val.trim()) == null) {
                                        return 'Invalid number';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: TextFormField(
                                    controller: _freeDeliveryThresholdController,
                                    decoration: const InputDecoration(
                                      labelText: 'Free Above (₹)',
                                      prefixIcon: Icon(Icons.local_offer_rounded),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Required';
                                      }
                                      if (double.tryParse(val.trim()) == null) {
                                        return 'Invalid number';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Save Button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: _saveStoreDetails,
                                icon: const Icon(Icons.save_rounded),
                                label: const Text('SAVE SETTINGS & CHARGES', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
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
                            'Danger zone — use the button below to permanently wipe all data from the database. Data is synced from the OrderKart POS app.',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                          const SizedBox(height: 20),
                          // Clear Database button (full width)
                          SizedBox(
                            width: double.infinity,
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
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
