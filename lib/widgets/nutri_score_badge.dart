import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class NutriScoreBadge extends StatelessWidget {
  final String? score;
  final double size;

  const NutriScoreBadge({super.key, this.score, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final letters = ['A', 'B', 'C', 'D', 'E'];
    final colors = [
      AppTheme.nutriA,
      AppTheme.nutriB,
      AppTheme.nutriC,
      AppTheme.nutriD,
      AppTheme.nutriE,
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppTheme.nutriScoreColor(score).withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final letter = letters[index];
            final isActive = score?.toUpperCase() == letter;
            final color = colors[index];

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isActive ? size * 1.1 : size * 0.65,
              height: isActive ? size : size * 0.75,
              decoration: BoxDecoration(
                color: isActive ? color : color.withValues(alpha: 0.12),
              ),
              alignment: Alignment.center,
              child: Text(
                letter,
                style: GoogleFonts.inter(
                  fontSize: isActive ? size * 0.5 : size * 0.32,
                  fontWeight: FontWeight.w800,
                  color: isActive ? Colors.white : color.withValues(alpha: 0.4),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class HealthScoreCircle extends StatelessWidget {
  final int? score;
  final double size;

  const HealthScoreCircle({super.key, this.score, this.size = 60});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.healthScoreColor(score);
    final label = score != null
        ? (score! >= 75
            ? 'Excellent'
            : score! >= 50
                ? 'Bon'
                : score! >= 25
                    ? 'Moyen'
                    : 'Mauvais')
        : 'N/A';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withValues(alpha: 0.7)],
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            score?.toString() ?? '?',
            style: GoogleFonts.inter(
              fontSize: size * 0.36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
