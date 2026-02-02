import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PauseReasonModal extends StatefulWidget {
  const PauseReasonModal({super.key});

  @override
  State<PauseReasonModal> createState() => _PauseReasonModalState();
}

class _PauseReasonModalState extends State<PauseReasonModal> {
  final _reasonController = TextEditingController();
  final List<String> _quickReasons = ['Staff Break', 'Maintenance', 'Customer Request', 'Power Outage'];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pause Session',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textHeading),
          ),
          const SizedBox(height: 8),
          const Text(
            'Provide a reason to pause the timer. This will be logged.',
            style: TextStyle(color: AppColors.textBody, fontSize: 13),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickReasons.map((reason) {
              return ActionChip(
                label: Text(reason),
                onPressed: () => setState(() => _reasonController.text = reason),
                backgroundColor: AppColors.surface,
                labelStyle: const TextStyle(color: AppColors.textBody),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(
              hintText: 'Enter custom reason...',
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              if (_reasonController.text.trim().isNotEmpty) {
                Navigator.pop(context, _reasonController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('CONFIRM PAUSE'),
          ),
        ],
      ),
    );
  }
}
