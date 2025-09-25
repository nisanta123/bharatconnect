import 'package:flutter/material.dart';
import 'package:bharatconnect/widgets/aura_ring_item.dart';

class AuraBar extends StatelessWidget {
  const AuraBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160.0, // Increased height for AuraBar
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          AuraRingItem(
            value: 70,
            label: 'Steps',
            color: Colors.blue,
          ),
          AuraRingItem(
            value: 85,
            label: 'Sleep',
            color: Colors.green,
          ),
          AuraRingItem(
            value: 50,
            label: 'Activity',
            color: Colors.orange,
          ),
          AuraRingItem(
            value: 90,
            label: 'Heart Rate',
            color: Colors.red,
          ),
        ],
      ),
    );
  }
}