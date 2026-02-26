import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final int maxStars;
  final double rating;
  final double size;
  final Color activeColor;
  final Color inactiveColor;
  final ValueChanged<int>? onRatingChanged;

  const StarRating({
    super.key,
    this.maxStars = 5,
    required this.rating,
    this.size = 24,
    this.activeColor = const Color(0xFFFFB300),
    this.inactiveColor = const Color(0xFFE0E0E0),
    this.onRatingChanged,
  });

  bool get isInteractive => onRatingChanged != null;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxStars, (index) {
        final starValue = index + 1;
        IconData icon;
        Color color;

        if (rating >= starValue) {
          icon = Icons.star_rounded;
          color = activeColor;
        } else if (rating >= starValue - 0.5) {
          icon = Icons.star_half_rounded;
          color = activeColor;
        } else {
          icon = Icons.star_outline_rounded;
          color = inactiveColor;
        }

        return GestureDetector(
          onTap: isInteractive ? () => onRatingChanged!(starValue) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(icon, color: color, size: size),
          ),
        );
      }),
    );
  }
}
