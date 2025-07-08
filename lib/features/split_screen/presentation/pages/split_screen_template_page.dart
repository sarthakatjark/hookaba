import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hookaba/core/common_widgets/primary_bottom_nav_bar.dart';
import 'package:hookaba/core/utils/app_fonts.dart';

import '../widgets/split_template.dart';

class SplitScreenPage extends StatelessWidget {
  const SplitScreenPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF081122),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        title: Text(
          'SPLIT SCREEN',
          style: AppFonts.dashHorizonStyle(
              fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose a format to split the LED screens in few sections.',
              style:
                  AppFonts.audiowideStyle(color: Colors.white70, fontSize: 15),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 0.8,
                children: [
                  TemplateCard(
                    label: 'Template 1',
                    onTap: () => context.go(
                        '/dashboard/split-screen/preview?templateIndex=0&ratio=0.5'),
                    template: SplitTemplate.template1(),
                  ),
                  TemplateCard(
                    label: 'Template 2',
                    onTap: () => context.go(
                        '/dashboard/split-screen/preview?templateIndex=1&ratio=0.25'),
                    template: SplitTemplate.template2(),
                  ),
                  TemplateCard(
                    label: 'Template 3',
                    onTap: () => context.go(
                        '/dashboard/split-screen/preview?templateIndex=2&ratio=0.75'),
                    template: SplitTemplate.template3(),
                  ),
                  TemplateCard(
                    label: 'Custom Template',
                    onTap: () => context
                        .go('/dashboard/split-screen/preview?templateIndex=3'),
                    template: SplitTemplate.custom(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: PrimaryBottomNavBar(
        currentIndex: 0,
        onTap: (_) {},
      ),
    );
  }
}
