import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:farm_data/services/auth_service.dart';
import 'package:farm_data/services/firestore_service.dart';
import '../services/biometric_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final BiometricService _biometricService = BiometricService();
  bool _isFaceIdEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricPreference();
  }

  Future<void> _loadBiometricPreference() async {
    bool enabled = await _biometricService.isFaceIdEnabled();
    setState(() {
      _isFaceIdEnabled = enabled;
    });
  }

  Future<void> _toggleFaceId(bool value) async {
    if (value) {
      // If turning ON, verify identity first
      bool authenticated = await _biometricService.authenticate();
      if (authenticated) {
        await _biometricService.setFaceIdEnabled(true);
        setState(() => _isFaceIdEnabled = true);
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Face ID Enabled')));
        }
      } else {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Authentication failed. Face ID not enabled.')));
        }
      }
    } else {
      // Turning OFF is easy
      await _biometricService.setFaceIdEnabled(false);
      setState(() => _isFaceIdEnabled = false);
    }
  }

  void _logout() async {
    await AuthService().signOut();
    // Navigation is handled by AuthWrapper in main.dart
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // User Info
            const Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.green,
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user?.displayName ?? 'Farm User', // Fallback name
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              user?.email ?? 'No Email',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            const Divider(),

            // Settings
            ListTile(
              title: const Text('Security', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            SwitchListTile(
              title: const Text('Enable Face ID / App Lock'),
              subtitle: const Text('Require authentication to open app'),
              value: _isFaceIdEnabled,
              onChanged: _toggleFaceId,
              secondary: const Icon(Icons.face),
            ),

            const Divider(),
            
            // Manage Data
            ListTile(
              title: const Text('Data Management', style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.dataset),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => const Dialog.fullscreen(
                    child: MetadataManager(),
                  ),
                );
              },
            ),

            const Divider(),
            const SizedBox(height: 32),

            // Logout
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MetadataManager extends StatefulWidget {
  const MetadataManager({super.key});

  @override
  State<MetadataManager> createState() => _MetadataManagerState();
}

class _MetadataManagerState extends State<MetadataManager> {
  final FirestoreService _firestoreService = FirestoreService();
  String _selectedCategory = 'Farms';
  final _textController = TextEditingController();
  final List<String> _categories = ['Farms', 'Buyers', 'Varieties', 'Pesticide Shops', 'Worker Sub-Categories'];
  String _selectedVarietyType = 'Mango'; // 'Mango' or 'Coconut'

  Stream<List<Map<String, dynamic>>> _getStream() {
    switch (_selectedCategory) {
      case 'Farms': return _firestoreService.getFarms();
      case 'Buyers': return _firestoreService.getBuyers();
      case 'Varieties': return _firestoreService.getVarieties();
      case 'Pesticide Shops': return _firestoreService.getPesticideShops();
      case 'Worker Sub-Categories': return _firestoreService.getWorkerSubCategories();
      default: return const Stream.empty();
    }
  }

  Future<void> _addItem(String name) async {
    switch (_selectedCategory) {
      case 'Farms': await _firestoreService.addFarm(name); break;
      case 'Buyers': await _firestoreService.addBuyer(name); break;
      case 'Varieties': await _firestoreService.addVariety(name, _selectedVarietyType); break;
      case 'Pesticide Shops': await _firestoreService.addPesticideShop(name); break;
      case 'Worker Sub-Categories': await _firestoreService.addWorkerSubCategory(name); break;
    }
  }

  Future<void> _deleteItem(Map<String, dynamic> item) async {
    final name = item['name'] as String;
    switch (_selectedCategory) {
      case 'Farms': await _firestoreService.deleteFarm(name); break;
      case 'Buyers': await _firestoreService.deleteBuyer(name); break;
      case 'Varieties': await _firestoreService.deleteVariety(name, item['type'] as String); break;
      case 'Pesticide Shops': await _firestoreService.deletePesticideShop(name); break;
      case 'Worker Sub-Categories': await _firestoreService.deleteWorkerSubCategory(name); break;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Data'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Category Selector
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Select Category'),
              items: _categories.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategory = val);
              },
            ),
            const SizedBox(height: 16),

            if (_selectedCategory == 'Varieties') ...[
              DropdownButtonFormField<String>(
                value: _selectedVarietyType,
                decoration: const InputDecoration(labelText: 'Variety Type'),
                items: ['Mango', 'Coconut'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedVarietyType = val);
                },
              ),
              const SizedBox(height: 16),
            ],

            // Input Row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      labelText: 'Add New $_selectedCategory',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_textController.text.isNotEmpty) {
                      _addItem(_textController.text);
                      _textController.clear();
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),

            // List of Items
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _getStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Text('Error: ${snapshot.error}');
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final items = snapshot.data ?? [];
                  if (items.isEmpty) return const Center(child: Text('No items found'));

                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        title: Text(item['name'] as String),
                        subtitle: _selectedCategory == 'Varieties' ? Text('Type: ${item['type']}') : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showEditDialog(item),
                        ),
                      );

                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _showEditDialog(Map<String, dynamic> item) {
    final editController = TextEditingController(text: item['name'] as String);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit $_selectedCategory'),
          content: TextField(
            controller: editController,
            decoration: const InputDecoration(labelText: 'New Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (editController.text.isNotEmpty) {
                  await _firestoreService.updateMetadata(
                    _selectedCategory,
                    item['id'] as String,
                    editController.text,
                  );
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }
}
