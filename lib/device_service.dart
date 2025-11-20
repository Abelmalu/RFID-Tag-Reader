import 'package:shared_preferences/shared_preferences.dart';

// --- Shared Preferences Keys ---
const String kRegisteredKey = 'registered';
const String kSerialNumberKey = 'serial_number';
const String kDeviceTokenKey = 'device_token';

class DeviceService {
  /// Step 2: Checks if the device has been successfully registered.
  static Future<bool> isRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(kRegisteredKey) ?? false;
  }

  /// Step 3: Saves all registration data upon successful backend verification.
  static Future<void> saveRegistrationData({
    required String serialNumber,
    required String deviceToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kRegisteredKey, true);
    await prefs.setString(kSerialNumberKey, serialNumber);
    await prefs.setString(kDeviceTokenKey, deviceToken);
  }

  /// Optional: Clears all local data, forcing re-registration.
  static Future<void> clearRegistrationData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kRegisteredKey);
    await prefs.remove(kSerialNumberKey);
    await prefs.remove(kDeviceTokenKey);
  }

  /// Retrieves the saved token for API calls (Step 4 & 5).
  static Future<String?> getDeviceToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(kDeviceTokenKey);
  }
}
