import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:hookaba/core/utils/app_fonts.dart' show AppFonts;

class SplitTemplate {
  final List<Rect> sections;

  const SplitTemplate({
    required this.sections,
  });

  factory SplitTemplate.template2() {
    return const SplitTemplate(
      sections: [
        Rect.fromLTRB(0, 0, 1, 0.2),
        Rect.fromLTRB(0, 0.5, 1, 1),
      ],
    );
  }

  factory SplitTemplate.template3() {
    return const SplitTemplate(
      sections: [
        Rect.fromLTRB(0, 0, 1, 0.5),
        //Rect.fromLTRB(0, 0.5, 1, 0.75),
        Rect.fromLTRB(0, 0.75, 1, 1),
      ],
    );
  }

  factory SplitTemplate.template1() {
    return const SplitTemplate(
      sections: [
        Rect.fromLTRB(0, 0.5, 1, 0.5), // Top half
        Rect.fromLTRB(0, 0.0, 1, 1), // Bottom half
      ],
    );
  }

  factory SplitTemplate.custom() {
    return const SplitTemplate(
      sections: [
        Rect.fromLTRB(0, 0, 1, 1),
      ],
    );
  }
}

class TemplateCard extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final SplitTemplate template;

  const TemplateCard({
    super.key,
    required this.label,
    required this.onTap,
    required this.template,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF112244),
                borderRadius: BorderRadius.circular(16),
              ),
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
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              label,
              style: AppFonts.audiowideStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
