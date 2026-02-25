import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(20),
          splashColor: scoreColor.withValues(alpha: 0.08),
          highlightColor: scoreColor.withValues(alpha: 0.04),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Product icon
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          scoreColor.withValues(alpha: 0.15),
                          scoreColor.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _getCategoryIcon(),
                      color: scoreColor,
                      size: 26,
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
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
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
                  const SizedBox(width: 8),
                  // Health score
                  HealthScoreCircle(
                    score: product.healthScore,
                    size: 48,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 350.ms, delay: Duration(milliseconds: index * 40))
        .slideX(begin: 0.03, end: 0, duration: 350.ms, delay: Duration(milliseconds: index * 40));
  }
}
