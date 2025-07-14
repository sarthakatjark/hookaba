import 'package:flutter/material.dart';

class ProfileAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text('Profile'),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
} 