import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farm_data/services/firestore_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();

  // General State
  String _entryType = 'Mango'; // 'Mango' or 'Expense'
  bool _isLoading = false;

  // Mango Entry Fields
  String? _selectedFarm;
  String? _selectedBuyer;
  String? _selectedMango;
  DateTime? _selectedDate;
  final _weightController = TextEditingController();
  final _rateController = TextEditingController();

  // Expense Entry Fields
  String _expenseSubtype = 'Workers'; // 'Workers', 'Tea/Food Expense', 'Other Expense'
  
  // Worker Fields
  String? _maleCount;
  final _maleAmountController = TextEditingController();
  String? _femaleCount;
  final _femaleAmountController = TextEditingController();

  // Tea/Food Fields
  final _teaFoodAmountController = TextEditingController();

  // Other Expense Fields
  final _otherExpenseController = TextEditingController(); 
  final _otherExpenseDescriptionController = TextEditingController();

  // Pesticide Expense Fields
  List<Map<String, dynamic>> _pesticideItems = [];
  double _totalPesticideAmount = 0.0;


  // Payment Entry Fields
  String _paymentMode = 'Cash';
  final _paymentAmountController = TextEditingController();

  // Dropdown options
  final List<String> _entryTypeOptions = ['Mango', 'Payment', 'Expense'];
  final List<String> _farmOptions = ['Poovai South', 'Poovai North'];
  final List<String> _buyerOptions = ['Ravi', 'Moorthy'];
  final List<String> _mangoOptions = ['Rumenia', 'Senthuram', 'Ottu', 'Nattu Mango'];
  final List<String> _expenseSubtypeOptions = ['Workers', 'Tea/Food Expense', 'Pesticides', 'Other Expense'];
  final List<String> _paymentModeOptions = ['Cash', 'Bank'];
  final List<String> _countOptions = List.generate(10, (index) => (index + 1).toString());

  @override
  void dispose() {
    _weightController.dispose();
    _rateController.dispose();
    _paymentAmountController.dispose();
    _maleAmountController.dispose();
    _femaleAmountController.dispose();
    _teaFoodAmountController.dispose();
    _otherExpenseController.dispose();
    _otherExpenseDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showPesticideEntryDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: PesticideEntryScreen(
          initialItems: _pesticideItems,
          onSave: (items) {
            setState(() {
              _pesticideItems = items;
              _totalPesticideAmount = items.fold(0.0, (sum, item) => sum + (item['amount'] as double));
            });
          },
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    print('Submit button pressed'); 
    if (_formKey.currentState!.validate()) {
      
      // Validation for Mango Date or Payment Date
      if ((_entryType == 'Mango' || _entryType == 'Payment') && _selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a date')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        Map<String, dynamic> data = {
          'entry_type': _entryType,
          // 'timestamp': FieldValue.serverTimestamp(),
        };

        if (_entryType == 'Mango') {
          data['transaction_type'] = 'credit';
          data['farm_name'] = _selectedFarm;
          data['buyer_name'] = _selectedBuyer;
          data['mango_name'] = _selectedMango;
          data['date'] = Timestamp.fromDate(_selectedDate!);
          data['weight_kg'] = double.parse(_weightController.text);
          data['rate_rs'] = double.parse(_rateController.text);
          // Calculate total for convenience?
          data['total_amount'] = double.parse(_weightController.text) * double.parse(_rateController.text);

        } else if (_entryType == 'Payment') {
          data['transaction_type'] = 'payment';
          data['buyer_name'] = _selectedBuyer;
          data['payment_mode'] = _paymentMode;
          data['date'] = Timestamp.fromDate(_selectedDate!);
          data['total_amount'] = double.parse(_paymentAmountController.text);

        } else {
          // Expense
          data['transaction_type'] = 'debit';
          data['expense_category'] = _expenseSubtype;
          
          // Use current date for expenses as date picker is hidden
          data['date'] = Timestamp.now(); 

          if (_expenseSubtype == 'Workers') {
            data['worker_male_count'] = _maleCount != null ? int.parse(_maleCount!) : 0;
            data['worker_male_amount'] = double.parse(_maleAmountController.text);
            data['worker_female_count'] = _femaleCount != null ? int.parse(_femaleCount!) : 0;
            data['worker_female_amount'] = double.parse(_femaleAmountController.text);
            data['total_amount'] = double.parse(_maleAmountController.text) + double.parse(_femaleAmountController.text);
            
          } else if (_expenseSubtype == 'Tea/Food Expense') {
            data['tea_food_amount'] = double.parse(_teaFoodAmountController.text);
            data['total_amount'] = double.parse(_teaFoodAmountController.text);

          } else if (_expenseSubtype == 'Other Expense') {
            data['other_expense_description'] = _otherExpenseDescriptionController.text;
            data['other_expense_amount'] = double.parse(_otherExpenseController.text);
            data['total_amount'] = double.parse(_otherExpenseController.text);
          } else if (_expenseSubtype == 'Pesticides') {
            data['pesticide_items'] = _pesticideItems;
            data['total_amount'] = _totalPesticideAmount;
            // Optionally save a summary name or just rely on items
            data['pesticide_name'] = _pesticideItems.map((e) => '${e['name']} (${e['quantity']} ${e['unit']})').join(', ');
          }
        }

        print('Data to save: $data');
        
        // Remove serverTimestamp to avoid potential JS interop issues
        // 'timestamp': FieldValue.serverTimestamp(), 
        
        // Add timeout to help debug hanging issues
        await _firestoreService.addEntry(data).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw 'Connection slow. Data saved in background.';
          },
        );
        print('Data saved.');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          _formKey.currentState!.reset();
          setState(() {
            // Reset fields
            _selectedFarm = null;
            _selectedBuyer = null;
            _selectedMango = null;
            _selectedDate = null;
            _weightController.clear();
            _rateController.clear();
            _paymentAmountController.clear();
            
            // Keep entry type or reset? Usually keep for rapid entry.
            // Resetting expense specific fields
             _maleCount = null;
             _maleAmountController.clear();
             _femaleCount = null;
             _femaleAmountController.clear();
             _teaFoodAmountController.clear();
             _otherExpenseController.clear();
             _otherExpenseDescriptionController.clear();
             // _pesticideNameController.clear();
             // _pesticideAmountController.clear();
             _pesticideItems.clear();
             _totalPesticideAmount = 0.0;
          });
        }
      } catch (e, stackTrace) {
        print('Error: $e');
        print(stackTrace);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving data: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Entry')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Entry Type Dropdown
              DropdownButtonFormField<String>(
                value: _entryType,
                decoration: const InputDecoration(labelText: 'Entry Type'),
                items: _entryTypeOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() {
                      _entryType = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              if (_entryType == 'Mango') ...[
                // --- Mango Form Fields ---
                DropdownButtonFormField<String>(
                  value: _selectedFarm,
                  decoration: const InputDecoration(labelText: 'Farm Name'),
                  items: _farmOptions.map((String value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                  onChanged: (val) => setState(() => _selectedFarm = val),
                  validator: (val) => val == null ? 'Select farm' : null,
                ),
                const SizedBox(height: 16),
                
                DropdownButtonFormField<String>(
                  value: _selectedBuyer,
                  decoration: const InputDecoration(labelText: 'Buyer'),
                  items: _buyerOptions.map((String value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                  onChanged: (val) => setState(() => _selectedBuyer = val),
                  validator: (val) => val == null ? 'Select buyer' : null,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _selectedMango,
                  decoration: const InputDecoration(labelText: 'Mango Name'),
                  items: _mangoOptions.map((String value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                  onChanged: (val) => setState(() => _selectedMango = val),
                  validator: (val) => val == null ? 'Select mango' : null,
                ),
                const SizedBox(height: 16),

                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _selectedDate != null
                          ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                          : 'Select Date',
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _weightController,
                  decoration: const InputDecoration(labelText: 'Weight', suffixText: 'kg'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (val) => (val == null || val.isEmpty) ? 'Enter weight' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _rateController,
                  decoration: const InputDecoration(labelText: 'Rate', prefixText: 'Rs. '),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (val) => (val == null || val.isEmpty) ? 'Enter rate' : null,
                ),

              ] else if (_entryType == 'Payment') ...[
                // --- Payment Form Fields ---
                DropdownButtonFormField<String>(
                  value: _selectedBuyer, // Re-using Buyer dropdown
                  decoration: const InputDecoration(labelText: 'Buyer'),
                  items: _buyerOptions.map((String value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                  onChanged: (val) => setState(() => _selectedBuyer = val),
                  validator: (val) => val == null ? 'Select buyer' : null,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _paymentMode,
                  decoration: const InputDecoration(labelText: 'Payment Mode'),
                  items: _paymentModeOptions.map((String value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _paymentMode = val);
                  },
                  validator: (val) => val == null ? 'Select mode' : null,
                ),
                const SizedBox(height: 16),

                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _selectedDate != null
                          ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                          : 'Select Date',
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _paymentAmountController,
                  decoration: const InputDecoration(labelText: 'Amount', prefixText: 'Rs. '),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (val) => (val == null || val.isEmpty) ? 'Enter amount' : null,
                ),

              ] else ...[
                // --- Expense Form Fields ---
                DropdownButtonFormField<String>(
                  value: _expenseSubtype,
                  decoration: const InputDecoration(labelText: 'Expense Category'),
                  items: _expenseSubtypeOptions.map((String value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _expenseSubtype = val);
                  },
                ),
                const SizedBox(height: 16),

                if (_expenseSubtype == 'Workers') ...[
                  // Male Workers
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          value: _maleCount,
                          decoration: const InputDecoration(labelText: 'Male Count'),
                          items: _countOptions.map((String value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                          onChanged: (val) => setState(() => _maleCount = val),
                          validator: (val) => val == null ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _maleAmountController,
                          decoration: const InputDecoration(labelText: 'Amount (Male)'),
                          keyboardType: TextInputType.number,
                          validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Female Workers
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          value: _femaleCount,
                          decoration: const InputDecoration(labelText: 'Female Count'),
                          items: _countOptions.map((String value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                          onChanged: (val) => setState(() => _femaleCount = val),
                          validator: (val) => val == null ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _femaleAmountController,
                          decoration: const InputDecoration(labelText: 'Amount (Female)'),
                          keyboardType: TextInputType.number,
                          validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                ] else if (_expenseSubtype == 'Tea/Food Expense') ...[
                  TextFormField(
                    controller: _teaFoodAmountController,
                    decoration: const InputDecoration(labelText: 'Expense Amount'),
                    keyboardType: TextInputType.number,
                    validator: (val) => (val == null || val.isEmpty) ? 'Enter amount' : null,
                  ),
                ] else if (_expenseSubtype == 'Other Expense') ...[
                  TextFormField(
                    controller: _otherExpenseDescriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    validator: (val) => (val == null || val.isEmpty) ? 'Enter description' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _otherExpenseController,
                    decoration: const InputDecoration(labelText: 'Expense Amount'),
                    keyboardType: TextInputType.number,
                    validator: (val) => (val == null || val.isEmpty) ? 'Enter amount' : null,
                  ),
                ] else if (_expenseSubtype == 'Pesticides') ...[
                  OutlinedButton.icon(
                    onPressed: _showPesticideEntryDialog,
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Add Pesticides Details'),
                  ),
                  const SizedBox(height: 10),
                  if (_pesticideItems.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Added Items (${_pesticideItems.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Total Amount: ₹$_totalPesticideAmount', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                ],
              ],

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isLoading ? const CircularProgressIndicator() : const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PesticideEntryScreen extends StatefulWidget {
  final List<Map<String, dynamic>> initialItems;
  final Function(List<Map<String, dynamic>>) onSave;

  const PesticideEntryScreen({
    super.key,
    required this.initialItems,
    required this.onSave,
  });

  @override
  State<PesticideEntryScreen> createState() => _PesticideEntryScreenState();
}

class _PesticideEntryScreenState extends State<PesticideEntryScreen> {
  late List<Map<String, dynamic>> _items;
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController();
  final _rateController = TextEditingController();
  String _selectedUnit = 'Ltr'; // Default unit

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.initialItems);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Pesticides Details'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Single Input Row
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _qtyController,
                    decoration: const InputDecoration(labelText: 'Qty'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    decoration: const InputDecoration(labelText: 'Unit'),
                    isExpanded: true,
                    items: ['Ltr', 'Kg'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12)))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedUnit = val);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _rateController,
                    decoration: const InputDecoration(labelText: 'Rate'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add),
                label: const Text('Add Item'),
              ),
            ),
            const Divider(),
            
            // List of Items
            Expanded(
              child: _items.isEmpty
                  ? const Center(child: Text('No items added'))
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return ListTile(
                          title: Text(item['name']),
                          subtitle: Text('Qty: ${item['quantity']} ${item['unit']} | Rate: ₹${item['rate']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('₹${item['amount']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.remove_circle, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _items.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            
            const Divider(),
            // Summary and Submit
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ₹${_items.fold(0.0, (sum, item) => sum + (item['amount'] as double))}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                ElevatedButton(
                  onPressed: () {
                    widget.onSave(_items);
                    Navigator.pop(context);
                  },
                  child: const Text('Save & Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addItem() {
    if (_nameController.text.isNotEmpty && 
        _qtyController.text.isNotEmpty && 
        _rateController.text.isNotEmpty) {
      setState(() {
        double qty = double.tryParse(_qtyController.text) ?? 0;
        double rate = double.tryParse(_rateController.text) ?? 0;
        _items.add({
          'name': _nameController.text,
          'quantity': qty,
          'unit': _selectedUnit,
          'rate': rate,
          'amount': qty * rate,
        });
        _nameController.clear();
        _qtyController.clear();
        _rateController.clear();
      });
    }
  }
}
