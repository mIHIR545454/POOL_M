import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_provider.dart';
import '../theme/app_theme.dart';

class PricingSettingsView extends ConsumerStatefulWidget {
  const PricingSettingsView({super.key});

  @override
  ConsumerState<PricingSettingsView> createState() => _PricingSettingsViewState();
}

class _PricingSettingsViewState extends ConsumerState<PricingSettingsView> {
  final _taxController = TextEditingController();
  final _poolRateController = TextEditingController();
  final _poolMinController = TextEditingController();
  final _snookerRateController = TextEditingController();
  final _snookerMinController = TextEditingController();

  @override
  void dispose() {
    _taxController.dispose();
    _poolRateController.dispose();
    _poolMinController.dispose();
    _snookerRateController.dispose();
    _snookerMinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(adminProvider).settings;
    if (settings == null) return const Center(child: CircularProgressIndicator());

    _taxController.text = settings['taxPercentage'].toString();
    final rules = settings['pricingRules'] as List;
    final pool = rules.firstWhere((r) => r['gameType'] == 'Pool');
    final snooker = rules.firstWhere((r) => r['gameType'] == 'Snooker');

    _poolRateController.text = pool['hourlyRate'].toString();
    _poolMinController.text = pool['minCharge'].toString();
    _snookerRateController.text = snooker['hourlyRate'].toString();
    _snookerMinController.text = snooker['minCharge'].toString();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Global Pricing Rules', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        
        // Tax Section
        _SectionHeader(title: 'Taxation'),
        _SettingField(label: 'Global Tax Percentage (%)', controller: _taxController),
        
        const SizedBox(height: 32),
        
        // Pool Section
        _SectionHeader(title: 'Pool Pricing'),
        _SettingField(label: 'Hourly Rate (₹)', controller: _poolRateController),
        _SettingField(label: 'Minimum Charge (₹)', controller: _poolMinController),
        
        const SizedBox(height: 32),
        
        // Snooker Section
        _SectionHeader(title: 'Snooker Pricing'),
        _SettingField(label: 'Hourly Rate (₹)', controller: _snookerRateController),
        _SettingField(label: 'Minimum Charge (₹)', controller: _snookerMinController),
        
        const SizedBox(height: 48),
        
        ElevatedButton(
          onPressed: () {
            ref.read(adminProvider.notifier).updateSettings({
              'taxPercentage': double.tryParse(_taxController.text) ?? 12,
              'pricingRules': [
                {
                  'gameType': 'Pool',
                  'hourlyRate': double.tryParse(_poolRateController.text) ?? 200,
                  'minCharge': double.tryParse(_poolMinController.text) ?? 50,
                },
                {
                  'gameType': 'Snooker',
                  'hourlyRate': double.tryParse(_snookerRateController.text) ?? 350,
                  'minCharge': double.tryParse(_snookerMinController.text) ?? 100,
                },
              ]
            });
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pricing rules updated!')));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size(double.infinity, 56),
          ),
          child: const Text('SAVE GLOBAL RULES'),
        ),
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
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(width: 4, height: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textHeading)),
        ],
      ),
    );
  }
}

class _SettingField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _SettingField({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textBody, fontSize: 13),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
