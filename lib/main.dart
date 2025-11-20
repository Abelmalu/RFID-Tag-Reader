import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

// --- Global Constants for Colors and Storage Keys ---
const Color kDarkBackgroundColor = Color(0xFF1A2B3C);
const Color kPrimaryAccentColor = Color(0xFF00C6AE);
const Color kLightTextColor = Colors.white;
const Color kSecondaryTextColor = Colors.white70;
const Color kAppBarTopColor = Color(0xFF15222E);

// API Base URL (Must be configured for your environment)
// NOTE: For local testing, change this to your actual server IP, e.g., 192.168.1.5:8080
const String _baseUrl = 'http://127.0.0.1:8080';

// Shared Preferences Keys
const String _kDeviceApiKey = 'device_api_key'; // <-- The new, revocable key
const String _kSelectedCafeteriaId = 'selected_cafeteria_id';
const String _kSelectedCafeteriaName = 'selected_cafeteria_name';

// --------------------------------------------------------

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Decoupled Device App',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kDarkBackgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: kAppBarTopColor,
          titleTextStyle: TextStyle(
            color: kLightTextColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: const AppInitializationWrapper(),
    );
  }
}

// --------------------------------------------------------
/// Device Service to handle retrieving the stored API Key.
// --------------------------------------------------------
class DeviceService {
  static Future<String?> getDeviceApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kDeviceApiKey);
  }

  static Future<void> saveDeviceApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDeviceApiKey, key);
  }

  static Future<void> clearApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kDeviceApiKey);
  }
}

/// --------------------------------------------------------
/// 1. App Initialization Wrapper (Checks the API Key to skip SN entry)
/// --------------------------------------------------------
class AppInitializationWrapper extends StatelessWidget {
  const AppInitializationWrapper({super.key});

  Future<String> _getInitialRoute() async {
    final apiKey = await DeviceService.getDeviceApiKey();
    final prefs = await SharedPreferences.getInstance();
    final selectedId = prefs.getInt(_kSelectedCafeteriaId);

    if (apiKey == null || apiKey.isEmpty) {
      // If the API Key is missing, we must show the SN input screen
      return '/activation';
    }

    if (selectedId == null) {
      // If API Key exists, but no cafeteria set, go to selection
      return '/selection';
    }

    return '/home'; // Fully set up
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getInitialRoute(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: kPrimaryAccentColor),
            ),
          );
        }

        final initialRoute = snapshot.data ?? '/activation';

        switch (initialRoute) {
          case '/activation':
            return const ActivationScreen();
          case '/selection':
            return const CafeteriaSelectionScreen();
          case '/home':
            return const DeviceHome();
          default:
            return const ActivationScreen();
        }
      },
    );
  }
}

// --------------------------------------------------------
/// 2. Device Activation Screen (One-time Serial Number Entry & Key Exchange)
/// --------------------------------------------------------
class ActivationScreen extends StatefulWidget {
  const ActivationScreen({Key? key}) : super(key: key);

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _snController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _activateDevice() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final String serialNumber = _snController.text;

      // Endpoint: Send the SN, receive the Device API Key
      final uri = Uri.parse('$_baseUrl/api/admin/activate_and_get_key');

      final response = await http.post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{"serial_number": serialNumber}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final newApiKey = responseData['device_api_key'] as String?;

