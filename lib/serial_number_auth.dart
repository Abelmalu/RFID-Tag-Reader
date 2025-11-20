import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'device_service.dart';
import 'home_screen.dart';

// Constants
const Color kPrimaryAccentColor = Color(0xFF00C6AE);
const Color kDarkBackgroundColor = Color(0xFF1A2B3C);
const Color kLightTextColor = Colors.white;
const Color kSecondaryTextColor = Colors.white70;
const String _baseUrl = 'http://127.0.0.1:8080'; // <-- CHANGE THIS TO YOUR API

class SerialNumberAuthScreen extends StatefulWidget {
  const SerialNumberAuthScreen({Key? key}) : super(key: key);

  @override
  State<SerialNumberAuthScreen> createState() => _SerialNumberAuthScreenState();
}

class _SerialNumberAuthScreenState extends State<SerialNumberAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _snController = TextEditingController();

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

    final serialNumber = _snController.text;

    try {
      final uri = Uri.parse('$_baseUrl/api/device/verify');

      final response = await http.post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{"serial": serialNumber}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // Assuming the backend returns a device_token on success
        final deviceToken = responseData['device_token'] as String?;

        if (deviceToken != null && deviceToken.isNotEmpty) {
          // Success: Save registration state and token
          await DeviceService.saveRegistrationData(
            serialNumber: serialNumber,
            deviceToken: deviceToken,
          );

          // Step 3 & 5: Navigate replace to HomeScreen
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
                TextFormField(
                  controller: _snController,
                  style: const TextStyle(color: kLightTextColor),
                  decoration: InputDecoration(
                    labelText: 'Serial Number',
                    hintText: 'e.g., ABC-123',
                    prefixIcon: const Icon(
                      Icons.qr_code_2_rounded,
                      color: kPrimaryAccentColor,
                    ),
                    filled: true,
                    fillColor: kDarkBackgroundColor.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: kPrimaryAccentColor,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Serial Number is required' : null,
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
