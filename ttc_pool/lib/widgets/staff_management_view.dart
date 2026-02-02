import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_provider.dart';
import '../theme/app_theme.dart';

class StaffManagementView extends ConsumerWidget {
  const StaffManagementView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminState = ref.watch(adminProvider);
    final staffList = adminState.staffList;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Manage Staff',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: () => _showStaffDialog(context, ref),
              icon: const Icon(Icons.person_add_outlined, size: 18),
              label: const Text('ADD STAFF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
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
                      () => ref.read(adminProvider.notifier).fetchStaff(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ] else if (staffList.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'No staff found',
                  style: TextStyle(color: AppColors.textBody),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed:
                      () => ref.read(adminProvider.notifier).fetchStaff(),
                  child: const Text('Reload'),
                ),
              ],
            ),
          ),
        ] else ...[
          ...staffList.map((staff) => _StaffCard(staff: staff, ref: ref)),
        ],
      ],
    );
  }
}

void _showStaffDialog(
  BuildContext context,
  WidgetRef ref, {
  Map<String, dynamic>? staff,
}) {
  final nameController = TextEditingController(text: staff?['username']);
  final mobileController = TextEditingController(text: staff?['mobile']);
  final passController = TextEditingController();
  String role = staff?['role'] ?? 'Staff';
  bool isActive = staff?['isActive'] ?? true;

  showDialog(
    context: context,
    builder:
        (context) => StatefulBuilder(
          builder:
              (context, setState) => AlertDialog(
                title: Text(staff == null ? 'Add New Staff' : 'Edit Staff'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                        ),
                        enabled: staff == null, // Username usually fixed
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: mobileController,
                        decoration: const InputDecoration(
                          labelText: 'Mobile Number',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passController,
                        decoration: InputDecoration(
                          labelText:
                              staff == null
                                  ? 'Password'
                                  : 'New Password (Optional)',
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 24),
                      DropdownButtonFormField<String>(
                        value: role,
                        decoration: const InputDecoration(labelText: 'Role'),
                        items:
                            ['Admin', 'Staff']
                                .map(
                                  (r) => DropdownMenuItem(
                                    value: r,
                                    child: Text(r),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) => setState(() => role = val!),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Active Status'),
                        value: isActive,
                        onChanged: (val) => setState(() => isActive = val),
                        activeColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final data = {
                        'username': nameController.text,
                        'mobile': mobileController.text,
                        'role': role,
                        'isActive': isActive,
                      };
                      if (passController.text.isNotEmpty) {
                        data['password'] = passController.text;
                      }

                      bool success = false;
                      if (staff == null) {
                        success = await ref
                            .read(adminProvider.notifier)
                            .addStaff(data);
                      } else {
                        success = await ref
                            .read(adminProvider.notifier)
                            .updateStaff(staff['_id'], data);
                      }

                      if (success && context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              staff == null
                                  ? 'Staff Member Added!'
                                  : 'Staff Member Updated!',
                            ),
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

class _StaffCard extends StatelessWidget {
  final Map<String, dynamic> staff;
  final WidgetRef ref;

  const _StaffCard({required this.staff, required this.ref});

  @override
  Widget build(BuildContext context) {
    bool active = staff['isActive'] ?? true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: active ? Colors.transparent : AppColors.error.withOpacity(0.3),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor:
              active ? AppColors.primary : AppColors.textBody.withOpacity(0.2),
          child: Text(
            (staff['username'] as String)[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              staff['username'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color:
                    staff['role'] == 'Admin'
                        ? AppColors.accent.withOpacity(0.1)
                        : AppColors.textBody.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                staff['role'].toUpperCase(),
                style: TextStyle(
                  fontSize: 8,
                  color:
                      staff['role'] == 'Admin'
                          ? AppColors.accent
                          : AppColors.textBody,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(staff['mobile'] ?? 'No mobile'),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
          onPressed: () => _showStaffDialog(context, ref, staff: staff),
        ),
      ),
    );
  }
}
