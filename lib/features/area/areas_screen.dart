import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class AreasScreen extends StatefulWidget {
  const AreasScreen({super.key});

  @override
  State<AreasScreen> createState() => _AreasScreenState();
}

class _AreasScreenState extends State<AreasScreen> {
  final _client = Supabase.instance.client;
  final _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _areas = [];
  List<Map<String, dynamic>> _allRoads = [];
  List<Map<String, dynamic>> _allSubRoads = [];
  List<Map<String, dynamic>> _allCustomers = [];
  
  bool _isLoading = false;
  String _searchQuery = '';

  // Hierarchical selection sets
  final Set<String> _selectedAreaIds = {};
  final Set<String> _selectedRoadIds = {};
  final Set<String> _selectedSubRoadIds = {};

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
    _fetchAllData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final List<dynamic> areasRes = await _client
          .from('areas')
          .select()
          .order('name', ascending: true);
          
      final List<dynamic> roadsRes = await _client
          .from('roads')
          .select()
          .order('name', ascending: true);
          
      final List<dynamic> subRoadsRes = await _client
          .from('sub_roads')
          .select()
          .order('name', ascending: true);
          
      final List<dynamic> customersRes = await _client
          .from('customers')
          .select('id, name, customer_code, phone, address, area_id, road_id, sub_road_id')
          .order('name');

