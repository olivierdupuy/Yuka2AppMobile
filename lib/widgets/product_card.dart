import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import 'nutri_score_badge.dart';

class ProductCard extends StatelessWidget {
  final ProductSearch product;
  final VoidCallback onTap;
  final int index;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.index = 0,
  });

  IconData _getCategoryIcon() {
    final cat = product.categories?.toLowerCase() ?? '';
    if (cat.contains('boisson') || cat.contains('eau')) return Icons.local_drink_rounded;
    if (cat.contains('fromage') || cat.contains('lait') || cat.contains('yaourt')) return Icons.breakfast_dining_rounded;
    if (cat.contains('chocolat') || cat.contains('biscuit') || cat.contains('sucr')) return Icons.cookie_rounded;
    if (cat.contains('légume') || cat.contains('salade')) return Icons.eco_rounded;
    if (cat.contains('fruit') || cat.contains('compote')) return Icons.apple_rounded;
    if (cat.contains('chip') || cat.contains('salé')) return Icons.fastfood_rounded;
    if (cat.contains('conserve')) return Icons.inventory_2_rounded;
    if (cat.contains('tartiner')) return Icons.brunch_dining_rounded;
    return Icons.restaurant_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final scoreColor = AppTheme.healthScoreColor(product.healthScore);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Product icon/image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getCategoryIcon(),
                  color: scoreColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              // Product info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.brand ?? 'Marque inconnue',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    NutriScoreBadge(score: product.nutriScore, size: 24),
                  ],
                ),
              ),
              // Health score
              HealthScoreCircle(
                score: product.healthScore,
                size: 50,
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: Duration(milliseconds: index * 50))
        .slideX(begin: 0.05, end: 0, duration: 300.ms, delay: Duration(milliseconds: index * 50));
  }
}
