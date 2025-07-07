import 'package:flutter/material.dart';

class PermissionDeniedDialog extends StatelessWidget {
  final bool permanentlyDenied;
  final VoidCallback onSettings;
  final VoidCallback onCancel;

  const PermissionDeniedDialog({
    Key? key,
    required this.permanentlyDenied,
    required this.onSettings,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bluetooth Permission'),
      content: Text(permanentlyDenied
          ? 'Bluetooth permission has been permanently denied. Please enable it from Settings.'
          : 'Bluetooth permission is required to search for devices. Would you like to open Settings and grant it?'),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: onSettings,
          child: const Text('Settings'),
        ),
      ],
    );
  }
} 