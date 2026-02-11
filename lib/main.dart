import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:farm_data/services/auth_service.dart';
import 'package:farm_data/screens/login_screen.dart';
import 'package:farm_data/screens/main_screen.dart';
import 'package:farm_data/services/biometric_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Farm Data',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      builder: (context, child) => LifecycleManager(child: child ?? const SizedBox()),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          if (user == null) {
            return const LoginScreen();
          }
          return const MainScreen();
        }
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}

// Global Lifecycle Manager for App Lock
class LifecycleManager extends StatefulWidget {
  final Widget child;
  const LifecycleManager({super.key, required this.child});

  @override
  _LifecycleManagerState createState() => _LifecycleManagerState();
}

class _LifecycleManagerState extends State<LifecycleManager> with WidgetsBindingObserver {
  final BiometricService _biometricService = BiometricService();
  bool _isLocked = false; 

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkInitialLock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _checkInitialLock() {
    // If a user is currently logged in, we should start locked
    if (FirebaseAuth.instance.currentUser != null) {
      setState(() => _isLocked = true);
      _authenticate();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && FirebaseAuth.instance.currentUser != null) {
      setState(() => _isLocked = true);
      _authenticate();
    }
  }

  Future<void> _authenticate() async {
    if (FirebaseAuth.instance.currentUser == null) {
      setState(() => _isLocked = false);
      return;
    }

    bool useFaceId = await _biometricService.isFaceIdEnabled();
    
    // Slight delay to ensure UI is ready
    await Future.delayed(const Duration(milliseconds: 200));

    // If Face ID enabled, try biometric only (with fallback if OS allows)
    // Actually, biometricOnly: false is safer as it uses PIN if FaceID fails.
    // The user specifically said "if disable Face ID ask mobile pin".
    // So if useFaceId is true, we can try biometrics. If false, we just use PIN.
    
    bool authenticated = await _biometricService.authenticate(
      biometricOnly: useFaceId, 
    );

    if (authenticated) {
      setState(() => _isLocked = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isLocked && FirebaseAuth.instance.currentUser != null)
          Material(
            color: Colors.white,
            child: SizedBox.expand(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, size: 80, color: Colors.green),
                  const SizedBox(height: 20),
                  const Text('Farm Data Locked', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Text('Please authenticate to continue'),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: _authenticate,
                    icon: const Icon(Icons.lock_open),
                    label: const Text('Unlock with Face ID / PIN'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
