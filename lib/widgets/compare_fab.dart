import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/compare_provider.dart';
import '../screens/compare_screen.dart';

class CompareFab extends StatelessWidget {
  const CompareFab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CompareProvider>(
      builder: (context, compare, _) {
        if (compare.selectedCount == 0) return const SizedBox.shrink();

        return FloatingActionButton.extended(
          heroTag: 'compare_fab',
          onPressed: compare.canCompare
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CompareScreen()),
                  );
                }
              : null,
          backgroundColor: compare.canCompare
              ? const Color(0xFF1B5E20)
              : Colors.grey,
          icon: Badge(
            label: Text(
              '${compare.selectedCount}',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            child: const Icon(Icons.compare_arrows, color: Colors.white),
          ),
          label: Text(
            compare.canCompare ? 'Comparer' : '${compare.selectedCount}/2 min',
            style: const TextStyle(color: Colors.white),
          ),
        );
      },
    );
  }
}
