import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/shopping_list_provider.dart';

class ShoppingListDetailScreen extends StatefulWidget {
  final int listId;
  final String listName;

  const ShoppingListDetailScreen({
    super.key,
    required this.listId,
    required this.listName,
  });

  @override
  State<ShoppingListDetailScreen> createState() => _ShoppingListDetailScreenState();
}

class _ShoppingListDetailScreenState extends State<ShoppingListDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShoppingListProvider>().loadDetail(widget.listId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.listName),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'shopping_detail_fab',
        onPressed: _showAddItemDialog,
        backgroundColor: const Color(0xFF1B5E20),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Consumer<ShoppingListProvider>(
        builder: (context, provider, _) {
          final detail = provider.currentDetail;

          if (provider.isLoading && detail == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (detail == null) {
            return const Center(child: Text('Liste introuvable'));
          }

          if (detail.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_basket_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'Liste vide',
                    style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ajoutez des articles !',
                    style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            );
          }

          final checkedCount = detail.items.where((i) => i.isChecked).length;
          final totalCount = detail.items.length;

          return Column(
            children: [
              // Progress header
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$checkedCount/$totalCount articles cochés',
                          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                        ),
                        Text(
                          '${totalCount > 0 ? (checkedCount / totalCount * 100).toInt() : 0}%',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: totalCount > 0 ? checkedCount / totalCount : 0,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation(Color(0xFF1B5E20)),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),

              // Items list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: detail.items.length,
                  itemBuilder: (context, index) {
                    final item = detail.items[index];
                    return Dismissible(
                      key: Key('item_${item.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.shade400,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) {
                        provider.removeItem(widget.listId, item.id);
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: Checkbox(
                            value: item.isChecked,
                            activeColor: const Color(0xFF1B5E20),
                            onChanged: (val) {
                              provider.toggleItemChecked(widget.listId, item.id, val ?? false);
                            },
                          ),
                          title: Text(
                            item.name,
                            style: TextStyle(
                              decoration: item.isChecked ? TextDecoration.lineThrough : null,
                              color: item.isChecked ? Colors.grey : null,
                            ),
                          ),
                          subtitle: item.productName != null
                              ? Text(
                                  item.productName!,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                                )
                              : null,
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'x${item.quantity}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ),
                      ).animate().fadeIn(duration: 200.ms, delay: (index * 30).ms),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddItemDialog() {
    final nameController = TextEditingController();
    int quantity = 1;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Ajouter un article'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Nom de l\'article',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Quantité : '),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: quantity > 1
                        ? () => setDialogState(() => quantity--)
                        : null,
                  ),
                  Text('$quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => setDialogState(() => quantity++),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  await context.read<ShoppingListProvider>().addItem(
                    widget.listId,
                    name: name,
                    quantity: quantity,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }
}