        if (newApiKey != null && newApiKey.isNotEmpty) {
          // SUCCESS: Save the revocable API Key for all future requests.
          await DeviceService.saveDeviceApiKey(newApiKey);

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const CafeteriaSelectionScreen(),
              ),
            );
          }
        } else {
          setState(() {
            _errorMessage =
                'Activation failed: Server did not return a valid API Key.';
          });
        }
      } else {
        final errorJson = jsonDecode(response.body);
        setState(() {
          _errorMessage =
              errorJson['message'] ??
              'Activation failed. Serial number rejected.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Connection Error. Check your network or API server. Details: $e';
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
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
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
      appBar: AppBar(title: const Text('Device Activation (One-Time Setup)')),
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
                  Icons.key_rounded,
                  size: 80,
                  color: kPrimaryAccentColor,
                ),
                const SizedBox(height: 30),
                Text(
                  'Activate Device',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: kLightTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Enter the device\'s physical Serial Number to authorize this hardware.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kSecondaryTextColor),
                ),
                const SizedBox(height: 20),

                _buildTextField(
                  controller: _snController,
                  labelText: 'Serial Number',
                  hintText: 'e.g., SN292 (Printed on device)',
                  icon: Icons.qr_code_2_rounded,
                  validator: (value) => value!.isEmpty
                      ? 'Please enter the device\'s Serial Number'
                      : null,
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
                  onPressed: _isLoading ? null : _activateDevice,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: kDarkBackgroundColor,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.lock_open_rounded, size: 24),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 16.0,
                    ),
                    child: Text(
                      _isLoading ? 'Activating...' : 'Activate Device',
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

/// --------------------------------------------------------
/// 3. Cafeteria Selection Screen (Uses the Device API Key in Headers)
/// --------------------------------------------------------
class CafeteriaSelectionScreen extends StatefulWidget {
  const CafeteriaSelectionScreen({super.key});

  @override
  State<CafeteriaSelectionScreen> createState() =>
      _CafeteriaSelectionScreenState();
}

class _CafeteriaSelectionScreenState extends State<CafeteriaSelectionScreen> {
  List<Map<String, dynamic>> _cafeterias = [];
  bool _isDataLoading = true;
  int? _selectedCafeteriaId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _getCafeterias();
  }

  Future<void> _getCafeterias() async {
    setState(() {
      _isDataLoading = true;
      _errorMessage = null;
    });

    final apiKey = await DeviceService.getDeviceApiKey();
    if (apiKey == null) {
      _handleUnauthorizedAccess();
      return;
    }

    try {
      final uri = Uri.parse('$_baseUrl/api/cafeterias');

      // Sending the API Key with every request for validation
      final response = await http.get(
        uri,
        headers: {
          'X-Device-API-Key': apiKey, // <-- Using the safe, revocable key
        },
      );

      // Security check: If the backend rejects the API Key, we reset and show an error.
      if (response.statusCode == 401 || response.statusCode == 403) {
        _handleUnauthorizedAccess();
        return;
      }

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<Map<String, dynamic>> rawList = List<Map<String, dynamic>>.from(
          decoded as List,
        );

        List<Map<String, dynamic>> safeList = rawList.map((cafeteria) {
          int id = 0;
          if (cafeteria.containsKey('id')) {
            final idValue = cafeteria['id'];
            if (idValue is int) {
              id = idValue;
            } else if (idValue is String) {
              id = int.tryParse(idValue) ?? 0;
            }
          }
          return Map<String, dynamic>.from(cafeteria)..['id'] = id;
        }).toList();

        setState(() {
          _cafeterias = safeList.where((c) => c['id'] != 0).toList();
          _isDataLoading = false;
        });
      } else {
        final errorJson = jsonDecode(response.body);
        setState(() {
          _errorMessage =
              'Error fetching cafeterias (Status: ${response.statusCode}): ${errorJson['message'] ?? 'Unknown API Error'}';
          _isDataLoading = false;
        });
      }
    } catch (e) {
      print('Network/Unknown Error fetching cafeterias: $e');
      setState(() {
        _errorMessage =
            'Connection Error. Could not load cafeterias. Details: $e';
        _isDataLoading = false;
      });
    }
  }

  void _handleUnauthorizedAccess() async {
    // Clear the API Key, forcing the user back to the ActivationScreen
    await DeviceService.clearApiKey();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const ErrorScreen(
            message:
                'Device authorization failed. Please reactivate with the Serial Number.',
            redirectToRegistration: true,
          ),
        ),
      );
    }
  }

  Future<void> _saveSelectionAndProceed() async {
    if (_selectedCafeteriaId == null) {
      setState(() {
        _errorMessage = 'Please select a cafeteria to continue.';
      });
      return;
    }

    final selectedCafeteria = _cafeterias.firstWhere(
      (c) => c['id'] == _selectedCafeteriaId,
      orElse: () => {'id': 0, 'name': 'Unknown'},
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kSelectedCafeteriaId, _selectedCafeteriaId!);
    await prefs.setString(
      _kSelectedCafeteriaName,
      selectedCafeteria['name'] as String,
    );

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DeviceHome()),
      );
    }
  }

  Widget _buildStyledDropdown() {
    final BorderSide borderSide = const BorderSide(
      color: kPrimaryAccentColor,
      width: 1,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: kDarkBackgroundColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderSide.color, width: borderSide.width),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedCafeteriaId,
          hint: Row(
            children: [
              const Icon(
                Icons.location_city_rounded,
                color: kPrimaryAccentColor,
              ),
              const SizedBox(width: 12),
              Text(
                'Select Active Cafeteria',
                style: TextStyle(color: kSecondaryTextColor.withOpacity(0.8)),
              ),
            ],
          ),
          style: const TextStyle(color: kLightTextColor, fontSize: 16),
          icon: const Icon(
            Icons.arrow_drop_down,
            color: kPrimaryAccentColor,
            size: 30,
          ),
          isExpanded: true,
          dropdownColor: kAppBarTopColor,

          items: _cafeterias.map<DropdownMenuItem<int>>((
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
            if (newValue != _selectedCafeteriaId || _errorMessage != null) {
              setState(() {
                _selectedCafeteriaId = newValue;
                if (_errorMessage != null) _errorMessage = null;
              });
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cafeteria Selection (Step 2 of 2)')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.pin_drop_rounded,
                size: 80,
                color: kPrimaryAccentColor,
              ),
              const SizedBox(height: 30),
              Text(
                'Set Active Location',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: kLightTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Select the cafeteria this device will currently operate for.',
                textAlign: TextAlign.center,
                style: TextStyle(color: kSecondaryTextColor, fontSize: 16),
              ),
              const SizedBox(height: 30),

              if (_isDataLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(
                      color: kPrimaryAccentColor,
                    ),
                  ),
                )
              else if (_cafeterias.isEmpty)
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.refresh, color: kPrimaryAccentColor),
                    label: const Text(
                      'No cafeterias found. Tap to retry.',
                      style: TextStyle(color: kPrimaryAccentColor),
                    ),
                    onPressed: _getCafeterias,
                  ),
                )
              else
                _buildStyledDropdown(),

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
                onPressed: _isDataLoading || _selectedCafeteriaId == null
                    ? null
                    : _saveSelectionAndProceed,
                icon: const Icon(Icons.save_rounded, size: 24),
                label: const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 16.0,
                  ),
                  child: Text(
                    'Save Selection',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
    );
  }
}

