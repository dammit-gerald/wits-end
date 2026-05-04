import 'package:flutter/material.dart';
import '../../core/models/models.dart';

class TacticalButton extends StatelessWidget {
  final String labelKey;
  final String fallback;
  final VoidCallback? onPressed;
  final Persona persona;
  final Color? color;
  final bool fullWidth;

  const TacticalButton({
    super.key,
    required this.labelKey,
    required this.fallback,
    required this.onPressed,
    required this.persona,
    this.color,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? Colors.greenAccent,
        minimumSize: fullWidth ? const Size(double.infinity, 56) : const Size(120, 48),
      ),
      child: Text(
        persona.getLabel(labelKey, fallback).toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );

    if (fullWidth) return button;
    return Center(child: button);
  }
}
