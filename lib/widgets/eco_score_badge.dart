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

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final letter = letters[index];
        final isActive = score?.toUpperCase() == letter;
        final color = _ecoColors[letter] ?? Colors.grey;

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isActive)
                Icon(Icons.eco_rounded, color: Colors.white, size: size * 0.3),
              Text(
                letter,
                style: GoogleFonts.inter(
                  fontSize: isActive ? size * 0.4 : size * 0.35,
                  fontWeight: FontWeight.w800,
                  color: isActive ? Colors.white : color.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
