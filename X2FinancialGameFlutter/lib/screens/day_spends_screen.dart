import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../state/game_store.dart';

class DaySpendsScreen extends StatefulWidget {
  const DaySpendsScreen({super.key, required this.store});

  final GameStore store;

  @override
  State<DaySpendsScreen> createState() => _DaySpendsScreenState();
}

class _DaySpendsScreenState extends State<DaySpendsScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final today = widget.store.today;
    final remaining = today.dailyLimitMinor - today.totalSpent;

    return Scaffold(
      appBar: AppBar(title: Text(s.t('fillSpends'))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${s.t('limit')}: ${widget.store.formatMoney(today.dailyLimitMinor, today.currencyCode)}'),
                Text('${s.t('total')}: ${widget.store.formatMoney(today.totalSpent, today.currencyCode)}'),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('${s.t('remaining')}: ${widget.store.formatMoney(remaining, today.currencyCode)}'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: s.t('title')),
            ),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: s.t('amount')),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: _addItem,
                child: Text(s.t('addItem')),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: today.items.length,
                itemBuilder: (context, index) {
                  final item = today.items[index];
                  return ListTile(
                    title: Text(item.title),
                    subtitle: Text(widget.store.formatMoney(item.amountMinor, today.currencyCode)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => setState(() => widget.store.removeSpendItem(index)),
                    ),
                  );
                },
              ),
            ),
            FilledButton(
              onPressed: widget.store.canSaveToday()
                  ? () {
                      widget.store.saveToday();
                      Navigator.of(context).pop();
                    }
                  : null,
              child: Text(s.t('saveDay')),
            ),
          ],
        ),
      ),
    );
  }

  void _addItem() {
    final title = _titleController.text.trim();
    final amount = (double.tryParse(_amountController.text.trim()) ?? 0);
    if (title.isEmpty || amount <= 0) return;
    widget.store.addSpendItem(
      title: title,
      amountMinor: (amount * 100).round(),
    );
    setState(() {
      _titleController.clear();
      _amountController.clear();
    });
  }
}
