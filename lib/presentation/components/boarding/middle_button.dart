import 'package:flutter/material.dart';

class MiddleButton extends StatelessWidget {
  final String label;
  final double fontSize;
  final Size minimumSize;
  final double iconSize;
  final VoidCallback onPressed;
  final Color backgroundColor;

  const MiddleButton({
    super.key,
    required this.label,
    this.fontSize = 20,
    this.minimumSize = const Size(150, 75),
    this.iconSize = 25,
    required this.onPressed,
    this.backgroundColor = Colors.black87,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(Icons.add, size: iconSize),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: minimumSize,
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      label: Text(label, style: TextStyle(fontSize: fontSize)),
    );
  }
}
