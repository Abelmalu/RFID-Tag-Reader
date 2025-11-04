import 'dart:math' as math;
import 'package:flutter/material.dart';

class NfcReaderScreen extends StatefulWidget {
  const NfcReaderScreen({Key? key}) : super(key: key);

  @override
  State<NfcReaderScreen> createState() => _NfcReaderScreenState();
}

class _NfcReaderScreenState extends State<NfcReaderScreen>
    with TickerProviderStateMixin {
  late AnimationController _popController;
  late Animation<double> _scaleAnimation;
  late AnimationController _orbitController;

  @override
  void initState() {
    super.initState();

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

  @override
  void dispose() {
    _popController.dispose();
    _orbitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use a dark blue/grey color for the background
      backgroundColor: const Color(0xFF1A2B3C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Read Tag',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          // Decorative elements (sparkles)
          _buildSparkle(top: 150, left: 50),
          _buildSparkle(top: 200, right: 70),
          _buildSparkle(bottom: 250, left: 60),

          // Decorative dots (bottom right)
          _buildDottedPattern(),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                // The instruction text
                const Text(
                  'Tap on the back of the\ndevice with an NFC\nCompatible tag',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF00C6AE), // Teal color from image
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 100),

                // --- Animation Rig ---
                SizedBox(
                  height: 300,
                  width: 300,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 1. The Phone (with Pop Animation)
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: _buildPhoneIcon(),
                      ),

                      // 2. The Orbiting Tag (with Positional Animation)
                      AnimatedBuilder(
                        animation: _orbitController,
                        builder: (context, child) {
                          // Calculate position in a circle
                          final angle = _orbitController.value * 2 * math.pi;
                          const radius = 110.0;
                          final offset = Offset(
                            math.cos(angle) * radius,
                            math.sin(angle) * radius,
                          );
                          return Transform.translate(
                            offset: offset,
                            child: child,
                          );
                        },
                        child: _buildNfcTag(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for the phone icon
  Widget _buildPhoneIcon() {
    return Container(
      width: 140,
      height: 280,
      decoration: BoxDecoration(
        color: const Color(0xFF00C6AE), // Teal fill
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF0A1A2A),
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
            color: const Color(0xFF0A1A2A), // Dark notch
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ),
    );
  }

  // Helper widget for the white NFC tag
  Widget _buildNfcTag() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.contactless, // A good icon for NFC/tags
          color: Color(0xFF00C6AE), // Teal icon
          size: 45,
        ),
      ),
    );
  }

  // Helper for the sparkles
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
        Icons.abc,
        color: const Color(0xFF00C6AE).withOpacity(0.7),
        size: 20,
      ),
    );
  }

  // Helper for the dotted pattern in the corner
  Widget _buildDottedPattern() {
    return Positioned(
      bottom: 40,
      right: 40,
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
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}









// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';

// void main() {
//   runApp(const MaterialApp(home: NFCTagScreen()));
// }

// class NFCTagScreen extends StatefulWidget {
//   const NFCTagScreen({super.key});

//   @override
//   State<NFCTagScreen> createState() => _NFCTagScreenState();
// }

// class _NFCTagScreenState extends State<NFCTagScreen>
//     with SingleTickerProviderStateMixin {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xff0e2433),
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Title Bar
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//               child: Row(
//                 children: const [
//                   Icon(Icons.arrow_back_ios, color: Colors.white),
//                   SizedBox(width: 10),
//                   Text(
//                     "Read Tag",
//                     style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 22,
//                         fontWeight: FontWeight.bold),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 50),

//             // Animated Area
//             Expanded(
//               child: Center(
//                 child: Stack(
//                   alignment: Alignment.center,
//                   children: [
//                     // Rotating background white circle
//                     Container(
//                       width: 250,
//                       height: 250,
//                       decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(0.1),
//                         shape: BoxShape.circle,
//                       ),
//                     )
//                         .animate(
//                           onPlay: (controller) => controller.repeat(),
//                         )
//                         .rotate(
//                             duration: 10.seconds,
//                             curve: Curves.linear), // slow rotation

//                     // Phone image popping in/out
//                     Container(
//                       width: 180,
//                       height: 320,
//                       decoration: BoxDecoration(
//                         color: const Color(0xff1dc6b8),
//                         borderRadius: BorderRadius.circular(25),
//                       ),
//                       child: const Icon(Icons.nfc, size: 60, color: Colors.white),
//                     )
//                         .animate(
//                           onPlay: (controller) => controller.repeat(reverse: true),
//                         )
//                         .scale(
//                           duration: 2.seconds,
//                           begin: const Offset(0.95, 0.95),
//                           end: const Offset(1.05, 1.05),
//                           curve: Curves.easeInOut,
//                         ),

//                     // NFC chip illustration
//                     Positioned(
//                       bottom: 40,
//                       right: 30,
//                       child: Container(
//                         width: 80,
//                         height: 80,
//                         decoration: BoxDecoration(
//                           color: Colors.white.withOpacity(0.8),
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: const Icon(Icons.wifi_tethering,
//                             color: Color(0xff1dc6b8), size: 40),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             // Instruction Text
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 24.0),
//               child: Text(
//                 "Tap on the back of the device with an NFC Compatible tag",
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                     color: Colors.cyanAccent.withOpacity(0.9),
//                     fontSize: 18,
//                     fontWeight: FontWeight.w500),
//               ),
//             ),
//             const SizedBox(height: 100),
//           ],
//         ),
//       ),
//     );
//   }
// }

