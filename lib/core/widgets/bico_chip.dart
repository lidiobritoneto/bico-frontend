import 'package:flutter/material.dart';

class BicoChip extends StatelessWidget {
  final String label;

  const BicoChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    );
  }
}