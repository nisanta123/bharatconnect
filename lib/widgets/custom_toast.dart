import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomToast extends StatefulWidget {
  final String message;
  final bool isError;

  const CustomToast({
    super.key,
    required this.message,
    this.isError = false,
  });

  @override
  State<CustomToast> createState() => _CustomToastState();
}

class _CustomToastState extends State<CustomToast> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation; // Added for fade animation

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.5), // Starts slightly below center
      end: Offset.zero, // Ends at its normal position
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(
      begin: 0.0, // Starts fully transparent
      end: 1.0, // Ends fully opaque
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) {
            // No need to dispose of the overlay entry here, it's handled by showCustomToast
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition( // Added FadeTransition
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Material(
          color: Colors.transparent,
          child: Center( // Center the toast horizontally and vertically
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40.0), // Add horizontal margin
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0), // More rounded corners
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF42A5F5).withOpacity(0.5), // Primary Blue with 50% opacity
                    const Color(0xFFAB47BC).withOpacity(0.5), // Accent Violet with 50% opacity
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    spreadRadius: 3,
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text( // Removed ShaderMask, text color is now solid
                widget.message,
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white, // Solid white text color
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void showCustomToast(BuildContext context, String message, {bool isError = false}) {
  final overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.of(context).size.height * 0.5 - 50, // Center vertically, adjust -50 for half of toast height
      left: 0,
      right: 0,
      child: CustomToast(message: message, isError: isError),
    ),
  );

  Overlay.of(context).insert(overlayEntry);

  Future.delayed(const Duration(seconds: 3), () {
    if (overlayEntry.mounted) {
      overlayEntry.remove();
    }
  });
}
