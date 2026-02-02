import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/table_model.dart';
import '../theme/app_theme.dart';

class CheckoutModal extends StatefulWidget {
  final TableModel table;
  final Function(String paymentMethod) onConfirm;

  const CheckoutModal({
    super.key,
    required this.table,
    required this.onConfirm,
  });

  @override
  State<CheckoutModal> createState() => _CheckoutModalState();
}

class _CheckoutModalState extends State<CheckoutModal> {
  String _selectedPayment = 'Cash';

  @override
  Widget build(BuildContext context) {
    final session = widget.table.currentSession;
    if (session == null) return const SizedBox.shrink();

    final timeFormat = DateFormat('hh:mm a');

    return Container(
      padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 24),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bill Preview',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textHeading,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Table & Game Info Section
            Row(
              children: [
                _InfoChip(label: widget.table.name, color: AppColors.primary),
                const SizedBox(width: 8),
                _InfoChip(label: widget.table.type, color: AppColors.secondary),
              ],
            ),
            const SizedBox(height: 16),

            // Time Details
            _SummaryRow(label: 'Table Name', value: widget.table.name),
            _SummaryRow(
              label: 'Person (Staff)',
              value: session.handledByName ?? 'N/A',
            ),
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'Start Time',
              value: timeFormat.format(session.startTime),
            ),
            _SummaryRow(
              label: 'End Time',
              value:
                  session.endTime != null
                      ? timeFormat.format(session.endTime!)
                      : '--',
            ),
            _SummaryRow(
              label: 'Total Duration',
              value: '${session.elapsedMinutes} mins',
            ),
            _SummaryRow(
              label: 'Pricing Rule',
              value: session.pricingMode.toUpperCase().replaceAll('_', ' '),
            ),

            const Divider(height: 32, color: AppColors.surface),

            // Billing Details
            _SummaryRow(
              label: 'Subtotal',
              value: '₹${session.subtotal.toStringAsFixed(2)}',
            ),
            _SummaryRow(
              label: 'Tax',
              value: '₹${session.taxAmount.toStringAsFixed(2)}',
            ),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL AMOUNT',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textHeading,
                    ),
                  ),
                  Text(
                    '₹${session.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Text(
              'Select Payment Method',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textHeading,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _PaymentTypeCard(
                  label: 'Cash',
                  icon: Icons.money_rounded,
                  isSelected: _selectedPayment == 'Cash',
                  onTap: () => setState(() => _selectedPayment = 'Cash'),
                ),
                const SizedBox(width: 12),
                _PaymentTypeCard(
                  label: 'UPI',
                  icon: Icons.qr_code_rounded,
                  isSelected: _selectedPayment == 'UPI',
                  onTap: () => setState(() => _selectedPayment = 'UPI'),
                ),
                const SizedBox(width: 12),
                _PaymentTypeCard(
                  label: 'Other',
                  icon: Icons.credit_card_rounded,
                  isSelected: _selectedPayment == 'Other',
                  onTap: () => setState(() => _selectedPayment = 'Other'),
                ),
              ],
            ),

            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onConfirm(_selectedPayment);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                minimumSize: const Size(double.infinity, 56),
              ),
              child: const Text('MARK AS PAID & CLOSE'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onConfirm('${_selectedPayment}|DELETE');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 56),
              ),
              child: const Text('MARK AS PAID & DELETE TABLE'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;

  const _InfoChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textBody, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textHeading,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentTypeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentTypeCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? AppColors.primary.withOpacity(0.1)
                    : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textBody,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.textBody,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
