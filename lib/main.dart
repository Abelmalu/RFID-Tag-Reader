import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'RFID_screen.dart';

void main() {
  runApp(MyApp());
}

// --- Color Palette ---
const Color kDarkBackgroundColor = Color(0xFF1A2B3C);
const Color kPrimaryAccentColor = Color(0xFF00C6AE);
const Color kLightTextColor = Colors.white;
const Color kSecondaryTextColor = Colors.white70;

// Custom colors for the AppBar gradient to ensure visual distinction
const Color kAppBarTopColor = Color(0xFF223A53);
const Color kAppBarBottomColor = Color(0xFF152A40);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Light status bar icons
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Scaffold(
      backgroundColor: kDarkBackgroundColor,
      body: Stack(
        children: [
          // --- Background Decorative Elements ---
          _buildSparkle(top: 100, left: 50),
          _buildSparkle(top: 300, right: 70),
          _buildSparkle(bottom: 200, left: 60),
          _buildDottedPattern(bottom: 40, right: 40),

          // --- FIX: Wrap the Column in Positioned.fill ---
          // This gives the Column a defined size within the Stack,
          // which allows the Expanded widget to work correctly.
          Positioned.fill(
            child: Column(
              children: [
                // --- Custom Curved AppBar ---
                ClipPath(
                  clipper: AppBarClipper(),
                  child: Container(
                    height: 160,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      // UPDATED: Using distinct colors for a separated AppBar
                      gradient: LinearGradient(
                        colors: [kAppBarTopColor, kAppBarBottomColor],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Tag & Scan',
                            style: TextStyle(
                              color: kLightTextColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'What would you like to scan today?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: kSecondaryTextColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // --- Centered Cards in Remaining Body ---
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildScanOptionCard(
                            icon: Icons.qr_code_scanner_rounded,
                            title: 'Scan QR Codeee',
                            subtitle: 'Open camera to scan a barcode',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const NfcReaderScreen(),
                                ),
                              );
                            },
                          ),
                          // Using the 30 logical pixels you added
                          const SizedBox(height: 30),
                          _buildScanOptionCard(
                            icon: Icons.nfc_rounded,
                            title: 'Scan RFID Tag',
                            subtitle: 'Tap an NFC/RFID tag to read',
                            onTap: () => print('Navigating to RFID Scanner...'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Reusable Scan Option Card ---
  Widget _buildScanOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: kPrimaryAccentColor.withOpacity(0.1),
          border: Border.all(color: kPrimaryAccentColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              // Using the more intense shadow you added
              color: kPrimaryAccentColor.withOpacity(0.25),
              blurRadius: 12,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 48, color: kPrimaryAccentColor),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: kLightTextColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: kSecondaryTextColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: kSecondaryTextColor,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // --- Sparkles (background decorations) ---
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
        // Using the star icon you chose
        Icons.star_rounded,
        color: kPrimaryAccentColor.withOpacity(0.4),
        size: 18,
      ),
    );
  }

  // --- Dotted corner pattern ---
  Widget _buildDottedPattern({double? bottom, double? right}) {
    return Positioned(
      bottom: bottom,
      right: right,
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
}

// --- Custom Clipper for Smooth Curved AppBar ---
class AppBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 30);
    // This creates the nice dip in the center
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 30, // Control point is *below* the line
      size.width,
      size.height - 30, // End point
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
