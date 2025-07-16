import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hookaba/core/common_widgets/primary_button.dart';
import 'package:hookaba/core/common_widgets/primary_snackbar.dart';
import 'package:hookaba/core/common_widgets/primary_text_field.dart';
import 'package:hookaba/core/utils/app_fonts.dart';

class EditProgramNameSheet extends HookWidget {
  final String initialName;
  final ValueChanged<String> onSave;

  const EditProgramNameSheet({super.key, required this.initialName, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController(text: initialName);
    final loading = useState(false);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit Program Name', style: AppFonts.dashHorizonStyle(fontSize: 18, color: Colors.white)),
            const SizedBox(height: 16),
            PrimaryTextField(
              controller: controller,
              hintText: 'Program Name',
              maxLength: 32,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'Save',
              loading: loading.value,
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isEmpty) {
                  showPrimarySnackbar(context, 'Name cannot be empty', colorTint: Colors.red, icon: Icons.error);
                  return;
                }
                loading.value = true;
                await Future.delayed(const Duration(milliseconds: 200));
                onSave(newName);
                loading.value = false;
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
} 