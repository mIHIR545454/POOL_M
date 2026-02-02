import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/table_model.dart';
import '../providers/admin_provider.dart';
import '../theme/app_theme.dart';

void showTableDialog(BuildContext context, WidgetRef ref, {TableModel? table}) {
  final nameController = TextEditingController(text: table?.name);
  final rateController = TextEditingController(text: table?.hourlyRate.toString() ?? '200');
  List<String> supportedTypes = table?.supportedTypes != null ? List.from(table!.supportedTypes) : ['Pool'];
  bool isActive = table?.isActive ?? true;

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(table == null ? 'Add New Table' : 'Edit Table'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Table Name/Number'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: rateController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Hourly Rate (₹)'),
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Supported Games', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              CheckboxListTile(
                title: const Text('Pool'),
                value: supportedTypes.contains('Pool'),
                onChanged: (val) {
                  setState(() {
                    if (val!) {
                      supportedTypes.add('Pool');
                    } else if (supportedTypes.length > 1) {
                      supportedTypes.remove('Pool');
                    }
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Snooker'),
                value: supportedTypes.contains('Snooker'),
                onChanged: (val) {
                  setState(() {
                    if (val!) {
                      supportedTypes.add('Snooker');
                    } else if (supportedTypes.length > 1) {
                      supportedTypes.remove('Snooker');
                    }
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Is Active'),
                value: isActive,
                onChanged: (val) => setState(() => isActive = val),
                activeColor: AppColors.primary,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final data = {
                'name': nameController.text,
                'hourlyRate': double.tryParse(rateController.text) ?? 200,
                'supportedTypes': supportedTypes,
                'isActive': isActive,
              };

              bool success = false;
              if (table == null) {
                success = await ref.read(adminProvider.notifier).addTable(data);
              } else {
                success = await ref.read(adminProvider.notifier).updateTable(table.id, data);
              }

              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(table == null ? 'Table Added Successfully!' : 'Table Updated Successfully!'),
                    backgroundColor: AppColors.secondary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    ),
  );
}
