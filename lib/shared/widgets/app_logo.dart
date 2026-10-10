// Logo resmi Les Jogoloyo dari assets/logo.png.
// Dipakai di splash, onboarding, setup, header, dan avatar fallback.
// Latar putih agar menyatu dengan ikon launcher.
import 'package:flutter/material.dart';
import '../../app/theme.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final double radius;
  const AppLogo({super.key, this.size = 96, this.radius = 24});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: JogloColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset('assets/logo.png', fit: BoxFit.cover),
    );
  }
}
