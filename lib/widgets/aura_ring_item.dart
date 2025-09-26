import 'package:flutter/material.dart';
import 'package:bharatconnect/models/aura_models.dart' as aura_models; // Alias aura_models
import 'package:google_fonts/google_fonts.dart'; // Import google_fonts

class AuraRingItem extends StatefulWidget {
  final aura_models.AuraUser user; // Use AuraUser
  final aura_models.DisplayAura? activeAura; // Use DisplayAura and make nullable
  final bool isCurrentUser;
  final VoidCallback onClick;

  const AuraRingItem({
    super.key,
    required this.user,
    this.activeAura,
    this.isCurrentUser = false,
    required this.onClick,
  });

  @override
  State<AuraRingItem> createState() => _AuraRingItemState();
}

class _AuraRingItemState extends State<AuraRingItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10), // Adjust speed as needed
    )..repeat(); // Repeat the animation indefinitely
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasActiveAura = widget.activeAura != null; // This condition is correct
    final Color primaryColor = hasActiveAura && widget.activeAura!.auraStyle != null ? widget.activeAura!.auraStyle!.primaryColor : Colors.grey;
    final Color secondaryColor = hasActiveAura && widget.activeAura!.auraStyle != null ? widget.activeAura!.auraStyle!.secondaryColor : Colors.grey.shade700;

    print('AuraRingItem: Building for user ${widget.user.name}');
    print('AuraRingItem: hasActiveAura: $hasActiveAura');
    if (hasActiveAura) {
      print('AuraRingItem: Active Aura ID: ${widget.activeAura!.id}');
      print('AuraRingItem: Aura Style: ${widget.activeAura!.auraStyle?.name}');
      print('AuraRingItem: Aura Icon URL: ${widget.activeAura!.auraStyle?.iconUrl}');
    }

    return GestureDetector(
      onTap: () {
        print('AuraRingItem: onClick triggered for ${widget.user.name}');
        widget.onClick();
      },
      child: SizedBox(
        width: 80, // Increased width
        height: 100, // Increased height to provide more buffer
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none, // Allow overflow (like z-index)
              alignment: Alignment.center,
              children: [
                if (hasActiveAura) // Show aura ring if active
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      print('AuraRingItem: Rendering AnimatedBuilder for gradient ring.');
                      return Transform.rotate(
                        angle: _controller.value * 2 * 3.141592653589793, // 2 * PI for a full circle
                        child: Container(
                          width: 78, // Slightly larger than avatar
                          height: 78,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                primaryColor,
                                secondaryColor,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                CircleAvatar(
                  radius: 35, // Increased radius
                  backgroundColor: hasActiveAura ? Theme.of(context).cardColor : Colors.grey.shade800, // Background color based on active aura
                  backgroundImage: widget.user.avatarUrl != null && widget.user.avatarUrl!.isNotEmpty
                      ? NetworkImage(widget.user.avatarUrl!)
                      : null,
                  child: widget.user.avatarUrl == null || widget.user.avatarUrl!.isEmpty
                      ? Icon(Icons.person, size: 35, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)) // Increased icon size
                      : null,
                ),
                if (widget.isCurrentUser && !hasActiveAura) // Show + icon only for current user if no active aura
                  Positioned(
                    bottom: -6, // Keep overlap
                    left: 0, // Centered horizontally
                    right: 0, // Centered horizontally
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400, // Changed to light gray background
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade600, width: 1.0), // Darker gray border
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 3,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.add, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                if (hasActiveAura && widget.activeAura!.auraStyle!.iconUrl.isNotEmpty) // Show aura icon if active
                  Positioned(
                    bottom: -6, // Position at bottom-center
                    left: 0, // Centered horizontally
                    right: 0, // Centered horizontally
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        padding: const EdgeInsets.all(3), // Slightly increased padding for better visual
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor, // Solid background color for the icon overlay
                          shape: BoxShape.circle,
                          border: Border.all(color: primaryColor, width: 1.5), // Border color from aura
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 3,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Image.asset(widget.activeAura!.auraStyle!.iconUrl, width: 18, height: 18), // Increased aura icon size
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              widget.isCurrentUser ? 'Your Aura' : widget.user.name, // Updated text
              style: GoogleFonts.playfairDisplay(
                fontSize: 13, // Increased font size
                color: Theme.of(context).colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}