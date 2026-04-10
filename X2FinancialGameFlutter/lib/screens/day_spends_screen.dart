import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_strings.dart';
import '../models/game_models.dart';
import '../state/game_store.dart';
import '../widgets/app_scope.dart';
import '../widgets/category_chip.dart';

class DaySpendsScreen extends StatefulWidget {
  const DaySpendsScreen({super.key, required this.dayIndex});

  final int dayIndex;

  @override
  State<DaySpendsScreen> createState() => _DaySpendsScreenState();
}

class _DaySpendsScreenState extends State<DaySpendsScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String? _selectedCategory;
  String? _editingItemId;
  Timer? _autosaveTimer;
  int _shakeKey = 0; // Increment to trigger shake animation

  late List<SpendItem> _items;
  late GameStore _store;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!mounted) return;
    _store = AppScope.of(context);
    final entry = _store.days.firstWhere(
      (d) => d.dayIndex == widget.dayIndex,
      orElse: () => _store.today,
    );
    _items = List.of(entry.items);
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    // Flush draft immediately on close
    _store.updateDraftItems(_items, widget.dayIndex);
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _scheduleAutosave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(seconds: 3), () {
      _store.updateDraftItems(_items, widget.dayIndex);
    });
  }

  DayEntry get _dayEntry => _store.days.firstWhere(
        (d) => d.dayIndex == widget.dayIndex,
        orElse: () => _store.today,
      );

  int get _totalSpent =>
      _items.fold(0, (sum, item) => sum + item.amountMinor);

  void _addOrUpdateItem() {
    final title = _titleController.text.trim();
    final amountStr =
        _amountController.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(amountStr) ?? 0;
    if (title.isEmpty || amount <= 0) return;

    final amountMinor = (amount * 100).round();
    final limit = _dayEntry.allowedTotalMinor;

    if (_editingItemId != null) {
      final idx = _items.indexWhere((i) => i.id == _editingItemId);
      if (idx >= 0) {
        final candidate = _totalSpent - _items[idx].amountMinor + amountMinor;
        if (candidate > limit) {
          _triggerShake();
          return;
        }
        setState(() {
          _items[idx] = _items[idx].copyWith(
            title: title,
            amountMinor: amountMinor,
            category: _selectedCategory,
          );
          _editingItemId = null;
          _titleController.clear();
          _amountController.clear();
          _selectedCategory = null;
        });
      }
    } else {
      if (_totalSpent + amountMinor > limit) {
        _triggerShake();
        return;
      }
      setState(() {
        _items.add(SpendItem(
          title: title,
          amountMinor: amountMinor,
          category: _selectedCategory,
        ));
        _titleController.clear();
        _amountController.clear();
        _selectedCategory = null;
      });
    }
    _scheduleAutosave();
  }

  void _editItem(SpendItem item) {
    setState(() {
      _editingItemId = item.id;
      _titleController.text = item.title;
      _amountController.text =
          (item.amountMinor / 100).toStringAsFixed(2);
      _selectedCategory = item.category;
    });
  }

  void _removeItem(String id) {
    setState(() => _items.removeWhere((i) => i.id == id));
    _scheduleAutosave();
  }

  void _triggerShake() {
    setState(() => _shakeKey++);
    HapticFeedback.lightImpact();
  }

  bool get _canSave {
    if (_items.isEmpty) return false;
    return _totalSpent <= _dayEntry.allowedTotalMinor;
  }

  void _saveDay() {
    if (!_canSave) return;
    _store.saveSpends(_items, widget.dayIndex);
    // Mark as filled only if this is today
    if (_store.todayEntry?.dayIndex == widget.dayIndex) {
      _store.today.items
        ..clear()
        ..addAll(_items);
      _store.saveToday();
    }
    _store.clearDraft(widget.dayIndex);
    context.go('/today');
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final entry = _dayEntry;
    final limit = entry.dailyLimitMinor;
    final currency = entry.currencyCode;
    final isToday = _store.todayEntry?.dayIndex == widget.dayIndex;

    final remaining = limit - _totalSpent;
    final isOver = _totalSpent > entry.allowedTotalMinor;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/today'),
        ),
        title: Text(
          '${s.t('day')} ${entry.dayIndex}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Limit / total / remaining bar
            Container(
              margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${s.t('limit')}: ${_store.formatMoney(limit, currency)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      Text(
                        '${s.t('total')}: ${_store.formatMoney(_totalSpent, currency)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isOver ? Colors.red : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${s.t('remaining')}: ${_store.formatMoney(remaining.abs(), currency)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: remaining < 0 ? Colors.red : Colors.green.shade700,
                        ),
                      ),
                      Text(
                        s.t('plus5Hint'),
                        style: const TextStyle(
                            fontSize: 11, color: Colors.black38),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Input form
            _ShakeWidget(
              key: ValueKey(_shakeKey),
              shake: _shakeKey > 0,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isOver ? Colors.red.shade300 : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              labelText: s.t('title'),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                            onChanged: (_) => _scheduleAutosave(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _amountController,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            decoration: InputDecoration(
                              labelText: s.t('amount'),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                            onChanged: (_) => _scheduleAutosave(),
                            onSubmitted: (_) => _addOrUpdateItem(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Category chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final cat in _store.categorySuggestions)
                          CategoryChip(
                            name: cat,
                            store: _store,
                            isSelected: _selectedCategory == cat,
                            onTap: () => setState(() => _selectedCategory =
                                _selectedCategory == cat ? null : cat),
                            onDoubleTap: _store.customCategories.contains(cat)
                                ? () => showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      builder: (_) => CategoryEditorSheet(
                                        categoryName: cat,
                                        store: _store,
                                      ),
                                    )
                                : null,
                          ),
                        // Add custom category button
                        GestureDetector(
                          onTap: _showAddCategoryDialog,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.grey.shade300,
                                  style: BorderStyle.solid),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  s.t('addCategory'),
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: _addOrUpdateItem,
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              _editingItemId != null
                                  ? s.t('updateItem')
                                  : s.t('addItem'),
                            ),
                          ),
                        ),
                        if (_editingItemId != null) ...[
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () => setState(() {
                              _editingItemId = null;
                              _titleController.clear();
                              _amountController.clear();
                              _selectedCategory = null;
                            }),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Icon(Icons.close, size: 18),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Items list
            Expanded(
              child: _items.isEmpty
                  ? Center(
                      child: Text(
                        s.t('noItems'),
                        style: const TextStyle(color: Colors.black38),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 56),
                      itemBuilder: (context, i) {
                        final item = _items[i];
                        return Dismissible(
                          key: ValueKey(item.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16),
                            color: Colors.red.shade100,
                            child: const Icon(Icons.delete_outline,
                                color: Colors.red),
                          ),
                          onDismissed: (_) => _removeItem(item.id),
                          child: ListTile(
                            dense: true,
                            onTap: () => _editItem(item),
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: item.category != null
                                  ? CategoryPalette.color(
                                      _store.colorTokenForCategory(
                                          item.category!),
                                    ).withOpacity(0.18)
                                  : Colors.grey.shade100,
                              child: Text(
                                item.title.isNotEmpty
                                    ? item.title[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(item.title),
                            subtitle: item.category != null
                                ? Text(item.category!,
                                    style: const TextStyle(fontSize: 11))
                                : null,
                            trailing: Text(
                              _store.formatMoney(item.amountMinor, currency),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Save button
            if (isToday)
              Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _canSave ? _saveDay : null,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(s.t('saveDay')),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddCategoryDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                _store.addCustomCategory(name);
                setState(() => _selectedCategory = name);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shake animation widget
// ---------------------------------------------------------------------------

class _ShakeWidget extends StatefulWidget {
  const _ShakeWidget({super.key, required this.child, required this.shake});

  final Widget child;
  final bool shake;

  @override
  State<_ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<_ShakeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);

    if (widget.shake) {
      _controller.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(_ShakeWidget old) {
    super.didUpdateWidget(old);
    if (widget.shake && !old.shake) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, child) {
        final offset = sin(_animation.value * pi * 4) * 8.0;
        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
