import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AreasScreen extends StatefulWidget {
  const AreasScreen({super.key});

  @override
  State<AreasScreen> createState() => _AreasScreenState();
}

class _AreasScreenState extends State<AreasScreen> {
  final _client = Supabase.instance.client;
  List<Map<String, dynamic>> _areas = [];
  bool _isLoading = false;

  // Selected state for navigation/filtering
  String? _selectedAreaId;
  String? _selectedRoadId;

  List<Map<String, dynamic>> _roads = [];
  List<Map<String, dynamic>> _subRoads = [];

  // Customer counts cache
  final Map<String, int> _customerCounts = {};

  final List<String> _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _fetchAreas();
  }

  Future<void> _fetchAreas() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final List<dynamic> res = await _client
          .from('areas')
          .select()
          .order('name', ascending: true);
      setState(() {
        _areas = List<Map<String, dynamic>>.from(res);
      });
      for (final area in _areas) {
        _fetchCustomerCount('area', area['id'] as String);
      }
    } catch (e) {
      _showError('Failed to load areas: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchRoads(String areaId) async {
    try {
      final List<dynamic> res = await _client
          .from('roads')
          .select()
          .eq('area_id', areaId)
          .order('name', ascending: true);
      setState(() {
        _roads = List<Map<String, dynamic>>.from(res);
        _subRoads = [];
        _selectedRoadId = null;
      });
      for (final road in _roads) {
        _fetchCustomerCount('road', road['id'] as String);
      }
    } catch (e) {
      _showError('Failed to load roads: $e');
    }
  }

  Future<void> _fetchSubRoads(String roadId) async {
    try {
      final List<dynamic> res = await _client
          .from('sub_roads')
          .select()
          .eq('road_id', roadId)
          .order('name', ascending: true);
      setState(() {
        _subRoads = List<Map<String, dynamic>>.from(res);
      });
      for (final subRoad in _subRoads) {
        _fetchCustomerCount('sub_road', subRoad['id'] as String);
      }
    } catch (e) {
      _showError('Failed to load sub-roads: $e');
    }
  }

  Future<void> _fetchCustomerCount(String type, String id) async {
    try {
      final List<dynamic> response = await _client
          .from('customers')
          .select('id')
          .eq('${type}_id', id);
      
      final count = response.length;
      setState(() {
        _customerCounts['$type:$id'] = count;
      });
    } catch (_) {}
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // ==========================================
  // AREA CRUD
  // ==========================================

  void _showAreaDialog({Map<String, dynamic>? area}) {
    final nameController = TextEditingController(text: area?['name'] ?? '');
    List<String> selectedDays = [];
    if (area != null && area['delivery_schedule'] != null) {
      selectedDays = List<String>.from(json.decode(json.encode(area['delivery_schedule'])));
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(area == null ? 'Add Area' : 'Edit Area'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Area Name',
                        hintText: 'e.g. Kothrud',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Delivery Schedule:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    ..._weekdays.map((day) {
                      final isSelected = selectedDays.contains(day);
                      return CheckboxListTile(
                        title: Text(day),
                        value: isSelected,
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (val) {
                          setDialogState(() {
                            if (val == true) {
                              selectedDays.add(day);
                            } else {
                              selectedDays.remove(day);
                            }
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    Navigator.pop(context);
                    
                    try {
                      if (area == null) {
                        await _client.from('areas').insert({
                          'name': nameController.text.trim(),
                          'delivery_schedule': selectedDays,
                        });
                      } else {
                        await _client.from('areas').update({
                          'name': nameController.text.trim(),
                          'delivery_schedule': selectedDays,
                        }).eq('id', area['id']);
                      }
                      _fetchAreas();
                    } catch (e) {
                      _showError('Failed to save area: $e');
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

  Future<void> _deleteArea(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Area'),
        content: const Text('Are you sure you want to delete this Area? All child Roads, Sub-roads, and Customer mappings will be affected.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _client.from('areas').delete().eq('id', id);
      _fetchAreas();
      if (_selectedAreaId == id) {
        setState(() {
          _selectedAreaId = null;
          _roads = [];
          _subRoads = [];
          _selectedRoadId = null;
        });
      }
    } catch (e) {
      _showError('Failed to delete area: $e');
    }
  }

  // ==========================================
  // ROAD CRUD
  // ==========================================

  void _showRoadDialog({Map<String, dynamic>? road}) {
    if (_selectedAreaId == null) return;
    final nameController = TextEditingController(text: road?['name'] ?? '');
    
    bool hasOverride = road?['delivery_schedule'] != null;
    List<String> selectedDays = [];
    if (road != null && road['delivery_schedule'] != null) {
      selectedDays = List<String>.from(json.decode(json.encode(road['delivery_schedule'])));
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(road == null ? 'Add Road' : 'Edit Road'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Road Name',
                        hintText: 'e.g. Sunrise Heights Road',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Override Area Schedule', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      value: hasOverride,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setDialogState(() {
                          hasOverride = val;
                          if (!hasOverride) {
                            selectedDays = [];
                          }
                        });
                      },
                    ),
                    if (hasOverride) ...[
                      const SizedBox(height: 8),
                      ..._weekdays.map((day) {
                        final isSelected = selectedDays.contains(day);
                        return CheckboxListTile(
                          title: Text(day),
                          value: isSelected,
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (val) {
                            setDialogState(() {
                              if (val == true) {
                                selectedDays.add(day);
                              } else {
                                selectedDays.remove(day);
                              }
                            });
                          },
                        );
                      }),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    Navigator.pop(context);
                    
                    try {
                      final schedule = hasOverride ? selectedDays : null;
                      if (road == null) {
                        await _client.from('roads').insert({
                          'area_id': _selectedAreaId,
                          'name': nameController.text.trim(),
                          'delivery_schedule': schedule,
                        });
                      } else {
                        await _client.from('roads').update({
                          'name': nameController.text.trim(),
                          'delivery_schedule': schedule,
                        }).eq('id', road['id']);
                      }
                      _fetchRoads(_selectedAreaId!);
                    } catch (e) {
                      _showError('Failed to save road: $e');
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

  Future<void> _deleteRoad(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Road'),
        content: const Text('Are you sure you want to delete this Road? All child Sub-roads and Customer mappings will be affected.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _client.from('roads').delete().eq('id', id);
      _fetchRoads(_selectedAreaId!);
      if (_selectedRoadId == id) {
        setState(() {
          _selectedRoadId = null;
          _subRoads = [];
        });
      }
    } catch (e) {
      _showError('Failed to delete road: $e');
    }
  }

  // ==========================================
  // SUB-ROAD CRUD
  // ==========================================

  void _showSubRoadDialog({Map<String, dynamic>? subRoad}) {
    if (_selectedRoadId == null) return;
    final nameController = TextEditingController(text: subRoad?['name'] ?? '');
    
    bool hasOverride = subRoad?['delivery_schedule'] != null;
    List<String> selectedDays = [];
    if (subRoad != null && subRoad['delivery_schedule'] != null) {
      selectedDays = List<String>.from(json.decode(json.encode(subRoad['delivery_schedule'])));
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(subRoad == null ? 'Add Sub-Road' : 'Edit Sub-Road'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Sub-Road Name',
                        hintText: 'e.g. Apt 201 Lane',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Override Schedule', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      value: hasOverride,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setDialogState(() {
                          hasOverride = val;
                          if (!hasOverride) {
                            selectedDays = [];
                          }
                        });
                      },
                    ),
                    if (hasOverride) ...[
                      const SizedBox(height: 8),
                      ..._weekdays.map((day) {
                        final isSelected = selectedDays.contains(day);
                        return CheckboxListTile(
                          title: Text(day),
                          value: isSelected,
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (val) {
                            setDialogState(() {
                              if (val == true) {
                                selectedDays.add(day);
                              } else {
                                selectedDays.remove(day);
                              }
                            });
                          },
                        );
                      }),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    Navigator.pop(context);
                    
                    try {
                      final schedule = hasOverride ? selectedDays : null;
                      if (subRoad == null) {
                        await _client.from('sub_roads').insert({
                          'road_id': _selectedRoadId,
                          'name': nameController.text.trim(),
                          'delivery_schedule': schedule,
                        });
                      } else {
                        await _client.from('sub_roads').update({
                          'name': nameController.text.trim(),
                          'delivery_schedule': schedule,
                        }).eq('id', subRoad['id']);
                      }
                      _fetchSubRoads(_selectedRoadId!);
                    } catch (e) {
                      _showError('Failed to save sub-road: $e');
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

  Future<void> _deleteSubRoad(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Sub-Road'),
        content: const Text('Are you sure you want to delete this Sub-Road? Customer mappings will be reset.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _client.from('sub_roads').delete().eq('id', id);
      _fetchSubRoads(_selectedRoadId!);
    } catch (e) {
      _showError('Failed to delete sub-road: $e');
    }
  }

  // ==========================================
  // CUSTOMER ROUTE LIST VIEW
  // ==========================================

  void _showCustomerListDialog(String type, String id, String name) async {
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Loading customers...'),
          ],
        ),
      ),
    );

    try {
      final List<dynamic> res = await _client
          .from('customers')
          .select('name, customer_code, phone, address')
          .eq('${type}_id', id)
          .order('name');
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      final List<Map<String, dynamic>> customers = List<Map<String, dynamic>>.from(res);

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Customers on $name (${customers.length})'),
            content: SizedBox(
              width: 500,
              height: 400,
              child: customers.isEmpty
                  ? const Center(child: Text('No customers registered on this route.'))
                  : ListView.separated(
                      itemCount: customers.length,
                      separatorBuilder: (context, idx) => const Divider(),
                      itemBuilder: (context, idx) {
                        final c = customers[idx];
                        final codeStr = c['customer_code'] ?? 'No Code';
                        return ListTile(
                          title: Text(c['name'] ?? 'Unnamed Customer', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Address: ${c['address'] ?? 'N/A'}'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(codeStr, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber[900], fontSize: 11)),
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading
      _showError('Failed to fetch customers: $e');
    }
  }

  // ==========================================
  // VIEW LAYOUT
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width >= 1000;

    Widget areasList = Card(
      child: Column(
        children: [
          AppBar(
            title: const Text('Areas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Add Area',
                onPressed: () => _showAreaDialog(),
              )
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _areas.isEmpty
                    ? const Center(child: Text('No Areas configured.'))
                    : ListView.builder(
                        itemCount: _areas.length,
                        itemBuilder: (context, idx) {
                          final area = _areas[idx];
                          final isSelected = _selectedAreaId == area['id'];
                          final count = _customerCounts['area:${area['id']}'] ?? 0;
                          final schedule = (area['delivery_schedule'] as List?)?.join(', ') ?? 'None';

                          return ListTile(
                            selected: isSelected,
                            selectedTileColor: theme.colorScheme.primary.withOpacity(0.08),
                            title: Text('${area['name']} (${area['id']})', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Schedule: $schedule'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: () => _showCustomerListDialog('area', area['id'] as String, area['name'] as String),
                                  child: Text('$count Customers', style: const TextStyle(fontSize: 12)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 20),
                                  onPressed: () => _showAreaDialog(area: area),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                  onPressed: () => _deleteArea(area['id'] as String),
                                ),
                              ],
                            ),
                            onTap: () {
                              setState(() {
                                _selectedAreaId = area['id'] as String;
                              });
                              _fetchRoads(area['id'] as String);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );

    Widget roadsList = Card(
      child: Column(
        children: [
          AppBar(
            title: const Text('Roads / Routes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              if (_selectedAreaId != null)
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Add Road',
                  onPressed: () => _showRoadDialog(),
                )
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: _selectedAreaId == null
                ? const Center(child: Text('Select an Area to view Roads.'))
                : _roads.isEmpty
                    ? const Center(child: Text('No Roads in this Area.'))
                    : ListView.builder(
                        itemCount: _roads.length,
                        itemBuilder: (context, idx) {
                          final road = _roads[idx];
                          final isSelected = _selectedRoadId == road['id'];
                          final count = _customerCounts['road:${road['id']}'] ?? 0;
                          final schedule = road['delivery_schedule'] == null
                              ? 'Inherited'
                              : (road['delivery_schedule'] as List).join(', ');

                          return ListTile(
                            selected: isSelected,
                            selectedTileColor: theme.colorScheme.primary.withOpacity(0.08),
                            title: Text('${road['name']} (${road['id']})', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Schedule: $schedule'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: () => _showCustomerListDialog('road', road['id'] as String, road['name'] as String),
                                  child: Text('$count Customers', style: const TextStyle(fontSize: 12)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 20),
                                  onPressed: () => _showRoadDialog(road: road),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                  onPressed: () => _deleteRoad(road['id'] as String),
                                ),
                              ],
                            ),
                            onTap: () {
                              setState(() {
                                _selectedRoadId = road['id'] as String;
                              });
                              _fetchSubRoads(road['id'] as String);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );

    Widget subRoadsList = Card(
      child: Column(
        children: [
          AppBar(
            title: const Text('Sub-Roads / Lanes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              if (_selectedRoadId != null)
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Add Sub-Road',
                  onPressed: () => _showSubRoadDialog(),
                )
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: _selectedRoadId == null
                ? const Center(child: Text('Select a Road to view Sub-Roads.'))
                : _subRoads.isEmpty
                    ? const Center(child: Text('No Sub-Roads / Lanes on this Road.'))
                    : ListView.builder(
                        itemCount: _subRoads.length,
                        itemBuilder: (context, idx) {
                          final subRoad = _subRoads[idx];
                          final count = _customerCounts['sub_road:${subRoad['id']}'] ?? 0;
                          final schedule = subRoad['delivery_schedule'] == null
                              ? 'Inherited'
                              : (subRoad['delivery_schedule'] as List).join(', ');

                          return ListTile(
                            title: Text('${subRoad['name']} (${subRoad['id']})', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Schedule: $schedule'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: () => _showCustomerListDialog('sub_road', subRoad['id'] as String, subRoad['name'] as String),
                                  child: Text('$count Customers', style: const TextStyle(fontSize: 12)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 20),
                                  onPressed: () => _showSubRoadDialog(subRoad: subRoad),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                  onPressed: () => _deleteSubRoad(subRoad['id'] as String),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );

    if (isWide) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(child: areasList),
            const SizedBox(width: 12),
            Expanded(child: roadsList),
            const SizedBox(width: 12),
            Expanded(child: subRoadsList),
          ],
        ),
      );
    } else {
      // Split layout for mobile/smaller screens with TabBar/Swiper or simple back stack
      return DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: const TabBar(
            tabs: [
              Tab(text: 'Areas'),
              Tab(text: 'Roads'),
              Tab(text: 'Sub-Roads'),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(12.0),
            child: TabBarView(
              children: [
                areasList,
                roadsList,
                subRoadsList,
              ],
            ),
          ),
        ),
      );
    }
  }
}
