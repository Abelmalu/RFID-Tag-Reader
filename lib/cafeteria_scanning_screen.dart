import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'dart:typed_data';

// Color Palette
const Color kDarkBackgroundColor = Color(0xFF1A2B3C);
const Color kAppBarColor = Color(0xFF223A53); // Distinct color for AppBar
const Color kPrimaryAccentColor = Color(0xFF00C6AE);
const Color kLightTextColor = Colors.white;
const Color kSecondaryTextColor = Colors.white70;
const Color kErrorColor = Color(0xFFE57373); // Light red for errors/not found

class NfcReaderScreen extends StatefulWidget {
  final int cafeteriaId;

  const NfcReaderScreen({
    super.key, // Standard Flutter convention
    required this.cafeteriaId,
  });

  @override
  State<NfcReaderScreen> createState() => _NfcReaderScreenState();
}

class _NfcReaderScreenState extends State<NfcReaderScreen>
    with TickerProviderStateMixin {
  // State for NFC results
  String? _tagUid;
  Map<String, dynamic>? _studentData;
  bool _isNfcAvailable = true;
  bool _isScanning = true;
  static final String _baseUrl = "http://192.168.100.169:8080";

  // Animation Controllers
  late AnimationController _popController;
  late Animation<double> _scaleAnimation;
  late AnimationController _orbitController;

  // Mock Student Data
  final List<Map<String, dynamic>> students = [
    {
      'id': 'C6:65:D3:EA',
      'full_name': 'ABEBE TASEW',
      'batch': 'Batch 2025',
      'department': 'Computer Science',
    },
    {
      'id': '79:68:DB:9B',
      'full_name': 'MASRESHA Kasa',
      'batch': 'Batch 2025',
      'department': 'Information Technology',
    },
    {
      'id': 'F9:CE:9D:9B',
      'full_name': 'TOMAS SEFIW',
      'batch': 'Batch 2024',
      'department': 'Software Engineering',
    },
  ];

  // Utility function to convert tag UID bytes to Hex string
  String _bytesToHexString(Uint8List bytes) {
    if (bytes.isEmpty) return 'N/A';
    return bytes
        .map((e) => e.toRadixString(16).padLeft(2, '0'))
        .join(':')
        .toUpperCase();
  }

  // --- NFC Management ---

  @override
  void initState() {
    super.initState();
    print(widget.cafeteriaId);
    print("printing in initState");
    _checkNfcAvailability();
    _startNfcSession();

    // 1. Controller for the phone "pop" animation
    _popController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: true); // Repeats back and forth

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _popController, curve: Curves.easeInOut));

    // 2. Controller for the tag "orbit" animation
    _orbitController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(); // Repeats in one direction
  }

  void _checkNfcAvailability() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    if (mounted) {
      setState(() {
        _isNfcAvailable = isAvailable;
      });
    }
  }

  void _startNfcSession() {
    // Check if NFC is available before starting the session
    if (!_isNfcAvailable) return;
    print("in the start NFC method");
    NfcManager.instance
        .startSession(
          pollingOptions: {
            NfcPollingOption.iso14443,
            NfcPollingOption.iso15693,
            NfcPollingOption.iso18092,
          },
          onDiscovered: (NfcTag tag) async {
            // We do NOT call NfcManager.instance.stopSession() here,
            // which keeps the session running for continuous listening.

            // 1. Process Tag ID (using MifareClassicAndroid as example)
            final MifareClassicAndroid? mifareClassicCard =
                MifareClassicAndroid.from(tag);
            final rawUidBytes = mifareClassicCard?.tag.id;
            final tagUid = rawUidBytes != null
                ? _bytesToHexString(rawUidBytes)
                : null;
            // print(tagUid);
            print("hellow from uid");
            // 2. Look up student data
            Map<String, dynamic>? student;
            if (tagUid != null) {
              try {
                // student = students.firstWhere((s) => s['id'] == tagUid);
                print(tagUid);
                print("object");
                final urlMealAccess = Uri.parse(
                  "$_baseUrl/api/mealaccess/$tagUid/${widget.cafeteriaId}",
                );

                final response = await http.get(urlMealAccess);
                print("decoded data from meal accss");
                final decode = jsonDecode(response.body);
                student = decode as Map<String, dynamic>?;

                print(decode);

                if (decode?["status"] == "error") {
                  print("error");
                }
              } catch (e) {
                // Student not found, student remains null
                print("printing the error for the api call");
                print(e);
              }
            }

            // 3. Update UI state
            if (mounted) {
              setState(() {
                _tagUid = tagUid;
                _studentData = student;
                _isScanning = false;
                // Stop animations when a result is displayed
                //_popController.stop();
                _orbitController.stop();
              });
            }
          },
        )
        .catchError((error) {
          // Handle session start errors here
          print("NFC Session Error: $error");
        });
  }

  void _resetScanning() {
    if (mounted) {
      setState(() {
        _tagUid = null;
        _studentData = null;
        _isScanning = true;
      });
      // Restart animations
      _popController.repeat(reverse: true);
      _orbitController.repeat();
    }
  }

  @override
  void dispose() {
    // IMPORTANT: Stop the session when the screen is disposed
    NfcManager.instance.stopSession().catchError(
      (e) => print('Error stopping NFC session during dispose: $e'),
    );

    _popController.dispose();
    _orbitController.dispose();
    super.dispose();
  }

  // --- Widget Builders ---

  // Helper widget for the phone icon (Scanning animation)
  Widget _buildPhoneIcon() {
    return Container(
      width: 140,
      height: 280,
      decoration: BoxDecoration(
        color: kPrimaryAccentColor, // Teal fill
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: kDarkBackgroundColor,
          width: 8,
        ), // Dark border
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          margin: const EdgeInsets.only(top: 12),
          width: 60,
          height: 10,
          decoration: BoxDecoration(
            color: kDarkBackgroundColor, // Dark notch
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ),
    );
  }

  // Helper widget for the white NFC tag (Scanning animation)
  Widget _buildNfcTag() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: kLightTextColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: kPrimaryAccentColor.withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.contactless, color: kPrimaryAccentColor, size: 45),
      ),
    );
  }

  // Helper for the sparkles (background decorations)
  Widget _buildSparkle({
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Icon(
        Icons.star_rounded,
        color: kPrimaryAccentColor.withOpacity(0.4),
        size: 20,
      ),
    );
  }

  // Helper for the dotted pattern in the corner
  Widget _buildDottedPattern() {
    return Positioned(
      bottom: 40,
      right: 40,
      child: Opacity(
        opacity: 0.3,
        child: SizedBox(
          width: 80,
          height: 80,
          child: GridView.builder(
            itemCount: 64,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
            ),
            itemBuilder: (context, index) => Container(
              decoration: BoxDecoration(
                color: kLightTextColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Main Build Method ---
  @override
  Widget build(BuildContext context) {
    Widget mainContent;

    if (!_isNfcAvailable) {
      mainContent = _buildNfcNotAvailable();
    } else if (_isScanning) {
      mainContent = _buildScanningAnimation();
    } else {
      mainContent = _buildResultView();
    }

    return Scaffold(
      backgroundColor: kDarkBackgroundColor,
      appBar: AppBar(
        // Use the distinct color for the AppBar
        backgroundColor: kAppBarColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kLightTextColor),
          // Example of navigating back
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Woldiya University',
          style: TextStyle(color: kLightTextColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          // Decorative elements (sparkles and dots)
          _buildSparkle(top: 150, left: 50),
          _buildSparkle(top: 200, right: 70),
          _buildSparkle(bottom: 250, left: 60),
          _buildDottedPattern(),

          // Main content based on state
          Center(child: mainContent),
        ],
      ),
    );
  }

  // --- Content Widgets based on State ---

  Widget _buildNfcNotAvailable() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.phonelink_erase_rounded,
            color: kErrorColor,
            size: 80,
          ),
          const SizedBox(height: 20),
          const Text(
            'NFC Not Available',
            style: TextStyle(
              color: kErrorColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'This device does not support NFC or it is currently disabled. Please enable it and restart the app.',
            textAlign: TextAlign.center,
            style: TextStyle(color: kSecondaryTextColor, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningAnimation() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        const Text(
          'Tap a tag on the back of the\ndevice to read data.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: kPrimaryAccentColor,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 100),
        SizedBox(
          height: 300,
          width: 300,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. The Phone (Pop Animation)
              ScaleTransition(scale: _scaleAnimation, child: _buildPhoneIcon()),
              // 2. The Orbiting Tag (Positional Animation)
              AnimatedBuilder(
                animation: _orbitController,
                builder: (context, child) {
                  final angle = _orbitController.value * 2 * math.pi;
                  const radius = 110.0;
                  final offset = Offset(
                    math.cos(angle) * radius,
                    math.sin(angle) * radius,
                  );
                  return Transform.translate(offset: offset, child: child);
                },
                child: _buildNfcTag(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultView() {
    print("printing student data");
    print(_studentData);
    if (_studentData?["status"] == "error") {
      return Text(_studentData?["message"]);
    }
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScanResultCard(tagUid: _tagUid, studentData: _studentData),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

// --- Result Card Widget (Nested to keep the main file clean) ---

class ScanResultCard extends StatelessWidget {
  final String? tagUid;
  final Map<String, dynamic>? studentData;

  const ScanResultCard({
    required this.tagUid,
    required this.studentData,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool found = studentData != null && studentData!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kAppBarColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: found ? kPrimaryAccentColor : kErrorColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (found ? kPrimaryAccentColor : kErrorColor).withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                found ? Icons.check_circle_rounded : Icons.warning_rounded,
                color: found ? kPrimaryAccentColor : kErrorColor,
                size: 36,
              ),
              const SizedBox(width: 16),
              Text(
                found ? 'Tag Data Found' : 'Record Not Found',
                style: TextStyle(
                  color: found ? kPrimaryAccentColor : kErrorColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 30, color: kSecondaryTextColor),
          _buildInfoRow('UID:', tagUid ?? 'Unknown Tag', kSecondaryTextColor),
          const SizedBox(height: 10),
          if (found) ...[
            _buildInfoRow(
              'Name:',
              studentData?['data']['first_name'],
              kLightTextColor,
            ),
            const SizedBox(height: 10),
            _buildInfoRow(
              'Department:',
              studentData?['data']['middle_name'],
              kSecondaryTextColor,
            ),
            const SizedBox(height: 10),
            _buildInfoRow(
              'Batch:',
              (studentData?['message']),
              kSecondaryTextColor,
            ),
          ] else
            const Text(
              'No corresponding student record found for this tag ID in the local database.',
              style: TextStyle(color: kSecondaryTextColor, fontSize: 16),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              color: kSecondaryTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 16,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
