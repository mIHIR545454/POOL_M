import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/admin_provider.dart';
import '../widgets/table_management_view.dart';
import '../widgets/pricing_settings_view.dart';
import '../widgets/staff_management_view.dart';
import '../widgets/system_settings_view.dart';
import '../theme/app_theme.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminState = ref.watch(adminProvider);

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Stats', icon: Icon(Icons.analytics_outlined)),
              Tab(text: 'Tables', icon: Icon(Icons.table_bar_outlined)),
              Tab(text: 'Pricing', icon: Icon(Icons.payments_outlined)),
              Tab(text: 'Staff', icon: Icon(Icons.people_outline)),
              Tab(text: 'System', icon: Icon(Icons.settings_outlined)),
            ],
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textBody,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () {
                ref.read(adminProvider.notifier).fetchStats();
                ref.read(adminProvider.notifier).fetchAllTables();
                ref.read(adminProvider.notifier).fetchSettings();
                ref.read(adminProvider.notifier).fetchStaff();
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: adminState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : adminState.error != null
                ? Center(child: Text('Error: ${adminState.error}'))
                : TabBarView(
                    children: [
                      _AdminDashboardContent(
                        stats: adminState.stats!, 
                        currency: adminState.settings?['currency'] ?? '₹'
                      ),
                      const TableManagementView(),
                      const PricingSettingsView(),
                      const StaffManagementView(),
                      const SystemSettingsView(),
                    ],
                  ),
      ),
    );
  }
}

class _AdminDashboardContent extends StatelessWidget {
  final AdminStats stats;
  final String currency;

  const _AdminDashboardContent({required this.stats, required this.currency});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Revenue Overview
        const Text('Revenue Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            _StatCard(
              label: "Today",
              value: "$currency${stats.revenue['today'].toStringAsFixed(0)}",
              color: AppColors.primary,
              icon: Icons.today,
            ),
            const SizedBox(width: 12),
            _StatCard(
              label: "This Week",
              value: "$currency${stats.revenue['week'].toStringAsFixed(0)}",
              color: AppColors.secondary,
              icon: Icons.calendar_view_week,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _StatCard(
              label: "This Month",
              value: "$currency${stats.revenue['month'].toStringAsFixed(0)}",
              color: AppColors.accent,
              icon: Icons.calendar_month,
            ),
            const SizedBox(width: 12),
            _StatCard(
              label: "Active Tables",
              value: "${stats.activeTablesCount}",
              color: Colors.orangeAccent,
              icon: Icons.table_restaurant,
            ),
          ],
        ),

        const SizedBox(height: 32),
        const Text('Table Utilization', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _UtilizationList(data: stats.tableUtilization),

        const SizedBox(height: 32),
        const Text('Staff Performance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _StaffPerformanceCard(data: stats.staffPerformance, currency: currency),

        const SizedBox(height: 32),
        const Text('Peak Hours', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _PeakHoursChart(data: stats.peakHours),
        
        const SizedBox(height: 48),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textHeading)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textBody)),
          ],
        ),
      ),
    );
  }
}

class _UtilizationList extends StatelessWidget {
  final List<dynamic> data;

  const _UtilizationList({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: data.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Icon(Icons.table_bar, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${item['count']} sessions', style: const TextStyle(fontSize: 12, color: AppColors.textBody)),
                  ],
                ),
              ),
              Text('${(item['totalMinutes'] / 60).toStringAsFixed(1)} hrs', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _StaffPerformanceCard extends StatelessWidget {
  final List<dynamic> data;
  final String currency;

  const _StaffPerformanceCard({required this.data, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: data.map((staff) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(staff['username'], style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('$currency${staff['totalRevenue'].toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PeakHoursChart extends StatelessWidget {
  final List<dynamic> data;

  const _PeakHoursChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: data.isEmpty ? 10 : data.map((e) => e['count'] as int).reduce((a, b) => a > b ? a : b).toDouble() + 2,
          barGroups: data.map((e) {
            return BarChartGroupData(
              x: e['_id'],
              barRods: [
                BarChartRodData(
                  toY: (e['count'] as int).toDouble(),
                  color: AppColors.primary,
                  width: 12,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                )
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text('${value.toInt()}h', style: const TextStyle(fontSize: 10, color: AppColors.textBody));
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}
