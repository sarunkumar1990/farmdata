import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:farm_data/services/firestore_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  // Filter State
  String _dateFilter = 'Current Year'; // Default to Current Year
  DateTimeRange? _customDateRange;
  final List<String> _selectedBuyers = [];
  final List<String> _selectedMangos = [];
  final List<String> _selectedFarms = [];
  final List<String> _selectedWorkerSubCategories = [];
  final List<String> _selectedShops = [];
  final List<String> _selectedTypes = []; // 'Credit', 'Debit', 'Payment'

  // Dynamic Options for filters
  List<Map<String, dynamic>> _farmOptions = [];
  List<Map<String, dynamic>> _buyerOptions = [];
  List<Map<String, dynamic>> _mangoOptions = [];
  List<Map<String, dynamic>> _workerSubCategoryOptions = [];
  List<Map<String, dynamic>> _shopOptions = [];
  final List<String> _typeOptions = ['Credit', 'Debit', 'Payment'];

  @override
  void initState() {
    super.initState();
    _fetchFilterOptions();
  }

  void _fetchFilterOptions() {
    _firestoreService.getFarms().listen((farms) {
      if (mounted) setState(() => _farmOptions = farms);
    });
    _firestoreService.getBuyers().listen((buyers) {
      if (mounted) setState(() => _buyerOptions = buyers);
    });
    _firestoreService.getVarieties().listen((mangos) {
      if (mounted) setState(() => _mangoOptions = mangos);
    });
    _firestoreService.getWorkerSubCategories().listen((subs) {
      if (mounted) setState(() => _workerSubCategoryOptions = subs);
    });
    _firestoreService.getPesticideShops().listen((shops) {
      if (mounted) setState(() => _shopOptions = shops);
    });
  }

  void _resetFilters() {
    _dateFilter = 'Current Year';
    _customDateRange = null;
    _selectedBuyers.clear();
    _selectedMangos.clear();
    _selectedFarms.clear();
    _selectedWorkerSubCategories.clear();
    _selectedShops.clear();
    _selectedTypes.clear();
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, controller) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      // --- Fixed Header ---
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            TextButton(
                              onPressed: () {
                                setModalState(() {
                                  _resetFilters();
                                });
                              },
                              child: const Text('Reset'),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),

                      // --- Scrollable Content ---
                      Expanded(
                        child: ListView(
                          controller: controller,
                          padding: const EdgeInsets.all(16.0),
                          children: [
                            // --- Date Filter ---
                            const Text('Date Range', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Wrap(
                                spacing: 8.0,
                                runSpacing: 8.0,
                                children: [
                                  'Current Year', 'All Time', 'Last 30 Days', 'Last 6 Months', 'Custom Range'
                                ].map((filter) {
                                  return ChoiceChip(
                                    label: Text(filter),
                                    selected: _dateFilter == filter,
                                    onSelected: (selected) {
                                      if (selected) {
                                        setModalState(() {
                                          _dateFilter = filter;
                                          if (filter != 'Custom Range') {
                                            _customDateRange = null;
                                          }
                                        });
                                        if (filter == 'Custom Range') {
                                          _pickDateRange(context, setModalState);
                                        }
                                      }
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                            if (_dateFilter == 'Custom Range' && _customDateRange != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Text(
                                  '${DateFormat('dd MMM yyyy').format(_customDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_customDateRange!.end)}',
                                  style: const TextStyle(color: Colors.blue),
                                ),
                              ),

                            // --- Transaction Type ---
                            const Text('Transaction Type', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Wrap(
                                spacing: 8.0,
                                runSpacing: 8.0,
                                children: _typeOptions.map((type) {
                                  return FilterChip(
                                    label: Text(type),
                                    selected: _selectedTypes.contains(type),
                                    onSelected: (selected) {
                                      setModalState(() {
                                        if (selected) {
                                          _selectedTypes.add(type);
                                        } else {
                                          _selectedTypes.remove(type);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ),

                            // --- Buyer Filter ---
                            const Text('Buyer', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Wrap(
                                spacing: 8.0,
                                runSpacing: 8.0,
                                children: _buyerOptions.map((buyer) {
                                  final id = buyer['id'];
                                  return FilterChip(
                                    label: Text(buyer['name']),
                                    selected: _selectedBuyers.contains(id),
                                    onSelected: (selected) {
                                      setModalState(() {
                                        if (selected) {
                                          _selectedBuyers.add(id);
                                        } else {
                                          _selectedBuyers.remove(id);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ),

                            // --- Farm Filter ---
                            const Text('Farm', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Wrap(
                                spacing: 8.0,
                                runSpacing: 8.0,
                                children: _farmOptions.map((farm) {
                                  final id = farm['id'];
                                  return FilterChip(
                                    label: Text(farm['name']),
                                    selected: _selectedFarms.contains(id),
                                    onSelected: (selected) {
                                      setModalState(() {
                                        if (selected) {
                                          _selectedFarms.add(id);
                                        } else {
                                          _selectedFarms.remove(id);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ),

                            // --- Mango Filter ---
                            const Text('Variety', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Wrap(
                                spacing: 8.0,
                                runSpacing: 8.0,
                                children: _mangoOptions.map((mango) {
                                  final id = mango['id'];
                                  return FilterChip(
                                    label: Text(mango['name']),
                                    selected: _selectedMangos.contains(id),
                                    onSelected: (selected) {
                                      setModalState(() {
                                        if (selected) {
                                          _selectedMangos.add(id);
                                        } else {
                                          _selectedMangos.remove(id);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ),

                            // --- Worker Sub-Category Filter ---
                            const Text('Worker Sub-Category', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Wrap(
                                spacing: 8.0,
                                runSpacing: 8.0,
                                children: _workerSubCategoryOptions.map((sub) {
                                  final id = sub['id'];
                                  return FilterChip(
                                    label: Text(sub['name']),
                                    selected: _selectedWorkerSubCategories.contains(id),
                                    onSelected: (selected) {
                                      setModalState(() {
                                        if (selected) {
                                          _selectedWorkerSubCategories.add(id);
                                        } else {
                                          _selectedWorkerSubCategories.remove(id);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ),

                            // --- Pesticide Shop Filter ---
                            const Text('Pesticide Shop', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Wrap(
                                spacing: 8.0,
                                runSpacing: 8.0,
                                children: _shopOptions.map((shop) {
                                  final id = shop['id'];
                                  return FilterChip(
                                    label: Text(shop['name']),
                                    selected: _selectedShops.contains(id),
                                    onSelected: (selected) {
                                      setModalState(() {
                                        if (selected) {
                                          _selectedShops.add(id);
                                        } else {
                                          _selectedShops.remove(id);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // --- Fixed Footer ---
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {}); // Trigger rebuild of ReportScreen
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Apply Filters'),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _pickDateRange(BuildContext context, StateSetter setModalState) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customDateRange,
    );
    if (picked != null) {
      setModalState(() {
        _customDateRange = picked;
      });
    }
  }

  bool _shouldInclude(Map<String, dynamic> entry) {
    // 1. Date Filter
    final Timestamp? ts = entry['date'];
    if (ts == null) return false;
    final DateTime date = ts.toDate();

    if (_dateFilter == 'Current Year') {
      final now = DateTime.now();
      final startOfYear = DateTime(now.year, 1, 1);
      final endOfYear = DateTime(now.year, 12, 31, 23, 59, 59);
      if (date.isBefore(startOfYear) || date.isAfter(endOfYear)) return false;
    } else if (_dateFilter == 'Last 30 Days') {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      if (date.isBefore(thirtyDaysAgo)) return false;
    } else if (_dateFilter == 'Last 6 Months') {
      final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
      if (date.isBefore(sixMonthsAgo)) return false;
    } else if (_dateFilter == 'Custom Range' && _customDateRange != null) {
      // Create a range that includes the entire end day
      final end = _customDateRange!.end.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
      if (date.isBefore(_customDateRange!.start) || date.isAfter(end)) return false;
    }

    // 2. Type Filter
    // Map db types to filter types: credit->Credit, debit->Debit, payment->Payment
    final dbType = entry['transaction_type'] ?? 'credit';
    String filterType;
    if (dbType == 'credit') filterType = 'Credit';
    else if (dbType == 'debit') filterType = 'Debit';
    else filterType = 'Payment';

    if (_selectedTypes.isNotEmpty && !_selectedTypes.contains(filterType)) {
      return false;
    }

    // 3. Buyer Filter
    if (_selectedBuyers.isNotEmpty) {
      final buyerId = entry['buyer_id'];
      if (buyerId == null || !_selectedBuyers.contains(buyerId)) {
        return false;
      }
    }

    // 4. Mango Filter
    if (_selectedMangos.isNotEmpty) {
      final mangoId = entry['mango_id'];
      if (mangoId == null || !_selectedMangos.contains(mangoId)) {
        return false;
      }
    }

    // 5. Farm Filter
    if (_selectedFarms.isNotEmpty) {
      final farmId = entry['farm_id'];
      if (farmId == null || !_selectedFarms.contains(farmId)) {
        return false;
      }
    }

    // 6. Worker Sub-Category Filter
    if (_selectedWorkerSubCategories.isNotEmpty) {
      final subId = entry['worker_sub_category_id'];
      if (subId == null || !_selectedWorkerSubCategories.contains(subId)) {
        return false;
      }
    }

    // 7. Pesticide Shop Filter
    if (_selectedShops.isNotEmpty) {
      final shopId = entry['shop_id'];
      if (shopId == null || !_selectedShops.contains(shopId)) {
        return false;
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterModal,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getEntries(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Fetch ALL data, then filter client-side
          final allData = snapshot.data!.docs;

          // Apply Filtering
          final filteredDocs = allData.where((doc) {
            return _shouldInclude(doc.data() as Map<String, dynamic>);
          }).toList();

          if (filteredDocs.isEmpty) {
            return const Center(child: Text('No entries found matching filters.'));
          }

          double totalWeight = 0;
          double totalIncome = 0;
          double totalExpense = 0;
          double totalPaymentReceived = 0;

          // Calculate totals from Filtered Data
          for (var doc in filteredDocs) {
            final entry = doc.data() as Map<String, dynamic>;
            final type = entry['transaction_type'] ?? 'credit'; 
            
            if (type == 'credit') {
              final weight = (entry['weight_kg'] as num?)?.toDouble() ?? 0.0;
              final amount = (entry['total_amount'] as num?)?.toDouble() ?? 
                             ((entry['rate_rs'] as num?)?.toDouble() ?? 0.0) * weight;
              totalWeight += weight;
              totalIncome += amount;
            } else if (type == 'payment') {
              final amount = (entry['total_amount'] as num?)?.toDouble() ?? 0.0;
              totalPaymentReceived += amount;
            } else {
              // Debit (Expense)
              final amount = (entry['total_amount'] as num?)?.toDouble() ?? 0.0;
              totalExpense += amount;
            }
          }
          
          final netBalance = totalIncome - totalExpense; 

          return Column(
            children: [
              // Active Filter Chips (Optional, but clear visual cue)
              if (_dateFilter != 'All Time' || _selectedBuyers.isNotEmpty || _selectedMangos.isNotEmpty || _selectedTypes.isNotEmpty || _selectedFarms.isNotEmpty || _selectedWorkerSubCategories.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.grey[200],
                  width: double.infinity,
                  child: Text(
                    'Filters Active: $_dateFilter${_selectedFarms.isNotEmpty ? ', Farms' : ''}${_selectedBuyers.isNotEmpty ? ', Buyers' : ''}${_selectedMangos.isNotEmpty ? ', Varieties' : ''}${_selectedWorkerSubCategories.isNotEmpty ? ', Worker Subs' : ''}${_selectedShops.isNotEmpty ? ', Shops' : ''}',
                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ),

              // List of Entries
              Expanded(
                child: ListView.separated(
                  itemCount: filteredDocs.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final entry = doc.data() as Map<String, dynamic>;
                    final type = entry['transaction_type'] ?? 'credit';
                    
                    final dateTimestamp = entry['date'] as Timestamp?;
                    final date = dateTimestamp?.toDate() ?? DateTime.now();
                    final formattedDate = DateFormat('dd MMM yyyy').format(date);
                    
                    if (type == 'credit') {
                      final farmName = entry['farm_name'] ?? 'Unknown Farm';
                      final buyerName = entry['buyer_name'] ?? 'Unknown Buyer';
                      final varietyName = entry['mango_name'] ?? 'Unknown Variety';
                      final entryType = entry['entry_type'] ?? 'Mango';
                      final weight = (entry['weight_kg'] as num?)?.toDouble() ?? 0.0;
                      final rate = (entry['rate_rs'] as num?)?.toDouble() ?? 0.0;
                      final amount = weight * rate;

                      return ListTile(
                        leading: Icon(entryType == 'Coconut' ? Icons.eco : Icons.description, color: Colors.green),
                        title: Text('$varietyName ($farmName)'),
                        subtitle: Text('$formattedDate | $buyerName'),
                        onTap: () => _showEntryDetails(entry),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${weight.toStringAsFixed(2)} kg x ₹$rate'),
                            Text(
                              '+ ₹${amount.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green),
                            ),
                          ],
                        ),
                      );
                    } else if (type == 'payment') {
                       final buyerName = entry['buyer_name'] ?? 'Unknown Buyer';
                       final mode = entry['payment_mode'] ?? 'Cash';
                       final amount = (entry['total_amount'] as num?)?.toDouble() ?? 0.0;

                       return ListTile(
                        leading: const Icon(Icons.payment, color: Colors.blue),
                        title: Text('Payment from $buyerName'),
                        subtitle: Text('$formattedDate | Mode: $mode'),
                        onTap: () => _showEntryDetails(entry),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${amount.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue),
                            ),
                          ],
                        ),
                      );
                    } else {
                      final category = entry['expense_category'] ?? 'Expense';
                      final amount = (entry['total_amount'] as num?)?.toDouble() ?? 0.0;
                      
                      String subtitle = formattedDate;
                      if (category == 'Workers') {
                         final m = entry['worker_male_count'] ?? 0;
                         final f = entry['worker_female_count'] ?? 0;
                         subtitle += ' | Users: M:$m F:$f';
                      } else if (category == 'Pesticides') {
                        subtitle += ' | ${entry['pesticide_name'] ?? ''}';
                      } else if (category == 'Other Expense') {
                        subtitle += ' | ${entry['other_expense_description'] ?? ''}';
                      }

                      return ListTile(
                        leading: const Icon(Icons.money_off, color: Colors.red),
                        title: Text(category),
                        subtitle: Text(subtitle),
                        onTap: () => _showEntryDetails(entry),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '- ₹${amount.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ),
              
              // Totals Section
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), offset: const Offset(0, -2), blurRadius: 4),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         Text('Total Weight: ${totalWeight.toStringAsFixed(2)} kg'),
                         Text('Income: ₹${totalIncome.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         Text('Received: ₹${totalPaymentReceived.toStringAsFixed(2)}', style: const TextStyle(color: Colors.blue)),
                         Text('Expense: ₹${totalExpense.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Net Balance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(
                          '₹${netBalance.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: netBalance >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  void _showEntryDetails(Map<String, dynamic> entry) {
    final type = entry['transaction_type'] ?? 'credit';
    final dateTimestamp = entry['date'] as Timestamp?;
    final date = dateTimestamp?.toDate() ?? DateTime.now();
    final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(date);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    type.toUpperCase(),
                    style: TextStyle(
                      color: type == 'credit' ? Colors.green : (type == 'payment' ? Colors.blue : Colors.red),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(formattedDate, style: const TextStyle(color: Colors.grey)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              if (type == 'credit') ...[
                _detailItem('Entry Type', entry['entry_type'] ?? 'Mango'),
                _detailItem('Farm', entry['farm_name']),
                _detailItem('Buyer', entry['buyer_name']),
                _detailItem('Variety', entry['mango_name']),
                _detailItem('Weight', '${entry['weight_kg']} kg'),
                _detailItem('Rate', '₹${entry['rate_rs']}'),
                const Divider(),
                _detailItem('Total Amount', '₹${((entry['weight_kg'] ?? 0.0) * (entry['rate_rs'] ?? 0.0)).toStringAsFixed(2)}', isBold: true),
              ] else if (type == 'payment') ...[
                _detailItem('Buyer', entry['buyer_name']),
                _detailItem('Payment Mode', entry['payment_mode']),
                const Divider(),
                _detailItem('Amount Received', '₹${entry['total_amount']}', isBold: true),
              ] else ...[
                _detailItem('Category', entry['expense_category']),
                _detailItem('Farm', entry['farm_name']),
                if (entry['expense_category'] == 'Workers') ...[
                  _detailItem('Sub Category', entry['worker_sub_category_name']),
                  _detailItem('Male Workers', '${entry['worker_male_count'] ?? 0} (₹${entry['worker_male_amount'] ?? 0})'),
                  _detailItem('Female Workers', '${entry['worker_female_count'] ?? 0} (₹${entry['worker_female_amount'] ?? 0})'),
                ] else if (entry['expense_category'] == 'Tea/Food Expense') ...[
                   _detailItem('Amount', '₹${entry['tea_food_amount']}'),
                ] else if (entry['expense_category'] == 'Other Expense') ...[
                   _detailItem('Description', entry['other_expense_description']),
                   _detailItem('Amount', '₹${entry['other_expense_amount']}'),
                ] else if (entry['expense_category'] == 'Pesticides') ...[
                   _detailItem('Shop', entry['shop_name']),
                   const SizedBox(height: 8),
                   const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                   const SizedBox(height: 4),
                   ...(entry['pesticide_items'] as List? ?? []).map((item) => Padding(
                     padding: const EdgeInsets.only(left: 16.0, top: 4),
                     child: Text('• ${item['name']}: ${item['quantity']} ${item['unit']} @ ₹${item['rate']} = ₹${item['amount']}'),
                   )),
                ],
                const Divider(),
                _detailItem('Total Expense', '₹${entry['total_amount']}', isBold: true),
              ],
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _detailItem(String label, dynamic value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value?.toString() ?? 'N/A',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
