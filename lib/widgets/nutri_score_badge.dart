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

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final letter = letters[index];
        final isActive = score?.toUpperCase() == letter;
        final color = colors[index];

        return Container(
          width: isActive ? size : size * 0.7,
          height: isActive ? size : size * 0.7,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: isActive ? color : color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.horizontal(
              left: index == 0 ? const Radius.circular(8) : Radius.zero,
              right: index == 4 ? const Radius.circular(8) : Radius.zero,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            letter,
            style: GoogleFonts.inter(
              fontSize: isActive ? size * 0.5 : size * 0.35,
              fontWeight: FontWeight.w800,
              color: isActive ? Colors.white : color.withValues(alpha: 0.5),
            ),
          ),
        );
      }),
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
                color: color.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            score?.toString() ?? '?',
            style: GoogleFonts.inter(
              fontSize: size * 0.35,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
