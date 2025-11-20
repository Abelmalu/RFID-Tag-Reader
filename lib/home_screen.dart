import 'package:flutter/material.dart';
import 'cafeteria_screen.dart';
import 'gate_screen.dart';
import 'serial_number_auth.dart';
import 'device_service.dart';

// Constants
const Color kPrimaryAccentColor = Color(0xFF00C6AE);
const Color kDarkBackgroundColor = Color(0xFF1A2B3C);
const Color kAppBarTopColor = Color(0xFF15222E);
const Color kLightTextColor = Colors.white;

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  // Example of a function to force re-registration
  Future<void> _handleDeviceReset(BuildContext context) async {
    // Clear the stored state, forcing the auth screen on next launch
    await DeviceService.clearRegistrationData();

    // Step 5: Navigate replace to SerialNumberAuthScreen
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SerialNumberAuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Screen (Select Mode)'),
        backgroundColor: kAppBarTopColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Deactivate Device',
            onPressed: () => _handleDeviceReset(context),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.tablet_android_rounded,
                size: 100,
                color: kPrimaryAccentColor,
              ),
              const SizedBox(height: 30),
              Text(
                'Device Activated & Ready',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: kLightTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),

              _buildModeButton(
                context,
                title: 'Cafeteria Scan',
                subtitle: 'Navigate to the food transaction processing.',
                icon: Icons.restaurant_menu_rounded,
                destination: const CafeteriaScreen(),
              ),
              const SizedBox(height: 20),
              _buildModeButton(
                context,
                title: 'Gate Scan',
                subtitle: 'Navigate to the entry/exit check-in module.',
                icon: Icons.sensor_door_rounded,
                destination: const GateScreen(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget destination,
  }) {
    return Card(
      color: kAppBarTopColor.withOpacity(0.8),
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: kPrimaryAccentColor, width: 1.5),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: kPrimaryAccentColor),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kLightTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: kPrimaryAccentColor,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
