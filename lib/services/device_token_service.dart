import 'package:firebase_messaging/firebase_messaging.dart';
import 'profile_service.dart';

class DeviceTokenService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final ProfileService _profileService = ProfileService();

  Future<void> init() async {
    final token = await _messaging.getToken();
    if (token != null) {
      await _profileService.updateDeviceToken(token);
    }
  }

  // 🔥 ADD THIS
  static Future<void> startTokenSync() async {
    await DeviceTokenService().init();
  }
}