import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/table_model.dart';
import '../providers/table_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class StartGameModal extends StatefulWidget {
  final TableModel table;

  const StartGameModal({super.key, required this.table});

  @override
  State<StartGameModal> createState() => _StartGameModalState();
}

class _StartGameModalState extends State<StartGameModal> {
  late String _gameType;
  String _pricingMode = 'per_hour';
  int _players = 1;
  final _timeLimitController = TextEditingController(text: '60');
  final _fixedPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _gameType = widget.table.supportedTypes.first;
    _fixedPriceController.text = widget.table.hourlyRate.toInt().toString();
  }

  @override
  void dispose() {
    _timeLimitController.dispose();
    _fixedPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Start Session: ${widget.table.name}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textHeading,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: AppColors.textBody),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Game Type', style: TextStyle(color: AppColors.textBody, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: widget.table.supportedTypes.map((type) {
              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: _ChoiceChip(
                  label: type,
                  isSelected: _gameType == type,
                  onSelected: (selected) => setState(() => _gameType = type),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text('Pricing Mode', style: TextStyle(color: AppColors.textBody, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _pricingMode,
            dropdownColor: AppColors.surface,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
            ),
            items: const [
              DropdownMenuItem(value: 'per_hour', child: Text('Per Hour')),
              DropdownMenuItem(value: 'per_minute', child: Text('Per Minute')),
              DropdownMenuItem(value: 'fixed', child: Text('Fixed Rate')),
              DropdownMenuItem(value: '30_min', child: Text('30 Mins (Half Rate)')),
            ],
            onChanged: (val) {
              setState(() {
                _pricingMode = val!;
                if (_pricingMode == '30_min') {
                  _fixedPriceController.text = (widget.table.hourlyRate / 2).toInt().toString();
                  _timeLimitController.text = '30';
                } else if (_pricingMode == 'per_hour') {
                  _timeLimitController.text = '60';
                }
              });
            },
          ),
          if (_pricingMode == 'fixed' || _pricingMode == '30_min') ...[
            const SizedBox(height: 24),
            const Text(
              'Fixed Price (₹)',
              style: TextStyle(color: AppColors.textBody, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _fixedPriceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Enter total price for session',
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Text('Number of Players', style: TextStyle(color: AppColors.textBody, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                onPressed: _players > 1 ? () => setState(() => _players--) : null,
                icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$_players', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                onPressed: () => setState(() => _players++),
                icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Time Limit (Minutes)', style: TextStyle(color: AppColors.textBody, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _timeLimitController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Enter minutes (0 for unlimited)',
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          const SizedBox(height: 48),
          Consumer(builder: (context, ref, child) {
            return ElevatedButton(
              onPressed: () {
                final userId = ref.read(authProvider).id ?? '';
                final isFixed = _pricingMode == 'fixed' || _pricingMode == '30_min';
                
                ref.read(tableProvider.notifier).startTable(
                      tableId: widget.table.id,
                      type: _gameType,
                      pricingMode: isFixed ? 'fixed' : _pricingMode,
                      players: _players,
                      timeLimitInMinutes: int.tryParse(_timeLimitController.text) ?? 0,
                      userId: userId,
                      fixedPrice: isFixed ? double.tryParse(_fixedPriceController.text) : null,
                    );
                Navigator.pop(context);
              },
              child: const Text('CONFIRM START'),
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Function(bool) onSelected;

  const _ChoiceChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textBody,
        fontWeight: FontWeight.bold,
      ),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
