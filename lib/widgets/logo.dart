import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import google_fonts

class Logo extends StatelessWidget {
  final String size; // Can be 'small' or 'large'

  const Logo({super.key, this.size = 'medium'});

  @override
  Widget build(BuildContext context) {
    double fontSize;
    switch (size) {
      case 'small':
        fontSize = 24;
        break;
      case 'large':
        fontSize = 36;
        break;
      case 'medium':
      default:
        fontSize = 30;
        break;
    }

    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [
          Color(0xFF42A5F5), // Primary Blue
          Color(0xFFAB47BC), // Accent Violet
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Text(
        'BharatConnect',
        style: GoogleFonts.playfairDisplay( // Using Playfair Display from Google Fonts
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white, // This color will be masked by the gradient
        ),
      ),
    );
  }
}
