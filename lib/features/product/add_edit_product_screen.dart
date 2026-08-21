import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../category/category_provider.dart';
import 'product_provider.dart';

class AddEditProductScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? product;

  const AddEditProductScreen({super.key, this.product});

  @override
  ConsumerState<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  
  String? _selectedCategoryId;
  String _selectedUnit = 'kg';
  bool _isAvailable = true;
  bool _isEnabled = true;

  final List<String> _units = ['kg', 'gram', 'litre', 'piece', 'packet'];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    final isEdit = p != null;

    _nameController = TextEditingController(text: isEdit ? p['name'] : '');
    _descriptionController = TextEditingController(text: isEdit ? p['description'] : '');
    _priceController = TextEditingController(text: isEdit ? p['price'].toString() : '');
    
    _selectedCategoryId = isEdit ? p['category_id'] : null;
    _selectedUnit = isEdit ? (p['unit'] ?? 'kg') : 'kg';
    _isAvailable = isEdit ? (p['is_available'] == true || p['is_available'] == 1) : true;
    _isEnabled = isEdit ? (p['is_enabled'] == true || p['is_enabled'] == 1) : true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final price = double.tryParse(_priceController.text) ?? 0.0;
      final isEdit = widget.product != null;

      if (isEdit) {
        ref.read(productListProvider.notifier).updateProduct(
              id: widget.product!['id'],
              name: name,
              categoryId: _selectedCategoryId,
              description: description,
              price: price,
              unit: _selectedUnit,
              isAvailable: _isAvailable,
              isEnabled: _isEnabled,
            );
      } else {
        ref.read(productListProvider.notifier).addProduct(
              name: name,
              categoryId: _selectedCategoryId,
              description: description,
              price: price,
              unit: _selectedUnit,
              isAvailable: _isAvailable,
              isEnabled: _isEnabled,
            );
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product ${isEdit ? 'updated' : 'added'} successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryListProvider);
    final isEdit = widget.product != null;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Product' : 'Add Product'),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading categories: $err')),
        data: (categories) {
          // Verify if the selected category still exists, if not clear it
          if (_selectedCategoryId != null && !categories.any((c) => c['id'] == _selectedCategoryId)) {
            _selectedCategoryId = null;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Basic Information',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const Divider(height: 24),
                          
                          // Name Input
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Product Name',
                              hintText: 'e.g. Potato (Aloo)',
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                  return 'Please enter product name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          
                          // Category Dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedCategoryId,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('Uncategorized'),
                              ),
                              ...categories.map((c) {
                                return DropdownMenuItem<String>(
                                  value: c['id'],
                                  child: Text(c['name'] ?? ''),
                                );
                              }),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _selectedCategoryId = val;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                          
                          // Description Input
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              hintText: 'e.g. Fresh potatoes from Punjab farms',
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Pricing & Stock Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pricing & Stock',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const Divider(height: 24),
                          
                          Row(
                            children: [
                              // Price Input
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: _priceController,
                                  decoration: const InputDecoration(
                                    labelText: 'Price (₹)',
                                    hintText: 'e.g. 45.00',
                                    prefixText: '₹ ',
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  validator: (val) {
                                    if (val == null || val.isEmpty) {
                                      return 'Please enter price';
                                    }
                                    if (double.tryParse(val) == null) {
                                      return 'Please enter a valid number';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              
                              // Unit Dropdown
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<String>(
                                  value: _selectedUnit,
                                  decoration: const InputDecoration(
                                    labelText: 'Unit',
                                  ),
                                  items: _units.map((unit) {
                                    return DropdownMenuItem<String>(
                                      value: unit,
                                      child: Text(unit),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _selectedUnit = val;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Availability Toggle
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Available (In Stock)'),
                            subtitle: const Text('Customers will see Out of Stock if disabled'),
                            value: _isAvailable,
                            onChanged: (val) {
                              setState(() {
                                _isAvailable = val;
                              });
                            },
                          ),
                          
                          // Enabled Toggle
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Product Status (Enabled)'),
                            subtitle: const Text('Hide product from shop entirely if disabled'),
                            value: _isEnabled,
                            onChanged: (val) {
                              setState(() {
                                _isEnabled = val;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _save,
                      child: Text(
                        isEdit ? 'SAVE CHANGES' : 'CREATE PRODUCT',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
}