      setState(() {
        _areas = List<Map<String, dynamic>>.from(areasRes);
        _allRoads = List<Map<String, dynamic>>.from(roadsRes);
        _allSubRoads = List<Map<String, dynamic>>.from(subRoadsRes);
        _allCustomers = List<Map<String, dynamic>>.from(customersRes);
      });
    } catch (e) {
      _showError('Failed to load route hierarchy data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // ==========================================
  // HIERARCHICAL SELECTION TOGGLES
  // ==========================================

  void _toggleAreaSelection(String areaId, bool selected) {
    setState(() {
      if (selected) {
        _selectedAreaIds.add(areaId);
        // Select all child roads
        final childRoads = _allRoads.where((r) => r['area_id'] == areaId);
        for (final r in childRoads) {
          _selectedRoadIds.add(r['id'] as String);
          final childSubRoads = _allSubRoads.where((sr) => sr['road_id'] == r['id']);
          for (final sr in childSubRoads) {
            _selectedSubRoadIds.add(sr['id'] as String);
          }
        }
      } else {
        _selectedAreaIds.remove(areaId);
        // Unselect all child roads
        final childRoads = _allRoads.where((r) => r['area_id'] == areaId);
        for (final r in childRoads) {
          _selectedRoadIds.remove(r['id'] as String);
          final childSubRoads = _allSubRoads.where((sr) => sr['road_id'] == r['id']);
          for (final sr in childSubRoads) {
            _selectedSubRoadIds.remove(sr['id'] as String);
          }
        }
      }
    });
  }

  void _toggleRoadSelection(String roadId, bool selected) {
    setState(() {
      if (selected) {
        _selectedRoadIds.add(roadId);
        // Select all child sub-roads
        final childSubRoads = _allSubRoads.where((sr) => sr['road_id'] == roadId);
        for (final sr in childSubRoads) {
          _selectedSubRoadIds.add(sr['id'] as String);
        }
      } else {
        _selectedRoadIds.remove(roadId);
        // Unselect all child sub-roads
        final childSubRoads = _allSubRoads.where((sr) => sr['road_id'] == roadId);
        for (final sr in childSubRoads) {
          _selectedSubRoadIds.remove(sr['id'] as String);
        }
      }
    });
  }

  void _toggleSubRoadSelection(String subRoadId, bool selected) {
    setState(() {
      if (selected) {
        _selectedSubRoadIds.add(subRoadId);
      } else {
        _selectedSubRoadIds.remove(subRoadId);
      }
    });
  }

  List<Map<String, dynamic>> _getSelectedCustomers() {
    return _allCustomers.where((c) {
      final areaId = c['area_id'];
      final roadId = c['road_id'];
      final subRoadId = c['sub_road_id'];
      return (subRoadId != null && _selectedSubRoadIds.contains(subRoadId)) ||
             (roadId != null && _selectedRoadIds.contains(roadId)) ||
             (areaId != null && _selectedAreaIds.contains(areaId));
    }).toList();
  }

  // ==========================================
  // SEARCH FILTER HELPER FUNCTIONS
  // ==========================================

  bool _matchesSearch(String text, String query) {
    return text.toLowerCase().contains(query.toLowerCase());
  }

  bool _isCustomerVisible(Map<String, dynamic> c, String query) {
    if (query.isEmpty) return true;
    return _matchesSearch(c['name'] ?? '', query) ||
           _matchesSearch(c['customer_code'] ?? '', query) ||
           _matchesSearch(c['phone'] ?? '', query) ||
           _matchesSearch(c['address'] ?? '', query);
  }

  bool _isSubRoadVisible(Map<String, dynamic> sr, String query) {
    if (query.isEmpty) return true;
    if (_matchesSearch(sr['name'] ?? '', query) || _matchesSearch(sr['subroad_code'] ?? '', query)) return true;
    
    // Check if any child customer matches search query
    final childCustomers = _allCustomers.where((c) => c['sub_road_id'] == sr['id']);
    return childCustomers.any((c) => _isCustomerVisible(c, query));
  }

  bool _isRoadVisible(Map<String, dynamic> r, String query) {
    if (query.isEmpty) return true;
    if (_matchesSearch(r['name'] ?? '', query) || _matchesSearch(r['road_code'] ?? '', query)) return true;
    
    // Check if any child sub-roads match search query
    final childSubRoads = _allSubRoads.where((sr) => sr['road_id'] == r['id']);
    return childSubRoads.any((sr) => _isSubRoadVisible(sr, query));
  }

  bool _isAreaVisible(Map<String, dynamic> a, String query) {
    if (query.isEmpty) return true;
    if (_matchesSearch(a['name'] ?? '', query) || _matchesSearch(a['area_code'] ?? '', query)) return true;
    
    // Check if any child roads match search query
    final childRoads = _allRoads.where((r) => r['area_id'] == a['id']);
    return childRoads.any((r) => _isRoadVisible(r, query));
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
                        final id = const Uuid().v4();
                        final areaCode = "AREA-${id.substring(0, 8).toUpperCase()}";
                        await _client.from('areas').insert({
                          'id': id,
                          'area_code': areaCode,
                          'name': nameController.text.trim(),
                          'delivery_schedule': selectedDays,
                        });
                      } else {
                        await _client.from('areas').update({
                          'name': nameController.text.trim(),
                          'delivery_schedule': selectedDays,
                        }).eq('id', area['id']);
                      }
                      _fetchAllData();
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
      _fetchAllData();
    } catch (e) {
      _showError('Failed to delete area: $e');
    }
  }

  // ==========================================
  // ROAD CRUD
  // ==========================================

  void _showRoadDialog({Map<String, dynamic>? road, required String areaId}) {
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
                        final id = const Uuid().v4();
                        final roadCode = "ROAD-${id.substring(0, 8).toUpperCase()}";
                        await _client.from('roads').insert({
                          'id': id,
                          'area_id': areaId,
                          'road_code': roadCode,
                          'name': nameController.text.trim(),
                          'delivery_schedule': schedule,
                        });
                      } else {
                        await _client.from('roads').update({
                          'name': nameController.text.trim(),
                          'delivery_schedule': schedule,
                        }).eq('id', road['id']);
                      }
                      _fetchAllData();
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
      _fetchAllData();
    } catch (e) {
      _showError('Failed to delete road: $e');
    }
  }

  // ==========================================
  // SUB-ROAD CRUD
  // ==========================================

  void _showSubRoadDialog({Map<String, dynamic>? subRoad, required String roadId}) {
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
                        final id = const Uuid().v4();
                        final subRoadCode = "SUBROAD-${id.substring(0, 8).toUpperCase()}";
                        await _client.from('sub_roads').insert({
                          'id': id,
                          'road_id': roadId,
                          'subroad_code': subRoadCode,
                          'name': nameController.text.trim(),
                          'delivery_schedule': schedule,
                        });
                      } else {
                        await _client.from('sub_roads').update({
                          'name': nameController.text.trim(),
                          'delivery_schedule': schedule,
                        }).eq('id', subRoad['id']);
                      }
                      _fetchAllData();
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
      _fetchAllData();
    } catch (e) {
      _showError('Failed to delete sub-road: $e');
    }
  }

  // ==========================================
  // VIEW LAYOUT
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredAreas = _areas.where((a) => _isAreaVisible(a, _searchQuery)).toList();
    final selectedCustomers = _getSelectedCustomers();
    
    final Map<String, int> areaBreakdown = {};
    final Map<String, int> roadBreakdown = {};
    
    for (final c in selectedCustomers) {
      final areaId = c['area_id'] as String?;
      final roadId = c['road_id'] as String?;
      if (areaId != null && _selectedAreaIds.contains(areaId)) {
        areaBreakdown[areaId] = (areaBreakdown[areaId] ?? 0) + 1;
      }
      if (roadId != null && _selectedRoadIds.contains(roadId)) {
        roadBreakdown[roadId] = (roadBreakdown[roadId] ?? 0) + 1;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Delivery Routes'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search areas, roads, sub-roads or customers...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val.trim();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _showAreaDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Area'),
                      ),
                    ],
                  ),
                ),

                if (selectedCustomers.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected: ${selectedCustomers.length} Customers',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('Breakdown:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            ...areaBreakdown.entries.map((e) {
                              final areaName = _areas.firstWhere((a) => a['id'] == e.key, orElse: () => {'name': 'Unknown'})['name'];
                              return Chip(
                                label: Text('$areaName — ${e.value}'),
                              );
                            }),
                            ...roadBreakdown.entries.map((e) {
                              final roadName = _allRoads.firstWhere((r) => r['id'] == e.key, orElse: () => {'name': 'Unknown'})['name'];
                              return Chip(
                                label: Text('$roadName — ${e.value}'),
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                Expanded(
                  child: ListView.builder(
                    itemCount: filteredAreas.length,
                    itemBuilder: (context, idx) {
                      final area = filteredAreas[idx];
                      final areaId = area['id'] as String;
                      final areaName = area['name'] as String;
                      final areaCode = area['area_code'] as String? ?? '';
                      final deliveryDays = (area['delivery_schedule'] as List?)?.join(', ') ?? 'None';

                      final areaRoads = _allRoads
                          .where((r) => r['area_id'] == areaId && _isRoadVisible(r, _searchQuery))
                          .toList();

                      final areaCustCount = _allCustomers.where((c) => c['area_id'] == areaId).length;
                      final isAreaChecked = _selectedAreaIds.contains(areaId);

                      return ExpansionTile(
                        key: PageStorageKey<String>('area:$areaId'),
                        leading: Checkbox(
                          value: isAreaChecked,
                          onChanged: (val) {
                            if (val != null) {
                              _toggleAreaSelection(areaId, val);
                            }
                          },
                        ),
                        title: Row(
                          children: [
                            Text(
                              areaName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '($areaCode)',
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            ),
                          ],
                        ),
                        subtitle: Text('Schedule: $deliveryDays • $areaCustCount Customers'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add_road_rounded, size: 20),
                              tooltip: 'Add Road',
                              onPressed: () => _showRoadDialog(areaId: areaId),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              tooltip: 'Edit Area',
                              onPressed: () => _showAreaDialog(area: area),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                              tooltip: 'Delete Area',
                              onPressed: () => _deleteArea(areaId),
                            ),
                          ],
                        ),
                        children: areaRoads.map((road) {
                          final roadId = road['id'] as String;
                          final roadName = road['name'] as String;
                          final roadCode = road['road_code'] as String? ?? '';
                          final roadSchedule = road['delivery_schedule'] == null
                              ? 'Inherited'
                              : (road['delivery_schedule'] as List).join(', ');

                          final roadSubRoads = _allSubRoads
                              .where((sr) => sr['road_id'] == roadId && _isSubRoadVisible(sr, _searchQuery))
                              .toList();

                          final roadCustCount = _allCustomers.where((c) => c['road_id'] == roadId).length;
                          final isRoadChecked = _selectedRoadIds.contains(roadId);

                          return Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: ExpansionTile(
                              key: PageStorageKey<String>('road:$roadId'),
                              leading: Checkbox(
                                value: isRoadChecked,
                                onChanged: (val) {
                                  if (val != null) {
                                    _toggleRoadSelection(roadId, val);
                                  }
                                },
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    roadName,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '($roadCode)',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                ],
                              ),
                              subtitle: Text('Schedule: $roadSchedule • $roadCustCount Customers'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.add_location_outlined, size: 20),
                                    tooltip: 'Add Sub-Road',
                                    onPressed: () => _showSubRoadDialog(roadId: roadId),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 20),
                                    tooltip: 'Edit Road',
                                    onPressed: () => _showRoadDialog(road: road, areaId: areaId),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                    tooltip: 'Delete Road',
                                    onPressed: () => _deleteRoad(roadId),
                                  ),
                                ],
                              ),
                              children: roadSubRoads.map((subRoad) {
                                final subRoadId = subRoad['id'] as String;
                                final subRoadName = subRoad['name'] as String;
                                final subRoadCode = subRoad['subroad_code'] as String? ?? '';
                                final subRoadSchedule = subRoad['delivery_schedule'] == null
                                    ? 'Inherited'
                                    : (subRoad['delivery_schedule'] as List).join(', ');

                                final subRoadCustomers = _allCustomers
                                    .where((c) => c['sub_road_id'] == subRoadId && _isCustomerVisible(c, _searchQuery))
                                    .toList();

                                final isSubRoadChecked = _selectedSubRoadIds.contains(subRoadId);

                                return Padding(
                                  padding: const EdgeInsets.only(left: 32.0),
                                  child: ExpansionTile(
                                    key: PageStorageKey<String>('subroad:$subRoadId'),
                                    leading: Checkbox(
                                      value: isSubRoadChecked,
                                      onChanged: (val) {
                                        if (val != null) {
                                          _toggleSubRoadSelection(subRoadId, val);
                                        }
                                      },
                                    ),
                                    title: Row(
                                      children: [
                                        Text(
                                          subRoadName,
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '($subRoadCode)',
                                          style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                        ),
                                      ],
                                    ),
                                    subtitle: Text('Schedule: $subRoadSchedule • ${subRoadCustomers.length} Customers'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, size: 20),
                                          tooltip: 'Edit Sub-Road',
                                          onPressed: () => _showSubRoadDialog(subRoad: subRoad, roadId: roadId),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                          tooltip: 'Delete Sub-Road',
                                          onPressed: () => _deleteSubRoad(subRoadId),
                                        ),
                                      ],
                                    ),
                                    children: subRoadCustomers.map((c) {
                                      final codeStr = c['customer_code'] ?? 'No Code';
                                      return Padding(
                                        padding: const EdgeInsets.only(left: 48.0, right: 16.0),
                                        child: ListTile(
                                          title: Text(
                                            c['name'] ?? 'Unnamed',
                                            style: const TextStyle(fontWeight: FontWeight.w500),
                                          ),
                                          subtitle: Text('Phone: ${c['phone']} • Address: ${c['address']}'),
                                          trailing: Chip(
                                            label: Text(
                                              codeStr,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                            ),
                                            backgroundColor: Colors.amber[100],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
