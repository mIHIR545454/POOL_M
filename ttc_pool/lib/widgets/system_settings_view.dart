import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_provider.dart';
import '../theme/app_theme.dart';

class SystemSettingsView extends ConsumerStatefulWidget {
  const SystemSettingsView({super.key});

  @override
  ConsumerState<SystemSettingsView> createState() => _SystemSettingsViewState();
}

class _SystemSettingsViewState extends ConsumerState<SystemSettingsView> {
  final _businessNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _gstinController = TextEditingController();
  final _logoutDurationController = TextEditingController();
  final _currencyController = TextEditingController();
  
  bool _taxEnabled = true;
  bool _autoEnd = false;

  @override
  void dispose() {
    _businessNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _gstinController.dispose();
    _logoutDurationController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(adminProvider).settings;
    if (settings == null) return const Center(child: CircularProgressIndicator());

    // Initialize values from settings
    final biz = settings['businessDetails'] ?? {};
    _businessNameController.text = biz['name'] ?? '';
    _addressController.text = biz['address'] ?? '';
    _phoneController.text = biz['phone'] ?? '';
    _gstinController.text = biz['gstin'] ?? '';
    _logoutDurationController.text = (settings['autoLogoutDuration'] ?? 30).toString();
    _currencyController.text = settings['currency'] ?? '₹';
    _taxEnabled = settings['taxEnabled'] ?? true;
    _autoEnd = settings['autoEndOnTimeOver'] ?? false;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('System Configurations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),

        _SectionHeader(title: 'Business Identity'),
        _SettingField(label: 'Business Name', controller: _businessNameController, icon: Icons.business),
        _SettingField(label: 'Address', controller: _addressController, icon: Icons.location_on_outlined),
        _SettingField(label: 'Phone Number', controller: _phoneController, icon: Icons.phone_outlined),
        _SettingField(label: 'GSTIN / Tax ID', controller: _gstinController, icon: Icons.description_outlined),

        const SizedBox(height: 24),
        _SectionHeader(title: 'Preferences'),
        Row(
          children: [
            Expanded(child: _SettingField(label: 'Currency Symbol', controller: _currencyController, icon: Icons.attach_money)),
            const SizedBox(width: 16),
            Expanded(child: _SettingField(label: 'Auto Logout (Mins)', controller: _logoutDurationController, icon: Icons.timer_outlined, keyboardType: TextInputType.number)),
          ],
        ),

        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Enable Taxation'),
          subtitle: const Text('Show taxes on bills and history'),
          value: _taxEnabled,
          onChanged: (val) => setState(() => _taxEnabled = val),
          activeColor: AppColors.primary,
        ),
        SwitchListTile(
          title: const Text('Auto-End Sessions'),
          subtitle: const Text('Force end session when time limit is over'),
          value: _autoEnd,
          onChanged: (val) => setState(() => _autoEnd = val),
          activeColor: AppColors.primary,
        ),

        const SizedBox(height: 48),
        ElevatedButton(
          onPressed: () {
            ref.read(adminProvider.notifier).updateSettings({
              'businessDetails': {
                'name': _businessNameController.text,
                'address': _addressController.text,
                'phone': _phoneController.text,
                'gstin': _gstinController.text,
              },
              'currency': _currencyController.text,
              'autoLogoutDuration': int.tryParse(_logoutDurationController.text) ?? 30,
              'taxEnabled': _taxEnabled,
              'autoEndOnTimeOver': _autoEnd,
            });
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('System settings saved!')));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text('SAVE SYSTEM SETTINGS'),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary.withOpacity(0.8), letterSpacing: 1.2, fontSize: 12)),
    );
  }
}

class _SettingField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType keyboardType;

  const _SettingField({
    required this.label, 
    required this.controller, 
    required this.icon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 20),
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
