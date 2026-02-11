import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class BiometricService {
  final LocalAuthentication auth = LocalAuthentication();
  static const String _faceIdEnabledKey = 'face_id_enabled';
  static const String _securitySetupDoneKey = 'security_setup_done';

  // Check if biometrics are available
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (e) {
      print("Error checking biometrics: $e");
      return false;
    }
  }

  // Authenticate user
  Future<bool> authenticate({bool biometricOnly = false}) async {
    try {
      return await auth.authenticate(
        localizedReason: 'Please authenticate to access the app',
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: biometricOnly, 
        ),
      );
    } on PlatformException catch (e) {
      print("Error authenticating: $e");
      return false;
    }
  }

  // Preference Management
  Future<void> setFaceIdEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_faceIdEnabledKey, enabled);
  }

  Future<bool> isFaceIdEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_faceIdEnabledKey) ?? false;
  }

  Future<void> setSecuritySetupDone(bool done) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_securitySetupDoneKey, done);
  }

  Future<bool> isSecuritySetupDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_securitySetupDoneKey) ?? false;
  }
}
