import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'customer_provider.dart';
import 'customer_details_screen.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(customerSearchProvider);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _editCustomerDialog(BuildContext context, Map<String, dynamic> customer) {
    final nameController = TextEditingController(text: customer['name'] ?? '');
    final phoneController = TextEditingController(text: customer['phone'] ?? '');
    final addressController = TextEditingController(text: customer['address'] ?? '');
    final formKey = GlobalKey<FormState>();

    String? selectedAreaId = customer['area_id'];
    String? selectedRoadId = customer['road_id'];
    String? selectedSubRoadId = customer['sub_road_id'];

    List<Map<String, dynamic>> areas = [];
    List<Map<String, dynamic>> roads = [];
    List<Map<String, dynamic>> subRoads = [];
    bool dialogLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Fetch initial lists once
            if (areas.isEmpty && !dialogLoading) {
              dialogLoading = true;
              Future.microtask(() async {
                try {
                  final res = await Supabase.instance.client.from('areas').select().order('name');
                  setState(() {
                    areas = List<Map<String, dynamic>>.from(res);
                  });
                  if (selectedAreaId != null) {
                    final resRoads = await Supabase.instance.client.from('roads').select().eq('area_id', selectedAreaId!).order('name');
                    setState(() {
                      roads = List<Map<String, dynamic>>.from(resRoads);
                    });
                  }
                  if (selectedRoadId != null) {
                    final resSubRoads = await Supabase.instance.client.from('sub_roads').select().eq('road_id', selectedRoadId!).order('name');
                    setState(() {
                      subRoads = List<Map<String, dynamic>>.from(resSubRoads);
                    });
                  }
                  setState(() {
                    dialogLoading = false;
                  });
                } catch (_) {
                  setState(() => dialogLoading = false);
                }
              });
            }

            return AlertDialog(
              title: const Text('Edit Customer Details'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneController,
                        decoration: const InputDecoration(labelText: 'Phone'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedAreaId,
                        decoration: const InputDecoration(labelText: 'Select Area'),
                        items: areas.map((a) => DropdownMenuItem(value: a['id'] as String, child: Text(a['name'] as String))).toList(),
                        onChanged: (val) async {
                          if (val != null) {
                            setState(() {
                              selectedAreaId = val;
                              selectedRoadId = null;
                              selectedSubRoadId = null;
                              roads = [];
                              subRoads = [];
                              dialogLoading = true;
                            });
                            try {
                              final resRoads = await Supabase.instance.client.from('roads').select().eq('area_id', val).order('name');
                              setState(() {
                                roads = List<Map<String, dynamic>>.from(resRoads);
                                dialogLoading = false;
                              });
                            } catch (_) {
                              setState(() => dialogLoading = false);
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedRoadId,
                        decoration: const InputDecoration(labelText: 'Select Road'),
                        disabledHint: const Text('Select Area first'),
                        items: selectedAreaId == null ? [] : roads.map((r) => DropdownMenuItem(value: r['id'] as String, child: Text(r['name'] as String))).toList(),
                        onChanged: selectedAreaId == null ? null : (val) async {
                          if (val != null) {
                            setState(() {
                              selectedRoadId = val;
                              selectedSubRoadId = null;
                              subRoads = [];
                              dialogLoading = true;
                            });
                            try {
                              final resSubRoads = await Supabase.instance.client.from('sub_roads').select().eq('road_id', val).order('name');
                              setState(() {
                                subRoads = List<Map<String, dynamic>>.from(resSubRoads);
                                dialogLoading = false;
                              });
                            } catch (_) {
                              setState(() => dialogLoading = false);
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      if (selectedRoadId != null && subRoads.isNotEmpty) ...[
                        DropdownButtonFormField<String>(
                          value: selectedSubRoadId,
                          decoration: const InputDecoration(labelText: 'Select Sub-Road (Optional)'),
                          items: subRoads.map((sr) => DropdownMenuItem(value: sr['id'] as String, child: Text(sr['name'] as String))).toList(),
                          onChanged: (val) {
                            setState(() {
                              selectedSubRoadId = val;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: addressController,
                        decoration: const InputDecoration(labelText: 'Address'),
                        maxLines: 2,
                      ),
                      if (dialogLoading) ...[
                        const SizedBox(height: 12),
                        const CircularProgressIndicator(),
                      ]
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: dialogLoading ? null : () async {
                    if (formKey.currentState!.validate()) {
                      if (selectedAreaId == null || selectedRoadId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select Area and Road')),
                        );
                        return;
                      }
                      try {
                        await ref.read(customerListProvider.notifier).updateCustomer(
                          customer['id'],
                          nameController.text.trim(),
                          phoneController.text.trim(),
                          addressController.text.trim(),
                          areaId: selectedAreaId,
                          roadId: selectedRoadId,
                          subRoadId: selectedSubRoadId,
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Customer details updated successfully!')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteCustomerDialog(BuildContext context, Map<String, dynamic> customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text(
          'Are you sure you want to delete customer "${customer['name'] ?? 'N/A'}"?\n\n'
          'WARNING: This will cascade-delete all of this customer\'s historical orders and order items.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await ref.read(customerListProvider.notifier).deleteCustomer(customer['id']);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Customer deleted successfully!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customerListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          // Search Input
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search customers by name, phone or address...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(customerSearchProvider.notifier).setSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) {
                ref.read(customerSearchProvider.notifier).setSearch(val.trim());
                setState(() {});
              },
            ),
          ),

          Expanded(
            child: customersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error loading customers: $err')),
              data: (customers) {
                if (customers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No customers found.',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref.read(customerListProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final c = customers[index];
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CustomerDetailsScreen(customerId: c['id']),
                              ),
                            );
                          },
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                            child: Icon(Icons.person_rounded, color: theme.colorScheme.primary),
                          ),
                          title: Text(
                            c['name'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Phone: ${c['phone'] ?? 'N/A'}'),
                                const SizedBox(height: 2),
                                Text(
                                  c['address'] ?? 'No address listed',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Edit Details',
                                onPressed: () => _editCustomerDialog(context, c),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                                tooltip: 'Delete Customer',
                                onPressed: () => _deleteCustomerDialog(context, c),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
