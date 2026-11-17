import 'package:flutter/material.dart';

import 'package:tims/core/models/item_model.dart';

/// Editable state for one issued item line.
class IssuanceLine {
  int? itemId;
  final TextEditingController quantity = TextEditingController();
  final TextEditingController notes = TextEditingController();

  void dispose() {
    quantity.dispose();
    notes.dispose();
  }
}

/// A row for picking an item and quantity on an issuance form.
class IssuanceLineRow extends StatelessWidget {
  const IssuanceLineRow({
    super.key,
    required this.line,
    required this.items,
    required this.onItemChanged,
    required this.onRemove,
  });

  final IssuanceLine line;
  final List<ItemModel> items;
  final ValueChanged<int?> onItemChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final selected = items.where((i) => i.id == line.itemId).firstOrNull;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<int>(
                  initialValue: line.itemId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Item *'),
                  items: [
                    for (final item in items)
                      DropdownMenuItem(
                        value: item.id,
                        child: Text(
                          '${item.name} (${item.quantity} ${item.unit})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: onItemChanged,
                  validator: (v) => v == null ? 'Select an item' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: line.quantity,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Qty *'),
                  validator: (v) {
                    final qty = int.tryParse(v?.trim() ?? '');
                    if (qty == null || qty < 1) return 'Min 1';
                    if (selected != null && qty > selected.quantity) {
                      return 'Max ${selected.quantity}';
                    }
                    return null;
                  },
                ),
              ),
              IconButton(
                tooltip: 'Remove item',
                onPressed: onRemove,
                icon: const Icon(Icons.remove_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: line.notes,
            decoration: const InputDecoration(labelText: 'Line notes'),
          ),
        ],
      ),
    );
  }
}
