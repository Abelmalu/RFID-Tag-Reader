import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'device_service.dart';
import 'home_screen.dart';

// Constants
const Color kDarkBackgroundColor = Color(0xFF1A2B3C);
const Color kPrimaryAccentColor = Color(0xFF00C6AE);
const Color kLightTextColor = Colors.white;
const Color kSecondaryTextColor = Colors.white70;
const Color kAppBarTopColor = Color(0xFF15222E);
const String _baseUrl = 'http://18.206.59.15:8080';

class SerialNumberAuthScreen extends StatefulWidget {
  const SerialNumberAuthScreen({Key? key}) : super(key: key);

  @override
  State<SerialNumberAuthScreen> createState() => _SerialNumberAuthScreenState();
}

class _SerialNumberAuthScreenState extends State<SerialNumberAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _serialNumberController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  // Step 3: Verify workflow
  Future<void> _verifySerialNumber() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final serialNumber = _serialNumberController.text;

    try {
      final uri = Uri.parse('$_baseUrl/api/device/verify/$serialNumber');
      print(uri);

      final response = await http.get(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      print(response.statusCode);

      if (response.statusCode == 202) {
        final responseData = jsonDecode(response.body);
        print(responseData["status"]);

        print(responseData);
        // Assuming the backend returns a device_token on success

        if (responseData["status"] == "success") {
          // Success: Save registration state and token
          await DeviceService.saveRegistrationData();

          //Step 3 & 5: Navigate replace to HomeScreen
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        } else {
          setState(() {
            _errorMessage =
                'Verification failed: Server did not return a valid device token.';
          });
        }
      } else {
        // Handle backend error (e.g., serial not found)
        final errorJson = jsonDecode(response.body);
        setState(() {
          _errorMessage =
              errorJson['message'] ?? 'Serial Number Verification Failed.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Connection Error. Please check your network. Details: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Activation'),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.vpn_key_rounded,
                  size: 80,
                  color: kPrimaryAccentColor,
                ),
                const SizedBox(height: 30),
                Text(
                  'Enter Device Serial Number',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: kLightTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _serialNumberController,
                  labelText: 'Serial Number',
                  hintText: 'e.g., SN292',
                  icon: Icons.code_rounded,
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a serial number' : null,
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
                        fontSize: 16,
                      ),
                    ),
                  ),

                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _verifySerialNumber,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: kDarkBackgroundColor,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline, size: 24),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    child: Text(
                      _isLoading ? 'Verifying...' : 'Verify Serial Number',
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
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
