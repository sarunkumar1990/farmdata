import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class BiometricService {
  final LocalAuthentication auth = LocalAuthentication();
  static const String _faceIdEnabledKey = 'face_id_enabled';
  static const String _securitySetupDoneKey = 'security_setup_done';

  // Check if biometrics are available
  Future<bool> isBiometricAvailable() async {
    return false; // Stubbed for now
  }

  // Authenticate user
  Future<bool> authenticate({bool biometricOnly = false}) async {
    return true; // Stubbed to always succeed for testing
  }

  // Preference Management
  Future<void> setFaceIdEnabled(bool enabled) async {}

  Future<bool> isFaceIdEnabled() async {
    return false;
  }

  Future<void> setSecuritySetupDone(bool done) async {}

  Future<bool> isSecuritySetupDone() async {
    return true; // Assume setup done to avoid dialog
  }
}
