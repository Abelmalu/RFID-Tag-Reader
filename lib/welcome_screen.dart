// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// //import 'main.dart';
// import 'start_scanning.dart';

// // Import your custom colors from main.dart
// const Color kDarkBackgroundColor = Color(0xFF1A2B3C);
// const Color kPrimaryAccentColor = Color(0xFF00C6AE);
// const Color kLightTextColor = Colors.white;
// const Color kSecondaryTextColor = Colors.white70;

// class RegistrationScreen extends StatelessWidget {
//   const RegistrationScreen({Key? key}) : super(key: key);

//   // Key used to store the registration status in SharedPreferences
//   static const String _kIsRegistered = 'is_device_registered';

//   Future<void> _registerDevice(BuildContext context) async {
//     // 1. Simulate API call or registration process (can be expanded later)
//     await Future.delayed(const Duration(milliseconds: 800)); // Simulate loading

//     // 2. Save the registration status persistently
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool(_kIsRegistered, true);

//     // 3. Navigate to the main application screen
//     if (context.mounted) {
//       Navigator.of(context).pushReplacement(
//         MaterialPageRoute(
//           builder: (context) => const DeviceRegistrationScreen(),
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: kDarkBackgroundColor,
//       body: Padding(
//         padding: const EdgeInsets.all(32.0),
//         child: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(
//                 Icons.security_rounded,
//                 size: 100,
//                 color: kPrimaryAccentColor,
//               ),
//               const SizedBox(height: 30),
//               const Text(
//                 'Register Device for Cafeteria Access',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   color: kLightTextColor,
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 15),
//               const Text(
//                 'This device must be registered once before accessing the scanning features.',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(color: kSecondaryTextColor, fontSize: 16),
//               ),
//               const SizedBox(height: 40),
//               ElevatedButton.icon(
//                 onPressed: () => _registerDevice(context),
//                 icon: const Icon(Icons.send_rounded, size: 24),
//                 label: const Padding(
//                   padding: EdgeInsets.symmetric(
//                     vertical: 12.0,
//                     horizontal: 16.0,
//                   ),
//                   child: Text(
//                     'Register Device',
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//                 ),
//                 style: ElevatedButton.styleFrom(
//                   foregroundColor: kDarkBackgroundColor,
//                   backgroundColor: kPrimaryAccentColor,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   elevation: 8,
//                   shadowColor: kPrimaryAccentColor.withOpacity(0.5),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // Dummy HomeScreen import needed for navigation in this file
// // (In main.dart, we'll use the actual HomeScreen)
