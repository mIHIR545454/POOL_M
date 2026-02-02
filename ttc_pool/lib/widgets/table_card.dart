import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/table_model.dart';
import '../providers/table_provider.dart';
import '../widgets/start_game_modal.dart';
import '../widgets/pause_reason_modal.dart';
import '../widgets/checkout_modal.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class TableCard extends ConsumerWidget {
  final TableModel table;

  const TableCard({super.key, required this.table});

  Color _getStatusColor() {
    switch (table.status) {
      case 'Idle':
        return AppColors.secondary;
      case 'Running':
        return AppColors.primary;
      case 'Paused':
        return AppColors.accent;
      case 'Time Over':
        return AppColors.error;
      case 'Ended':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = table.currentSession;
    final elapsedMinutes = session?.elapsedMinutes ?? 0;

    double displayBill = 0.0;
    if (table.status == 'Ended' && session != null) {
      displayBill = session.totalAmount;
    } else if (session != null) {
      if (session.pricingMode == 'fixed') {
        displayBill = session.hourlyRateAtStart;
      } else if (session.pricingMode == 'per_minute') {
        displayBill = elapsedMinutes * (session.hourlyRateAtStart / 60);
      } else {
        displayBill = (elapsedMinutes / 60) * session.hourlyRateAtStart;
      }
    }

    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: _getStatusColor().withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      table.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textHeading,
                      ),
                    ),
                    Text(
                      table.type,
                      style: TextStyle(
                        color: AppColors.textBody.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    table.status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (session != null) ...[
              _InfoRow(
                icon: Icons.timer_outlined,
                label: 'Elapsed',
                value: '${elapsedMinutes ~/ 60}h ${elapsedMinutes % 60}m',
              ),
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.payments_outlined,
                label: table.status == 'Ended' ? 'Final Bill' : 'Est. Bill',
                value: '₹${displayBill.toStringAsFixed(2)}',
                valueColor:
                    table.status == 'Ended'
                        ? Colors.orangeAccent
                        : AppColors.secondary,
              ),
            ] else ...[
              Center(
                child: Text(
                  '₹${table.hourlyRate.toInt()}/hr',
                  style: const TextStyle(color: AppColors.textBody),
                ),
              ),
            ],
            const Spacer(),
            Row(
              children: [
                if (table.status == 'Idle')
                  Expanded(
                    child: _ActionButton(
                      label: 'START',
                      color: AppColors.primary,
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => StartGameModal(table: table),
                        );
                      },
                    ),
                  ),
                if (table.status == 'Running') ...[
                  Expanded(
                    child: _ActionButton(
                      label: 'PAUSE',
                      color: AppColors.accent,
                      onPressed: () async {
                        final reason = await showModalBottomSheet<String>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => const PauseReasonModal(),
                        );
                        if (reason != null && context.mounted) {
                          ref
                              .read(tableProvider.notifier)
                              .pauseTable(
                                table.id,
                                reason,
                                ref.read(authProvider).id ?? '',
                              );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
                      label: 'END',
                      color: AppColors.error,
                      onPressed:
                          () => ref
                              .read(tableProvider.notifier)
                              .endTable(
                                table.id,
                                ref.read(authProvider).id ?? '',
                              ),
                    ),
                  ),
                ],
                if (table.status == 'Paused') ...[
                  Expanded(
                    child: _ActionButton(
                      label: 'RESUME',
                      color: AppColors.secondary,
                      onPressed:
                          () => ref
                              .read(tableProvider.notifier)
                              .resumeTable(
                                table.id,
                                ref.read(authProvider).id ?? '',
                              ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
                      label: 'END',
                      color: AppColors.error,
                      onPressed:
                          () => ref
                              .read(tableProvider.notifier)
                              .endTable(
                                table.id,
                                ref.read(authProvider).id ?? '',
                              ),
                    ),
                  ),
                ],
                if (table.status == 'Time Over')
                  Expanded(
                    child: _ActionButton(
                      label: 'END SESSION',
                      color: AppColors.error,
                      onPressed:
                          () => ref
                              .read(tableProvider.notifier)
                              .endTable(
                                table.id,
                                ref.read(authProvider).id ?? '',
                              ),
                    ),
                  ),
                if (table.status == 'Ended')
                  Expanded(
                    child: _ActionButton(
                      label: 'GENERATE BILL',
                      color: Colors.orangeAccent,
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder:
                              (context) => CheckoutModal(
                                table: table,
                                onConfirm: (paymentMethod) async {
                                  // Check if delete option is included
                                  bool shouldDelete = paymentMethod.contains(
                                    'DELETE',
                                  );
                                  String actualPaymentMethod = paymentMethod
                                      .replaceAll('|DELETE', '');

                                  final success = await ref
                                      .read(tableProvider.notifier)
                                      .clearTable(
                                        table.id,
                                        ref.read(authProvider).id ?? '',
                                        actualPaymentMethod,
                                        autoDelete: shouldDelete,
                                      );

                                  if (success && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            const Icon(
                                              Icons.check_circle,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                shouldDelete
                                                    ? 'Payment Successful! Table Deleted.'
                                                    : 'Payment Successful! Table Cleared.',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: AppColors.secondary,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                },
                              ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textBody),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: AppColors.textBody, fontSize: 13),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.textHeading,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(0, 40),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