/// --------------------------------------------------------
/// 4. Device Home Screen
/// --------------------------------------------------------
class DeviceHome extends StatefulWidget {
  const DeviceHome({super.key});

  @override
  State<DeviceHome> createState() => _DeviceHomeState();
}

class _DeviceHomeState extends State<DeviceHome> {
  String _activeCafeteriaName = 'Loading...';
  int? _activeCafeteriaId;

  @override
  void initState() {
    super.initState();
    _loadActiveCafeteria();
  }

  Future<void> _loadActiveCafeteria() async {
    final prefs = await SharedPreferences.getInstance();
    final name =
        prefs.getString(_kSelectedCafeteriaName) ?? 'Cafeteria Not Set';
    final id = prefs.getInt(_kSelectedCafeteriaId);

    setState(() {
      _activeCafeteriaName = name;
      _activeCafeteriaId = id;
    });
  }

  Future<void> _resetDevice() async {
    final prefs = await SharedPreferences.getInstance();
    // This clears the API Key, forcing re-activation on next launch
    await DeviceService.clearApiKey();
    await prefs.remove(_kSelectedCafeteriaId);
    await prefs.remove(_kSelectedCafeteriaName);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ActivationScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Active'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _resetDevice,
            tooltip: 'Deactivate Device (Requires SN re-entry)',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const CafeteriaSelectionScreen(),
                ),
              );
            },
            tooltip: 'Change Cafeteria',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 100,
                color: kPrimaryAccentColor,
              ),
              const SizedBox(height: 20),
              const Text(
                'Device Ready for Scanning',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: kLightTextColor,
                ),
              ),
              const SizedBox(height: 40),
              Card(
                color: kAppBarTopColor,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Text(
                        'Currently Active Cafeteria:',
                        style: TextStyle(
                          fontSize: 16,
                          color: kSecondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _activeCafeteriaName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: kPrimaryAccentColor,
                        ),
                      ),
                      if (_activeCafeteriaId != null)
                        Text(
                          '(ID: $_activeCafeteriaId)',
                          style: const TextStyle(
                            fontSize: 14,
                            color: kSecondaryTextColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              TextButton.icon(
                icon: const Icon(
                  Icons.location_on_rounded,
                  color: kPrimaryAccentColor,
                ),
                label: const Text(
                  'Change Location',
                  style: TextStyle(color: kPrimaryAccentColor),
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CafeteriaSelectionScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// --------------------------------------------------------
/// 5. Error Screen
/// --------------------------------------------------------
class ErrorScreen extends StatelessWidget {
  final String message;
  final bool redirectToRegistration;

  const ErrorScreen({
    super.key,
    required this.message,
    this.redirectToRegistration = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Application Error')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.security_update_warning_rounded,
                size: 80,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 30),
              Text(
                'Security/Initialization Failure',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: kLightTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent, fontSize: 16),
              ),
              const SizedBox(height: 30),
              if (redirectToRegistration)
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to the one-time activation screen
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ActivationScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.cached),
                  label: const Text('Go to Activation'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryAccentColor,
                    foregroundColor: kDarkBackgroundColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
