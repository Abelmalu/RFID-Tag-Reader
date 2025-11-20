import 'package:flutter/material.dart';
import 'serial_number_auth.dart';
import 'home_screen.dart';
import 'device_service.dart';

// --- Global Constants ---
const Color kDarkBackgroundColor = Color(0xFF1A2B3C);
const Color kPrimaryAccentColor = Color(0xFF00C6AE);
const Color kLightTextColor = Colors.white;
const Color kAppBarTopColor = Color(0xFF15222E);
// ------------------------

void main() {
  // Must initialize widgets binding before accessing SharedPreferences
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Device Kiosk App',
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
        useMaterial3: true,
      ),
      // AppInitializationWrapper is the root widget deciding the first screen
      home: const AppInitializationWrapper(),
    );
  }
}

// Step 2: Main app startup flow
class AppInitializationWrapper extends StatelessWidget {
  const AppInitializationWrapper({super.key});

  Future<Widget> _getInitialScreen() async {
    // Load SharedPreferences and Check if registered == true
    final bool registered = await DeviceService.isRegistered();

    if (registered) {
      // If yes -> go directly to HomeScreen
      return const HomeScreen();
    } else {
      // If no -> go to SerialNumberAuthScreen
      return const SerialNumberAuthScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _getInitialScreen(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show a simple loading screen while checking local storage
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: kPrimaryAccentColor),
            ),
          );
        }

        // Return the determined screen
        return snapshot.data ?? const SerialNumberAuthScreen();
      },
    );
  }
}
