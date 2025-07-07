import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hookaba/core/common_widgets/primary_button.dart';
import 'package:hookaba/core/utils/app_fonts.dart';

class SplitScreen extends StatelessWidget {
  const SplitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1A33),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 1,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      'A',
                      style: AppFonts.audiowideStyle(
                        color: Colors.white,
                        fontSize: 32,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: Container(
                  height: 100,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: GridView.count(
                      crossAxisCount: 2,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      mainAxisSpacing: 0,
                      crossAxisSpacing: 0,
                      childAspectRatio: 1.6,
                      children: [
                        // Top-left: Gradient
                        Container(
                          
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                            ),
                            gradient: LinearGradient(
                              colors: [Colors.orange, Colors.purple, Colors.blue],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                        // Top-right: Black
                        Container(
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(16),
                            ),
                            color: Colors.black,
                          ),
                        ),
                        // Bottom-left: Black
                        Container(
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                            ),
                            color: Colors.black,
                          ),
                        ),
                        // Bottom-right: Gradient
                        Container(
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.only(
                              bottomRight: Radius.circular(16),
                            ),
                            gradient: LinearGradient(
                              colors: [Colors.yellow, Colors.purple, Colors.blue],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            width: 160,
            child: PrimaryButton(
              onPressed: () => context.push('/dashboard/split-screen'),
              text: 'Explore',
            ),
          ),
        ],
      ),
    );
  }
}
