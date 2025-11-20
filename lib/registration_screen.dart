import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// --- Custom Colors/Constants (Defined for Runnability) ---
const Color kDarkBackgroundColor = Color(0xFF1A2B3C);
const Color kPrimaryAccentColor = Color(0xFF00C6AE);
const Color kLightTextColor = Colors.white;
const Color kSecondaryTextColor = Colors.white70;
const Color kAppBarTopColor = Color(0xFF15222E);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: DeviceRegistrationScreen());
  }
}
// --------------------------------------------------------

class DeviceRegistrationScreen extends StatefulWidget {
  const DeviceRegistrationScreen({Key? key}) : super(key: key);

  static const String _kIsDeviceRegistered = 'is_device_registered';

  @override
  State<DeviceRegistrationScreen> createState() =>
      _DeviceRegistrationScreenState();
}

class _DeviceRegistrationScreenState extends State<DeviceRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _serialNumberController = TextEditingController();

  // --- Dropdown State and Data ---
  List<Map<String, dynamic>>? _cafeterias;

  // Initialize as null so the hint is displayed by default
  int? _selectedCafeteriaId;
  // -------------------------------

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  static const String _baseUrl = 'http://127.0.0.1:8080';

  @override
  void initState() {
    super.initState();
    // Do NOT initialize _selectedCafeteriaId here. Keep it null
    // to force the user to select an option and display the hint.

    _getCafeterias();
  }

  Future<void> _getCafeterias() async {
    try {
      var uri = Uri.parse('$_baseUrl/api/cafeterias');
      final response = await http.get(uri);

      print("Printing response body");
      print(response.body);

      final decoded = jsonDecode(response.body);
      print("printing ");

      setState(() {
        _cafeterias = List<Map<String, dynamic>>.from(decoded);
      });
      print("printing _cafeterias");
      print(_cafeterias);
    } catch (e) {
      print(e);
    }
  }

  Future<void> _registerDevice() async {
    // 1. Validation
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 2. Critical Check: Ensure a cafeteria has been selected (i.e., not null)
    if (_selectedCafeteriaId == null) {
      setState(() {
        _errorMessage = 'Please select a cafeteria to register the device.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final String name = _nameController.text;
      final String serialNumber = _serialNumberController.text;
      final int cafeteriaId =
          _selectedCafeteriaId!; // Non-null guaranteed by check above

      final uri = Uri.parse('$_baseUrl/api/admin/register/device');

      print('Attempting to register device to: $uri');
      print(
        'Payload: {name: $name, serial_number: $serialNumber, cafeteria_id: $cafeteriaId}',
      );

      final response = await http.post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          "name": name,
          "serial_number": serialNumber,
          "cafeteria_id": cafeteriaId,
        }),
      );

      // 2. Handle Response
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = jsonDecode(response.body);
        setState(() {
          _successMessage =
              'Device registered successfully! Response: ${responseBody['message']}';
          _errorMessage = null;
        });
        print('Registration Success: ${response.body}');
      } else {
        print('API Error Status ${response.statusCode}: ${response.body}');
        final errorJson = jsonDecode(response.body);
        setState(() {
          _errorMessage = errorJson['message'];
        });
      }
    } catch (e) {
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
    super.dispose();
  }

  /// Builds a standard TextFormField with the defined styling.
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

  /// Builds a styled DropdownButton wrapped in a Container to match the TextFormField aesthetic.
  Widget _buildStyledDropdown() {
    final BorderSide borderSide = const BorderSide(
      color: kPrimaryAccentColor,
      width: 1,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      // Apply the same border/fill decoration as the text field
      decoration: BoxDecoration(
        color: kDarkBackgroundColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderSide.color, width: borderSide.width),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          // Value can be null, which triggers the hint to show
          value: _selectedCafeteriaId,

          // --- NEW: Add the hint text when no value is selected ---
          hint: Row(
            children: [
              const Icon(
                Icons.location_city_rounded,
                color: kPrimaryAccentColor,
              ),
              const SizedBox(width: 12),
              Text(
                'Select Cafeteria',
                style: TextStyle(color: kSecondaryTextColor.withOpacity(0.8)),
              ),
            ],
          ),
          // --------------------------------------------------------

          // Style the text of the selected value
          style: const TextStyle(color: kLightTextColor, fontSize: 16),
          icon: const Icon(
            Icons.arrow_drop_down,
            color: kPrimaryAccentColor,
            size: 30,
          ),
          isExpanded: true,
          dropdownColor: kAppBarTopColor,

          items: _cafeterias?.map<DropdownMenuItem<int>>((
            Map<String, dynamic> cafeteria,
          ) {
            return DropdownMenuItem<int>(
              value: cafeteria['id'] as int,
              child: Text(
                cafeteria['name'] as String,
                style: const TextStyle(color: kLightTextColor),
              ),
            );
          }).toList(),

          onChanged: (int? newValue) {
            setState(() {
              _selectedCafeteriaId = newValue;
              // Clear error message when a selection is made
              if (_errorMessage != null) _errorMessage = null;
            });
          },
        ),
      ),
    );
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
                _buildStyledDropdown(),
                const SizedBox(height: 30),
                // Display success message
                if (_successMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Text(
                      _successMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: kPrimaryAccentColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                // Display error message
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
}
