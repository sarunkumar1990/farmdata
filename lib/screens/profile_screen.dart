import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:farm_data/services/auth_service.dart';
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
