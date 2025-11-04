import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(home: NfcReaderScreen()));
}

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
          onPressed: () {
            // Add navigation logic if needed
          },
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
                const SizedBox(height: 80),
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








// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:nfc_manager/nfc_manager.dart';
// import 'package:nfc_manager/nfc_manager_android.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'NFC/RFID Reader',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//       ),
//       home: const MyHomePage(title: ' Home Screen'),
//     );
//   }
// }

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});

//   final String title;

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   int _counter = 0;
//   String tagInfo = 'Scan an NFC tag';

//   String _bytesToHexString(Uint8List bytes) {
//     if (bytes.isEmpty) return 'N/A';
//     return bytes
//         .map((e) => e.toRadixString(16).padLeft(2, '0'))
//         .join(':')
//         .toUpperCase();
//   }

//   void _incrementCounter() async {
//     final hellow = "hellow ";
//     print(hellow);

//     // Check the availability of NFC on the current device.

//     // Start the session.
//     NfcManager.instance.startSession(
//       pollingOptions: {
//         NfcPollingOption.iso14443,
//         NfcPollingOption.iso15693,
//         NfcPollingOption.iso18092,
//       }, // ISO standard cards
//       onDiscovered: (NfcTag tag) async {
//         print("this is the data");

//         final MifareClassicAndroid? mifareClassicCard =
//             MifareClassicAndroid.from(tag);
//         print("the raw id ");
//         print(mifareClassicCard?.tag.id);
//         print("the  id as UINT8lIST ");
//         final rawUidBytes = mifareClassicCard?.tag.id as Uint8List;
//         print("this is the id changed to hexadecimal");
//         final tagUid = _bytesToHexString(rawUidBytes);
//         print(tagUid);
//         print(mifareClassicCard?.size);

//         // Stop the session when no longer needed.
//         await NfcManager.instance.stopSession();
//       },
//     );

//     setState(() {
//       _counter++;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,

//         title: Text(widget.title),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             const Text('You have pushed the button this many times:'),
//             Text(
//               '$_counter',
//               style: Theme.of(context).textTheme.headlineMedium,
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _incrementCounter,
//         tooltip: 'Increment',
//         child: const Icon(Icons.add),
//       ), // This trailing comma makes auto-formatting nicer for build methods.
//     );
//   }
// }

