import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_provider.dart';
import '../models/table_model.dart';
import '../theme/app_theme.dart';
import 'table_dialogs.dart';

class TableManagementView extends ConsumerWidget {
  const TableManagementView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminState = ref.watch(adminProvider);
    final tables = adminState.allTables;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Manage Tables',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: () => showTableDialog(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('ADD TABLE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (adminState.isLoading) ...[
          const Center(child: CircularProgressIndicator()),
        ] else if (adminState.error != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  'Error: ${adminState.error}',
                  style: const TextStyle(color: AppColors.textBody),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed:
                      () => ref.read(adminProvider.notifier).fetchAllTables(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ] else if (tables.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'No tables found',
                  style: TextStyle(color: AppColors.textBody),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed:
                      () => ref.read(adminProvider.notifier).fetchAllTables(),
                  child: const Text('Reload'),
                ),
              ],
            ),
          ),
        ] else ...[
          ...tables.map((table) => _TableSettingsCard(table: table, ref: ref)),
        ],
      ],
    );
  }
}

class _TableSettingsCard extends StatelessWidget {
  final TableModel table;
  final WidgetRef ref;

  const _TableSettingsCard({required this.table, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color:
              table.isActive
                  ? Colors.transparent
                  : AppColors.error.withOpacity(0.3),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Text(
              table.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            if (!table.isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
                child: const Text(
                  'DISABLED',
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Games: ${table.supportedTypes.join(', ')} • ₹${table.hourlyRate.toInt()}/hr',
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
          onPressed: () => showTableDialog(context, ref, table: table),
        ),
      ),
    );
  }
}
