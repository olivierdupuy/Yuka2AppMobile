class AllergenCheckResult {
  final int productId;
  final String productName;
  final List<String> productAllergens;
  final List<String> userAllergens;
  final List<String> matchedAllergens;
  final bool hasAlert;

  AllergenCheckResult({
    required this.productId,
    required this.productName,
    required this.productAllergens,
    required this.userAllergens,
    required this.matchedAllergens,
    required this.hasAlert,
  });

  factory AllergenCheckResult.fromJson(Map<String, dynamic> json) {
    return AllergenCheckResult(
      productId: json['productId'] as int,
      productName: json['productName'] as String? ?? '',
      productAllergens: (json['productAllergens'] as List?)?.map((e) => e as String).toList() ?? [],
      userAllergens: (json['userAllergens'] as List?)?.map((e) => e as String).toList() ?? [],
      matchedAllergens: (json['matchedAllergens'] as List?)?.map((e) => e as String).toList() ?? [],
      hasAlert: json['hasAlert'] as bool? ?? false,
    );
  }
}
