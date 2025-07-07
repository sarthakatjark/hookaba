import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hookaba/core/common_widgets/primary_bottom_nav_bar.dart';
import 'package:hookaba/core/common_widgets/primary_button.dart';
import 'package:hookaba/core/utils/app_fonts.dart';
import 'package:hookaba/core/utils/enum.dart' show AnimationType;
import 'package:hookaba/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:hookaba/features/dashboard/presentation/widgets/animation_picker_modal.dart';
import 'package:hookaba/features/dashboard/presentation/widgets/color_picker_row.dart';
import 'package:hookaba/features/dashboard/presentation/widgets/settings_field.dart';

class TextEditorScreen extends HookWidget {
  const TextEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedColor = useState(Colors.black);
    final fontSize = useState(16.0);
    final text = useState('');
    final wordSpacing = useState(3.0);
    final lineSpacing = useState(1.0);
    final views = useState(3);
    final playTime = useState(1.0);
    final stayingTime = useState(1.0);
    //final isAnimated = useState(false);
    final selectedVerticalSpacing = useState(0);
    final selectedIndex = useState(0);
    final selectedAnimation = useState<AnimationType?>(null);

    return Scaffold(
      backgroundColor: const Color(0xFF081122),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'TEXT',
          style: AppFonts.dashHorizonStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF1A2942),
                  width: 1,
                ),
              ),
              child: TextField(
                onChanged: (value) => text.value = value,
                style: TextStyle(
                  color: selectedColor.value,
                  fontSize: fontSize.value,
                  height: lineSpacing.value,
                  wordSpacing: wordSpacing.value,
                ),
                maxLines: null,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Enter your text',
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text formatting toolbar
                  Row(
                    children: [
                      InkWell(
                        onTap: () {},
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.format_italic,
                            color: Colors.blue,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      InkWell(
                        onTap: () {},
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.format_bold,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      InkWell(
                        onTap: () {},
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.format_underline,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      InkWell(
                        onTap: () {},
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.link,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () {},
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.format_align_left,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {},
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.format_align_center,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {},
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.format_align_right,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Font size slider
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Font size',
                        style: AppFonts.audiowideStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: SliderTheme(
                              data: SliderThemeData(
                                activeTrackColor: Colors.blue,
                                inactiveTrackColor: Colors.blue.withOpacity(0.3),
                                thumbColor: Colors.white,
                                overlayColor: Colors.blue.withOpacity(0.1),
                                trackHeight: 4,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 16),
                              ),
                              child: Slider(
                                value: fontSize.value,
                                min: 12,
                                max: 48,
                                onChanged: (value) => fontSize.value = value,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            width: 35,
                            height: 35,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              border: Border.all(
                                color: const Color(0xFF1E5AFF),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${fontSize.value.toInt()}',
                              style: AppFonts.audiowideStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Text color
                  ColorPickerRow(
                    label: 'Text Color',
                    colors: const [
                      Colors.black,
                      Colors.blue,
                      Colors.green,
                      Colors.yellow,
                      Colors.red,
                      Colors.purple,
                      Colors.white,
                    ],
                    selectedColor: selectedColor.value,
                    onColorSelected: (color) => selectedColor.value = color,
                    onAddColor: () {/* Handle add color */},
                    colorSize: 24,
                    spacing: 16,
                    showLabel: true,
                    showSelectedIndicator: false,
                  ),
                  const SizedBox(height: 24),
                  // Vertical spacing
                  Row(
                    children: [
                      Text('Vertical Spacing',
                          style: AppFonts.audiowideStyle(
                            color: Colors.white,
                            fontSize: 14,
                            
                          )),
                      const Spacer(),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => selectedVerticalSpacing.value = 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: selectedVerticalSpacing.value == 0
                                    ? Colors.blue
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(Icons.format_line_spacing,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => selectedVerticalSpacing.value = 1,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: selectedVerticalSpacing.value == 1
                                    ? Colors.blue
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(Icons.format_line_spacing,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () => selectedVerticalSpacing.value = 2,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: selectedVerticalSpacing.value == 2
                                    ? Colors.blue
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(Icons.format_line_spacing,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  
                  // Spacing controls
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SettingsField(
                              label: 'Word Spacing',
                              value: wordSpacing.value,
                              onChanged: (v) => wordSpacing.value = v,
                              min: 0.0,
                              max: 10.0,
                              step: 0.5,
                              decimals: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SettingsField(
                              label: 'Line Spacing',
                              value: lineSpacing.value,
                              onChanged: (v) => lineSpacing.value = v,
                              min: 1.0,
                              max: 3.0,
                              step: 0.1,
                              decimals: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Animation settings
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SettingsField(
                              label: 'Views',
                              value: views.value.toDouble(),
                              onChanged: (v) => views.value = v.toInt(),
                              min: 1,
                              max: 10,
                              step: 1,
                              decimals: 0,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SettingsField(
                              label: 'Play Time',
                              value: playTime.value,
                              onChanged: (v) => playTime.value = v,
                              min: 0.1,
                              max: 10.0,
                              step: 0.1,
                              decimals: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Staying time
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Animation card (left)
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final selected =
                                await showModalBottomSheet<AnimationType>(
                              context: context,
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              builder: (modalContext) => AnimationPickerModal(
                                onSelected: (animationType) {
                                  Navigator.of(modalContext).pop(animationType);
                                },
                              ),
                            );
                            if (selected != null) {
                              selectedAnimation.value = selected;
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF112233),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.tv,
                                    color: Colors.blue, size: 32),
                                const SizedBox(width: 12),
                                Text(
                                  'Animation',
                                  style: AppFonts.dashHorizonStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Staying Time controls (right)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SettingsField(
                              label: 'Staying Time',
                              value: stayingTime.value,
                              onChanged: (v) => stayingTime.value = v,
                              min: 0.1,
                              max: 10.0,
                              step: 0.1,
                              decimals: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                 
                  // SEND BUTTON
                  PrimaryButton(
                    text: 'Send to BLE',
                    onPressed: () async {
                      final cubit = context.read<DashboardCubit>();
                      int colorInt = cubit.colorToBleInt(selectedColor.value);
                      Map<String, dynamic>? infoAnimate = cubit
                          .animationTypeToInfoAnimate(selectedAnimation.value);
                      try {
                        await cubit.sendTextToBle(
                          text: text.value,
                          color: colorInt,
                          size: fontSize.value.toInt(),
                          bold: null, // Set to 1 for bold if needed
                          italic: null, // Set to 1 for italic if needed
                          spaceFont: wordSpacing.value.toInt(),
                          spaceLine: (lineSpacing.value * 10).toInt(),
                          alignHorizontal: "center", // Or get from UI
                          alignVertical: "center", // Or get from UI
                          infoAnimate: infoAnimate,
                          stayingTime: stayingTime.value,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Text sent to BLE display!')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to send: $e')),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: PrimaryBottomNavBar(
        currentIndex: selectedIndex.value,
        onTap: (index) => selectedIndex.value = index,
      ),
    );
  }
}
