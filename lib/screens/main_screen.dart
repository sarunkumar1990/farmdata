import 'package:flutter/material.dart';
import 'package:farm_data/screens/home_screen.dart';
import 'package:farm_data/screens/report_screen.dart';
import 'package:farm_data/screens/profile_screen.dart';
import 'package:farm_data/services/biometric_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  
  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    ReportScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkSecuritySetup();
  }

  Future<void> _checkSecuritySetup() async {
    final biometricService = BiometricService();
    bool setupDone = await biometricService.isSecuritySetupDone();
    
    if (!setupDone) {
      // Small delay to let UI settle
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;

      bool available = await biometricService.isBiometricAvailable();
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Securing Your App'),
          content: Text(available 
            ? 'Would you like to enable Face ID / Biometrics for quick access?' 
            : 'Would you like to enable App Lock with your mobile PIN?'),
          actions: [
            TextButton(
              onPressed: () async {
                await biometricService.setSecuritySetupDone(true);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Maybe Later'),
            ),
            ElevatedButton(
              onPressed: () async {
                bool authenticated = await biometricService.authenticate();
                if (authenticated) {
                  await biometricService.setFaceIdEnabled(available); 
                  await biometricService.setSecuritySetupDone(true);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Security Enabled!'))
                    );
                  }
                }
              },
              child: const Text('Enable Now'),
            ),
          ],
        ),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farm Data'),
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Report',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}
