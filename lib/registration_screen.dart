import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // For json.encode
import 'main.dart'; // For making HTTP requests

// Import your custom colors from main.dart
const Color kDarkBackgroundColor = Color(0xFF1A2B3C);
const Color kPrimaryAccentColor = Color(0xFF00C6AE);
const Color kLightTextColor = Colors.white;
const Color kSecondaryTextColor = Colors.white70;

// This is the Home Screen from main.dart, used for navigation
// We import it here so we can navigate to it after registration
// Import HomeScreen from main.dart

class DeviceRegistrationScreen extends StatefulWidget {
  const DeviceRegistrationScreen({Key? key}) : super(key: key);

  // Key used to store the registration status in SharedPreferences
  static const String _kIsDeviceRegistered = 'is_device_registered';

  @override
  State<DeviceRegistrationScreen> createState() =>
      _DeviceRegistrationScreenState();
}

class _DeviceRegistrationScreenState extends State<DeviceRegistrationScreen> {
  final _formKey = GlobalKey<FormState>(); // Key for form validation
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _serialNumberController = TextEditingController();
  final TextEditingController _cafeteriaIdController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  // Placeholder for your Go backend's base URL
  // IMPORTANT: Replace with your actual Go server's IP address/domain
  static const String _baseUrl = 'http://127.0.0.1:8080';

  Future<void> _registerDevice() async {
    // 1. Validation
    if (!_formKey.currentState!.validate()) {
      return; // Stop if form is not valid
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final String name = _nameController.text;
      final String serialNumber = _serialNumberController.text;
      // CRITICAL: Parse the String from the controller into an Int
      final int cafeteriaId = int.parse(_cafeteriaIdController.text);

      final uri = Uri.parse('$_baseUrl/api/admin/register/device');

      print('Attempting to register device to: $uri');
      print(
        'Payload: {name: $name, serial_number: $serialNumber, cafeteria_id: $cafeteriaId}',
      );

      final response = await http.post(
        uri,
        // CRITICAL: Set the Content-Type header
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        // CRITICAL: Use jsonEncode() to send the integer ID correctly
        body: jsonEncode(<String, dynamic>{
          "name": name,
          "serial_number": serialNumber,
          "cafeteria_id": cafeteriaId,
        }),
      );

      // 2. Handle Response
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success
        final responseBody = jsonDecode(response.body);
        setState(() {
          _successMessage =
              'Device registered successfully! Response: ${responseBody['message']}';
          _errorMessage = null;
        });
        print('Registration Success: ${response.body}');
      } else {
        // API returned an error status
        print('API Error Status ${response.statusCode}: ${response.body}');
        final errorJson = jsonDecode(response.body);
        setState(() {
          _errorMessage = errorJson['Message'];
        });
      }
    } catch (e) {
      // 3. Handle Network/Parsing Errors (This is where your connection issue lives)
      print('Network/Unknown Error: $e');
      setState(() {
        _errorMessage =
            'Connection Error. Check your Wi-Fi, IP address, and firewall. Error details: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _serialNumberController.dispose();
    _cafeteriaIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Device Registration',
          style: TextStyle(color: kLightTextColor),
        ),
        backgroundColor: kAppBarTopColor,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.device_hub_rounded,
                  size: 80,
                  color: kPrimaryAccentColor,
                ),
                const SizedBox(height: 30),
                Text(
                  'Register Your Device',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: kLightTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _nameController,
                  labelText: 'Device Name',
                  hintText: 'e.g., Cafeteria Scanner 01',
                  icon: Icons.label_important_rounded,
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a device name' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _serialNumberController,
                  labelText: 'Serial Number',
                  hintText: 'e.g., SN292',
                  icon: Icons.code_rounded,
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a serial number' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _cafeteriaIdController,
                  labelText: 'Cafeteria ID',
                  hintText: 'e.g., 3',
                  icon: Icons.location_on_rounded,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter a cafeteria ID';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _registerDevice,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: kDarkBackgroundColor,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.app_registration_rounded, size: 24),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 16.0,
                    ),
                    child: Text(
                      _isLoading ? 'Registering...' : 'Register Device',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: kDarkBackgroundColor,
                    backgroundColor: kPrimaryAccentColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: kPrimaryAccentColor.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: kLightTextColor),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        hintStyle: TextStyle(color: kSecondaryTextColor.withOpacity(0.6)),
        prefixIcon: Icon(icon, color: kPrimaryAccentColor),
        labelStyle: const TextStyle(color: kSecondaryTextColor),
        filled: true,
        fillColor: kDarkBackgroundColor.withOpacity(0.5),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimaryAccentColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimaryAccentColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
      validator: validator,
    );
  }
}
