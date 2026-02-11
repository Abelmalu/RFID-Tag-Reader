import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// import 'nfcReader.dart';
import 'cafeteria_scanning_screen.dart';

// --- Custom Colors/Constants (Defined for Runnability) ---
const Color kDarkBackgroundColor = Color(0xFF1A2B3C);
const Color kPrimaryAccentColor = Color(0xFF00C6AE);
const Color kLightTextColor = Colors.white;
const Color kSecondaryTextColor = Colors.white70;
const Color kAppBarTopColor = Color(0xFF15222E);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: DeviceRegistrationScreen());
  }
}
// -----------------------------------------------

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

  static const String _baseUrl = 'http://18.206.59.15:8080';

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

  Future<void> _startScanning(BuildContext ctx) async {
    print("this is the id ");
    print(_selectedCafeteriaId);
    // 1. Validation
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 2. Critical Check: Ensure a cafeteria has been selected (i.e., not null)
    if (_selectedCafeteriaId == null) {
      setState(() {
        _errorMessage = 'Please select a cafeteria you want to Scan .';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    setState(() {
      _isLoading = false;
    });

    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (ctx) {
          return NfcReaderScreen(cafeteriaId: _selectedCafeteriaId!);
        },
      ),
    );
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
          'Cafeteria Selection',
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
                  'Choose Cafeteria',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: kLightTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

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
                  onPressed: _isLoading ? null : () => _startScanning(context),
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
                      _isLoading ? 'Choosing Cafeteria...' : 'Start Scanning',
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
