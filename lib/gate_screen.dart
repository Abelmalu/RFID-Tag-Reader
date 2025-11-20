import 'package:flutter/material.dart';

// Constants
const Color kPrimaryAccentColor = Color(0xFF00C6AE);
const Color kLightTextColor = Colors.white;
const Color kAppBarTopColor = Color(0xFF15222E);

class GateScreen extends StatelessWidget {
  const GateScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gate Scan Mode'),
        backgroundColor: kAppBarTopColor,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.sensor_door_rounded,
              size: 80,
              color: kPrimaryAccentColor,
            ),
            const SizedBox(height: 20),
            const Text(
              'Gate Mode Active',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: kLightTextColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Placeholder for user check-in/out logic.',
              style: TextStyle(
                fontSize: 16,
                color: kLightTextColor.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
