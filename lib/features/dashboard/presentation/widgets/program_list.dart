import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hookaba/core/extensions/responsive_ext.dart';
import 'package:hookaba/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:hookaba/features/dashboard/presentation/widgets/program_card.dart' show ProgramCard;

class ProgramList extends StatelessWidget {
  const ProgramList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        final programs = state.localPrograms;
        if (programs.isEmpty) {
          return const Center(
            child: Text(
              'No programs found.',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          );
        }
        final isMobile = context.isMobile;
        final crossAxisCount = isMobile ? 2 : 4;
        final childAspectRatio = isMobile ? 2.2 : 3.5;
        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: programs.length > 4 ? 4 : programs.length,
          itemBuilder: (context, index) {
            final program = programs[index];
            return GestureDetector(
              onTap: () {
                GoRouter.of(context).push('/dashboard/programs');
              },
              child: ProgramCard(
                title: program.name,
                imageBytes: program.bmpBytes,
                gifBase64: program.gifBase64,
              ),
            );
          },
        );
      },
    );
  }
} 