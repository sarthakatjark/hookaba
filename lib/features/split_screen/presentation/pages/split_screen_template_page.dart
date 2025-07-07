import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hookaba/core/common_widgets/primary_bottom_nav_bar.dart';
import 'package:hookaba/core/utils/app_fonts.dart';

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
                children: [
                  _TemplateCard(
                    label: 'Template 1',
                    onTap: () => context.go(
                        '/dashboard/split-screen/preview?templateIndex=0&ratio=0.5'),
                    template: _SplitTemplate.template1(),
                  ),
                  _TemplateCard(
                    label: 'Template 2',
                    onTap: () => context.go(
                        '/dashboard/split-screen/preview?templateIndex=1&ratio=0.25'),
                    template: _SplitTemplate.template2(),
                  ),
                  _TemplateCard(
                    label: 'Template 3',
                    onTap: () => context.go(
                        '/dashboard/split-screen/preview?templateIndex=2&ratio=0.75'),
                    template: _SplitTemplate.template3(),
                  ),
                  _TemplateCard(
                    label: 'Custom Template',
                    onTap: () => context
                        .go('/dashboard/split-screen/preview?templateIndex=3'),
                    template: _SplitTemplate.custom(),
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

class _SplitTemplate {
  final List<Rect> sections;

  const _SplitTemplate({
    required this.sections,
  });

  factory _SplitTemplate.template1() {
    return const _SplitTemplate(
      sections: [
        Rect.fromLTRB(0, 0, 1, 0.2),
        Rect.fromLTRB(0, 0.5, 1, 1),
        
      ],
    );
  }

  factory _SplitTemplate.template2() {
    return const _SplitTemplate(
      sections: [
        Rect.fromLTRB(0, 0, 1, 0.5),
        //Rect.fromLTRB(0, 0.5, 1, 0.75),
        Rect.fromLTRB(0, 0.75, 1, 1),
      ],
    );
  }

  factory _SplitTemplate.template3() {
    return const _SplitTemplate(
      sections: [
        Rect.fromLTRB(0, 0, 1, 0.5),
        Rect.fromLTRB(0, 0.5, 1, 1),
      ],
    );
  }

  factory _SplitTemplate.custom() {
    return const _SplitTemplate(
      sections: [
        Rect.fromLTRB(0, 0, 1, 1),
      ],
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final _SplitTemplate template;

  const _TemplateCard({
    required this.label,
    required this.onTap,
    required this.template,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF112244),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Stack(
                  children: template.sections.map((section) {
                    return Align(
                      alignment: Alignment(
                        -1.0 +
                            section.left * 2 +
                            (section.right - section.left),
                        -1.0 + section.top * 2 + (section.bottom - section.top),
                      ),
                      child: FractionallySizedBox(
                        widthFactor: section.right - section.left,
                        heightFactor: section.bottom - section.top,
                        alignment: Alignment.topLeft,
                        child: DottedBorder(
                          options: RoundedRectDottedBorderOptions(
                            color: Colors.white.withOpacity(0.3),
                            strokeWidth: 1,
                            radius: const Radius.circular(8),
                            dashPattern: [5, 5],
                          ),
                          child: Container(),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                label,
                style:
                    AppFonts.audiowideStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
