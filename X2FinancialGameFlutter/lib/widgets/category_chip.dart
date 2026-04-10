import 'package:flutter/material.dart';

import '../models/game_models.dart';
import '../state/game_store.dart';

/// Tappable category chip with optional double-tap to edit.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.name,
    required this.store,
    required this.isSelected,
    required this.onTap,
    this.onDoubleTap,
  });

  final String name;
  final GameStore store;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;

  @override
  Widget build(BuildContext context) {
    final token = store.colorTokenForCategory(name);
    final color = CategoryPalette.color(token);

    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.22) : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.35),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          name,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? color : Colors.black87,
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet for renaming/recoloring a category.
class CategoryEditorSheet extends StatefulWidget {
  const CategoryEditorSheet({
    super.key,
    required this.categoryName,
    required this.store,
  });

  final String categoryName;
  final GameStore store;

  @override
  State<CategoryEditorSheet> createState() => _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends State<CategoryEditorSheet> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.categoryName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final token = widget.store.colorTokenForCategory(widget.categoryName);
    final color = CategoryPalette.color(token);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit category',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Color: '),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    widget.store
                        .cycleCustomCategoryColor(widget.categoryName);
                    setState(() {});
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Tap to cycle',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.black45),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final newName = _nameController.text.trim();
                      if (newName.isNotEmpty &&
                          newName != widget.categoryName) {
                        widget.store.renameCustomCategory(
                          widget.categoryName,
                          newName,
                        );
                      }
                      Navigator.pop(context);
                    },
                    child: const Text('Save'),
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
