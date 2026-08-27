import 'package:flutter/material.dart';
import '../main.dart';

// The app mark — a dark rounded square with an orange capsule cut across it
// at an angle. Matches the web app's logo exactly.
class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.28),
      child: Container(
        width: size,
        height: size,
        color: const Color(0xFF2C2C2A),
        child: Center(
          child: Transform.rotate(
            angle: -0.52, // -30 degrees
            child: Container(
              width: size * 0.75,
              height: size * 0.32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(size),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
