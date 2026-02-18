import 'package:flutter/material.dart';

/// Shipper profile screen - shows details about a specific shipper.
/// Full implementation in Phase 10 (Step 33).
class ShipperProfileScreen extends StatelessWidget {
  final String shipperId;

  const ShipperProfileScreen({super.key, required this.shipperId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Shipper Profile'),
      ),
      body: Center(
        child: Text('Shipper Profile: $shipperId\n\nComing soon'),
      ),
    );
  }
}
