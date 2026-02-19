import 'package:flutter/material.dart';

class VerifiedBadge extends StatelessWidget {
  final double size;
  final Color? color;

  const VerifiedBadge({super.key, this.size = 16.0, this.color});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Verified User',
      child: Padding(
        padding: const EdgeInsets.only(left: 4.0),
        child: Icon(
          Icons.verified,
          color: color ?? Colors.blue,
          size: size,
        ),
      ),
    );
  }
}
