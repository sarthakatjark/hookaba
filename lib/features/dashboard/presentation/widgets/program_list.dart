import 'package:flutter/material.dart';

import 'program_card.dart';

class ProgramList extends StatelessWidget {
  const ProgramList({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2,
      shrinkWrap: true,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: const [
        ProgramCard("Fire", Icons.local_fire_department, Colors.orange),
        ProgramCard("Abstract", Icons.texture, Colors.deepPurple),
        ProgramCard("Clock", Icons.access_time, Colors.yellow),
        ProgramCard("Clock", Icons.blur_circular, Colors.purple),
      ],
    );
  }
} 