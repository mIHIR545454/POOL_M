import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/session_history_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final userId = ref.read(authProvider).id;
      if (userId != null) {
        ref.read(sessionHistoryProvider.notifier).fetchHistory(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(sessionHistoryProvider);
    final timeFormat = DateFormat('hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session History'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: historyState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : historyState.sessions.isEmpty
              ? const Center(child: Text('No sessions recorded today.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: historyState.sessions.length,
                  itemBuilder: (context, index) {
                    final session = historyState.sessions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: AppColors.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              session.tableName ?? 'Unknown Table',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '₹${session.totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.timer_outlined, size: 14, color: AppColors.textBody),
                                const SizedBox(width: 4),
                                Text('${session.elapsedMinutes} mins • ${timeFormat.format(session.startTime)} - ${session.endTime != null ? timeFormat.format(session.endTime!) : '--'}'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  session.paymentMethod == 'Cash' ? Icons.money : Icons.qr_code,
                                  size: 14,
                                  color: AppColors.textBody,
                                ),
                                const SizedBox(width: 4),
                                Text('Paid via ${session.paymentMethod ?? 'Other'}'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
