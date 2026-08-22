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
  
  // Extra compatible inventory fields
  late TextEditingController _costPriceController;
  late TextEditingController _marketPriceController;
  late TextEditingController _stockController;
  late TextEditingController _minStockController;
  late TextEditingController _barcodeController;
  late TextEditingController _weightPerPieceController;
  late TextEditingController _sequenceController;
  late TextEditingController _expiryDateController;
  late TextEditingController _batchNumberController;
  late TextEditingController _dosageInfoController;
  late TextEditingController _bestBeforeController;
  late TextEditingController _packDateController;
  bool _prescriptionRequired = false;

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
    
    // Parse extra properties from json-decoded description fields
    _costPriceController = TextEditingController(text: isEdit ? (p['cost_price']?.toString() ?? '') : '');
    _marketPriceController = TextEditingController(text: isEdit ? (p['market_price']?.toString() ?? '') : '');
    _stockController = TextEditingController(text: isEdit ? (p['stock']?.toString() ?? '') : '');
    _minStockController = TextEditingController(text: isEdit ? (p['min_stock']?.toString() ?? '') : '');
    _barcodeController = TextEditingController(text: isEdit ? (p['barcode'] ?? '') : '');
    _weightPerPieceController = TextEditingController(text: isEdit ? (p['weight_per_piece']?.toString() ?? '0.25') : '0.25');
    _sequenceController = TextEditingController(text: isEdit ? (p['sequence_no']?.toString() ?? '') : '');
    _expiryDateController = TextEditingController(text: isEdit ? (p['expiry_date'] ?? '') : '');
    _batchNumberController = TextEditingController(text: isEdit ? (p['batch_number'] ?? '') : '');
    _dosageInfoController = TextEditingController(text: isEdit ? (p['dosage_info'] ?? '') : '');
    _bestBeforeController = TextEditingController(text: isEdit ? (p['best_before'] ?? '') : '');
    _packDateController = TextEditingController(text: isEdit ? (p['pack_date'] ?? '') : '');
    _prescriptionRequired = isEdit ? (p['prescription_required'] == true) : false;

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
    _costPriceController.dispose();
    _marketPriceController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _barcodeController.dispose();
    _weightPerPieceController.dispose();
    _sequenceController.dispose();
    _expiryDateController.dispose();
    _batchNumberController.dispose();
    _dosageInfoController.dispose();
    _bestBeforeController.dispose();
    _packDateController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final price = double.tryParse(_priceController.text) ?? 0.0;
      
      final costPrice = double.tryParse(_costPriceController.text) ?? 0.0;
      final marketPrice = double.tryParse(_marketPriceController.text) ?? 0.0;
      final stock = double.tryParse(_stockController.text) ?? 0.0;
      final minStock = double.tryParse(_minStockController.text) ?? 0.0;
      final barcode = _barcodeController.text.trim();
      final weightPerPiece = double.tryParse(_weightPerPieceController.text) ?? 0.25;
      final sequenceNo = int.tryParse(_sequenceController.text) ?? 0;
      final expiryDate = _expiryDateController.text.trim();
      final batchNumber = _batchNumberController.text.trim();
      final dosageInfo = _dosageInfoController.text.trim();
      final bestBefore = _bestBeforeController.text.trim();
      final packDate = _packDateController.text.trim();

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
              costPrice: costPrice,
              marketPrice: marketPrice,
              stock: stock,
              minStock: minStock,
              barcode: barcode,
              weightPerPiece: weightPerPiece,
              sequenceNo: sequenceNo,
              expiryDate: expiryDate,
              batchNumber: batchNumber,
              prescriptionRequired: _prescriptionRequired,
              dosageInfo: dosageInfo,
              bestBefore: bestBefore,
              packDate: packDate,
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
              costPrice: costPrice,
              marketPrice: marketPrice,
              stock: stock,
              minStock: minStock,
              barcode: barcode,
              weightPerPiece: weightPerPiece,
              sequenceNo: sequenceNo,
              expiryDate: expiryDate,
              batchNumber: batchNumber,
              prescriptionRequired: _prescriptionRequired,
              dosageInfo: dosageInfo,
              bestBefore: bestBefore,
              packDate: packDate,
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
          if (_selectedCategoryId != null && !categories.any((c) => c['id'] == _selectedCategoryId)) {
            _selectedCategoryId = null;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Basic Info
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
                          const Divider(height: 20),
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
                          const SizedBox(height: 16),
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
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              hintText: 'e.g. Fresh organic potatoes',
                            ),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Pricing & Stock
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
                          const Divider(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _priceController,
                                  decoration: const InputDecoration(
                                    labelText: 'Selling Price (₹)',
                                    prefixText: '₹ ',
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  validator: (val) {
                                    if (val == null || val.isEmpty) return 'Please enter price';
                                    if (double.tryParse(val) == null) return 'Enter a number';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _costPriceController,
                                  decoration: const InputDecoration(
                                    labelText: 'Cost Price (₹)',
                                    prefixText: '₹ ',
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _marketPriceController,
                                  decoration: const InputDecoration(
                                    labelText: 'Market Price (MRP ₹)',
                                    prefixText: '₹ ',
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedUnit,
                                  decoration: const InputDecoration(labelText: 'Unit'),
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
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _stockController,
                                  decoration: const InputDecoration(
                                    labelText: 'Stock Qty',
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _minStockController,
                                  decoration: const InputDecoration(
                                    labelText: 'Min Stock Alert Qty',
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Identifiers
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Identifiers & Sorting',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const Divider(height: 20),
                          TextFormField(
                            controller: _barcodeController,
                            decoration: const InputDecoration(
                              labelText: 'Barcode',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _sequenceController,
                            decoration: const InputDecoration(
                              labelText: 'Sequence No (Sorting Order)',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. Pharmacy & Medicine Info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Medicine / Pharmacy Info',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const Divider(height: 20),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Prescription Required (Rx)'),
                            value: _prescriptionRequired,
                            onChanged: (val) {
                              setState(() {
                                _prescriptionRequired = val;
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _dosageInfoController,
                            decoration: const InputDecoration(
                              labelText: 'Dosage / Directions Info',
                              hintText: 'e.g. 1-0-1 after food',
                            ),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 5. Groceries / Advanced Settings
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Grocery / Dates Info',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const Divider(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _expiryDateController,
                                  decoration: const InputDecoration(
                                    labelText: 'Expiry Date',
                                    hintText: 'YYYY-MM-DD',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _batchNumberController,
                                  decoration: const InputDecoration(
                                    labelText: 'Batch Number',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _bestBeforeController,
                                  decoration: const InputDecoration(
                                    labelText: 'Best Before Info',
                                    hintText: 'e.g. 6 Months',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _packDateController,
                                  decoration: const InputDecoration(
                                    labelText: 'Pack Date',
                                    hintText: 'YYYY-MM-DD',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _weightPerPieceController,
                            decoration: const InputDecoration(
                              labelText: 'Weight per Piece (kg)',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Status Toggles
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Availability & Status',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const Divider(height: 20),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Available (In Stock)'),
                            subtitle: const Text('Shows Out of Stock if disabled'),
                            value: _isAvailable,
                            onChanged: (val) {
                              setState(() {
                                _isAvailable = val;
                              });
                            },
                          ),
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
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
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
