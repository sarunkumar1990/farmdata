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
  String _dateFilter = 'All Time'; // Default to All Time
  DateTimeRange? _customDateRange;
  final List<String> _selectedBuyers = [];
  final List<String> _selectedMangos = [];
  final List<String> _selectedTypes = []; // 'Credit', 'Debit', 'Payment'

  // Options for filters (could be dynamic, but hardcoded for now as per home screen)
  final List<String> _buyerOptions = ['Ravi', 'Moorthy'];
  final List<String> _mangoOptions = ['Rumenia', 'Senthuram', 'Ottu', 'Nattu Mango'];
  final List<String> _typeOptions = ['Credit', 'Debit', 'Payment'];

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
                  padding: const EdgeInsets.all(16.0),
                  child: ListView(
                    controller: controller,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                _dateFilter = 'All Time';
                                _customDateRange = null;
                                _selectedBuyers.clear();
                                _selectedMangos.clear();
                                _selectedTypes.clear();
                              });
                            },
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                      const Divider(),
                      
                      // --- Date Filter ---
                      const Text('Date Range', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8.0,
                        children: [
                          'All Time', 'Last 30 Days', 'Last 6 Months', 'Custom Range'
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
                      if (_dateFilter == 'Custom Range' && _customDateRange != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            '${DateFormat('dd MMM yyyy').format(_customDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_customDateRange!.end)}',
                            style: const TextStyle(color: Colors.blue),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // --- Transaction Type ---
                      const Text('Transaction Type', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8.0,
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
                      const SizedBox(height: 16),

                      // --- Buyer Filter ---
                      const Text('Buyer', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8.0,
                        children: _buyerOptions.map((buyer) {
                          return FilterChip(
                            label: Text(buyer),
                            selected: _selectedBuyers.contains(buyer),
                            onSelected: (selected) {
                              setModalState(() {
                                if (selected) {
                                  _selectedBuyers.add(buyer);
                                } else {
                                  _selectedBuyers.remove(buyer);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // --- Mango Filter ---
                      const Text('Mango', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8.0,
                        children: _mangoOptions.map((mango) {
                          return FilterChip(
                            label: Text(mango),
                            selected: _selectedMangos.contains(mango),
                            onSelected: (selected) {
                              setModalState(() {
                                if (selected) {
                                  _selectedMangos.add(mango);
                                } else {
                                  _selectedMangos.remove(mango);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // --- Apply Button ---
                      ElevatedButton(
                        onPressed: () {
                          setState(() {}); // Trigger rebuild of ReportScreen with new filters
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Apply Filters'),
                      ),
                      const SizedBox(height: 20), 
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

    if (_dateFilter == 'Last 30 Days') {
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
      final buyer = entry['buyer_name'];
      if (buyer != null && !_selectedBuyers.contains(buyer)) return false;
      // If buyer is null (e.g. expense) but buyer filter is selected, usually exclude?
      // Or keep expenses? Usually if I filter by "Ravi", I only want Ravi's transactions.
      if (buyer == null && (dbType == 'credit' || dbType == 'payment')) return false; 
    }

    // 4. Mango Filter
    if (_selectedMangos.isNotEmpty) {
      final mango = entry['mango_name'];
      if (mango != null && !_selectedMangos.contains(mango)) return false;
      if (mango == null && dbType == 'credit') return false;
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
              if (_dateFilter != 'All Time' || _selectedBuyers.isNotEmpty || _selectedMangos.isNotEmpty || _selectedTypes.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.grey[200],
                  width: double.infinity,
                  child: Text(
                    'Filters Active: $_dateFilter${_selectedBuyers.isNotEmpty ? ', Buyers' : ''}${_selectedMangos.isNotEmpty ? ', Mango' : ''}',
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
                      final mangoName = entry['mango_name'] ?? 'Unknown Mango';
                      final weight = (entry['weight_kg'] as num?)?.toDouble() ?? 0.0;
                      final rate = (entry['rate_rs'] as num?)?.toDouble() ?? 0.0;
                      final amount = weight * rate;

                      return ListTile(
                        leading: const Icon(Icons.description, color: Colors.green),
                        title: Text('$mangoName ($farmName)'),
                        subtitle: Text('$formattedDate | $buyerName'),
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
                      } else if (category == 'Other Expense') {
                        subtitle += ' | ${entry['other_expense_description'] ?? ''}';
                      }

                      return ListTile(
                        leading: const Icon(Icons.money_off, color: Colors.red),
                        title: Text(category),
                        subtitle: Text(subtitle),
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
}
