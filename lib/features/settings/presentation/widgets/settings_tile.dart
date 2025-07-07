import 'package:flutter/material.dart';

class SettingsTile extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final TextStyle? titleStyle;

  const SettingsTile({
    super.key,
    required this.title,
    this.trailing,
    this.onTap,
    this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: titleStyle ?? const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }
} 