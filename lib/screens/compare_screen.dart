import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/compare_provider.dart';
import '../models/product.dart';
import '../widgets/nutri_score_badge.dart';
import '../theme/app_theme.dart';

class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CompareProvider>().compare();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comparateur'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              context.read<CompareProvider>().clearSelection();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Consumer<CompareProvider>(
        builder: (context, compare, _) {
          if (compare.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (compare.comparedProducts.isEmpty) {
            return const Center(
              child: Text('Sélectionnez au moins 2 produits à comparer'),
            );
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildComparisonTable(compare),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildComparisonTable(CompareProvider compare) {
    final products = compare.comparedProducts;
    final bestHealthId = compare.bestHealthScoreId;
    final bestNutriId = compare.bestNutriScoreId;

    return Table(
      defaultColumnWidth: const FixedColumnWidth(140),
      border: TableBorder.all(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      children: [
        // Header row with product images and names
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade50),
          children: [
            _headerCell(''),
            ...products.map((p) => _productHeaderCell(p, bestHealthId)),
          ],
        ),
        // NutriScore
        _buildRow('NutriScore', products, (p) {
          final isBest = p.id == bestNutriId;
          return Container(
            padding: const EdgeInsets.all(4),
            decoration: isBest
                ? BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  )
                : null,
            child: Center(
              child: NutriScoreBadge(score: p.nutriScore ?? '?', size: 28),
            ),
          );
        }),
        // Health Score
        _buildRow('Score santé', products, (p) {
          final isBest = p.id == bestHealthId;
          return _valueCell(
            '${p.healthScore ?? "-"}/100',
            isBest: isBest,
            color: AppTheme.healthScoreColor(p.healthScore ?? 0),
          );
        }),
        // Nutritional values
        _buildNumericRow('Calories', products, (p) => p.calories, unit: 'kcal', lowerIsBetter: true),
        _buildNumericRow('Graisses', products, (p) => p.fat, unit: 'g', lowerIsBetter: true),
        _buildNumericRow('Graisses sat.', products, (p) => p.saturatedFat, unit: 'g', lowerIsBetter: true),
        _buildNumericRow('Sucres', products, (p) => p.sugars, unit: 'g', lowerIsBetter: true),
        _buildNumericRow('Sel', products, (p) => p.salt, unit: 'g', lowerIsBetter: true),
        _buildNumericRow('Fibres', products, (p) => p.fiber, unit: 'g', lowerIsBetter: false),
        _buildNumericRow('Protéines', products, (p) => p.proteins, unit: 'g', lowerIsBetter: false),
        // Allergens
        _buildRow('Allergènes', products, (p) {
          final allergens = p.allergens ?? 'Aucun';
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              allergens,
              style: TextStyle(
                fontSize: 11,
                color: allergens != 'Aucun' ? Colors.red.shade700 : Colors.green.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }),
      ],
    );
  }

  TableRow _buildRow(String label, List<Product> products, Widget Function(Product) cellBuilder) {
    return TableRow(
      children: [
        _labelCell(label),
        ...products.map(cellBuilder),
      ],
    );
  }

  TableRow _buildNumericRow(
    String label,
    List<Product> products,
    double? Function(Product) getValue, {
    String unit = '',
    required bool lowerIsBetter,
  }) {
    final values = products.map((p) => getValue(p)).toList();
    final nonNull = values.where((v) => v != null).toList();
    double? bestValue;
    double? worstValue;

    if (nonNull.isNotEmpty) {
      if (lowerIsBetter) {
        bestValue = nonNull.reduce((a, b) => a! < b! ? a : b);
        worstValue = nonNull.reduce((a, b) => a! > b! ? a : b);
      } else {
        bestValue = nonNull.reduce((a, b) => a! > b! ? a : b);
        worstValue = nonNull.reduce((a, b) => a! < b! ? a : b);
      }
    }

    return TableRow(
      children: [
        _labelCell(label),
        ...products.map((p) {
          final val = getValue(p);
          final isBest = val != null && val == bestValue && nonNull.length > 1;
          final isWorst = val != null && val == worstValue && nonNull.length > 1;
          return _valueCell(
            val != null ? '${val.toStringAsFixed(1)} $unit' : '-',
            isBest: isBest,
            isWorst: isWorst,
          );
        }),
      ],
    );
  }

  Widget _headerCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _labelCell(String text) {
    return Container(
      padding: const EdgeInsets.all(10),
      color: Colors.grey.shade50,
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF6B7280)),
      ),
    );
  }

  Widget _valueCell(String text, {bool isBest = false, bool isWorst = false, Color? color}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isBest
            ? Colors.green.withValues(alpha: 0.1)
            : isWorst
                ? Colors.red.withValues(alpha: 0.05)
                : null,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isBest ? FontWeight.bold : FontWeight.normal,
          color: color ?? (isBest ? Colors.green.shade700 : isWorst ? Colors.red.shade700 : null),
        ),
      ),
    );
  }

  Widget _productHeaderCell(Product product, int? bestHealthId) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          if (product.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                product.imageUrl!,
                height: 60,
                width: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 40),
              ),
            ),
          const SizedBox(height: 4),
          Text(
            product.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (product.brand != null)
            Text(
              product.brand!,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          if (product.id == bestHealthId)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Meilleur choix',
                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}
