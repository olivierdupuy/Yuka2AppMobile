import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EcoScoreBadge extends StatelessWidget {
  final String? score;
  final double size;

  const EcoScoreBadge({super.key, this.score, this.size = 40});

  static const Map<String, Color> _ecoColors = {
    'A': Color(0xFF1E8F4E),
    'B': Color(0xFF2D9B3A),
    'C': Color(0xFFFECB02),
    'D': Color(0xFFEE8100),
    'E': Color(0xFFE63E11),
  };

  static Color ecoScoreColor(String? score) {
    return _ecoColors[score?.toUpperCase()] ?? Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final letters = ['A', 'B', 'C', 'D', 'E'];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: ecoScoreColor(score).withValues(alpha: 0.2),
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
            final color = _ecoColors[letter] ?? Colors.grey;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isActive ? size * 1.1 : size * 0.65,
              height: isActive ? size : size * 0.75,
              decoration: BoxDecoration(
                color: isActive ? color : color.withValues(alpha: 0.12),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isActive)
                    Icon(Icons.eco_rounded, color: Colors.white, size: size * 0.28),
                  Text(
                    letter,
                    style: GoogleFonts.inter(
                      fontSize: isActive ? size * 0.38 : size * 0.32,
                      fontWeight: FontWeight.w800,
                      color: isActive ? Colors.white : color.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
