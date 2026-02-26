import 'package:flutter/material.dart';

class AllergenBanner extends StatelessWidget {
  final List<String> matchedAllergens;
  final VoidCallback? onTap;

  const AllergenBanner({
    super.key,
    required this.matchedAllergens,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (matchedAllergens.isEmpty) return const SizedBox.shrink();

    final isHighRisk = matchedAllergens.length >= 2;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isHighRisk
                ? [const Color(0xFFE53935), const Color(0xFFC62828)]
                : [const Color(0xFFFF9800), const Color(0xFFE65100)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: (isHighRisk ? Colors.red : Colors.orange).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              isHighRisk ? Icons.warning_rounded : Icons.info_outline_rounded,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isHighRisk ? 'Alerte allergène !' : 'Attention allergène',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Contient : ${matchedAllergens.join(", ")}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                color: Colors.white.withValues(alpha: 0.7),
              ),
          ],
        ),
      ),
    );
  }
}
