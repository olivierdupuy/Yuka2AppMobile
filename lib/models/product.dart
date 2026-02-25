class Product {
  final int id;
  final String barcode;
  final String name;
  final String? brand;
  final String? imageUrl;
  final String? nutriScore;
  final String? ecoScore;
  final int? novaGroup;
  final int? healthScore;
  final double? calories;
  final double? fat;
  final double? saturatedFat;
  final double? sugars;
  final double? salt;
  final double? fiber;
  final double? proteins;
  final double? carbohydrates;
  final String? ingredients;
  final String? allergens;
  final String? additives;
  final String? categories;
  final String? quantity;
  final bool isOrganic;
  final bool isPalmOilFree;
  final bool isVegan;

  Product({
    required this.id,
    required this.barcode,
    required this.name,
    this.brand,
    this.imageUrl,
    this.nutriScore,
    this.ecoScore,
    this.novaGroup,
    this.healthScore,
    this.calories,
    this.fat,
    this.saturatedFat,
    this.sugars,
    this.salt,
    this.fiber,
    this.proteins,
    this.carbohydrates,
    this.ingredients,
    this.allergens,
    this.additives,
    this.categories,
    this.quantity,
    this.isOrganic = false,
    this.isPalmOilFree = false,
    this.isVegan = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      barcode: json['barcode'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String?,
      imageUrl: json['imageUrl'] as String?,
      nutriScore: json['nutriScore'] as String?,
      ecoScore: json['ecoScore'] as String?,
      novaGroup: json['novaGroup'] as int?,
      healthScore: json['healthScore'] as int?,
      calories: (json['calories'] as num?)?.toDouble(),
      fat: (json['fat'] as num?)?.toDouble(),
      saturatedFat: (json['saturatedFat'] as num?)?.toDouble(),
      sugars: (json['sugars'] as num?)?.toDouble(),
      salt: (json['salt'] as num?)?.toDouble(),
      fiber: (json['fiber'] as num?)?.toDouble(),
      proteins: (json['proteins'] as num?)?.toDouble(),
      carbohydrates: (json['carbohydrates'] as num?)?.toDouble(),
      ingredients: json['ingredients'] as String?,
      allergens: json['allergens'] as String?,
      additives: json['additives'] as String?,
      categories: json['categories'] as String?,
      quantity: json['quantity'] as String?,
      isOrganic: json['isOrganic'] as bool? ?? false,
      isPalmOilFree: json['isPalmOilFree'] as bool? ?? false,
      isVegan: json['isVegan'] as bool? ?? false,
    );
  }

  /// Qualificatif du produit comme dans Yuka
  String get qualityLabel {
    if (healthScore == null) return 'Non évalué';
    if (healthScore! >= 75) return 'Excellent';
    if (healthScore! >= 50) return 'Bon';
    if (healthScore! >= 25) return 'Médiocre';
    return 'Mauvais';
  }

  /// Analyse les points positifs du produit
  List<ProductPoint> get positivePoints {
    final points = <ProductPoint>[];
    if (fiber != null && fiber! >= 3) {
      points.add(ProductPoint('Bonne teneur en fibres', 'Les fibres favorisent la digestion et la satiété', PointImpact.positive));
    }
    if (proteins != null && proteins! >= 8) {
      points.add(ProductPoint('Riche en protéines', 'Les protéines contribuent au maintien de la masse musculaire', PointImpact.positive));
    }
    if (isOrganic) {
      points.add(ProductPoint('Produit biologique', 'Agriculture respectueuse de l\'environnement', PointImpact.positive));
    }
    if (isPalmOilFree) {
      points.add(ProductPoint('Sans huile de palme', 'Préserve les forêts tropicales', PointImpact.positive));
    }
    if (isVegan) {
      points.add(ProductPoint('Convient aux végans', 'Ne contient aucun produit d\'origine animale', PointImpact.positive));
    }
    if (salt != null && salt! < 0.3) {
      points.add(ProductPoint('Faible teneur en sel', 'Bon pour la tension artérielle', PointImpact.positive));
    }
    if (saturatedFat != null && saturatedFat! < 2) {
      points.add(ProductPoint('Peu de graisses saturées', 'Bon pour le système cardiovasculaire', PointImpact.positive));
    }
    if (sugars != null && sugars! < 5) {
      points.add(ProductPoint('Peu de sucres', 'Limite les pics de glycémie', PointImpact.positive));
    }
    if (novaGroup != null && novaGroup! <= 2) {
      points.add(ProductPoint('Peu transformé (NOVA ${novaGroup!})', 'Produit naturel ou peu transformé', PointImpact.positive));
    }
    return points;
  }

  /// Analyse les points négatifs du produit
  List<ProductPoint> get negativePoints {
    final points = <ProductPoint>[];
    if (calories != null && calories! > 400) {
      points.add(ProductPoint('Très calorique', '${calories!.toStringAsFixed(0)} kcal pour 100g', PointImpact.negative));
    } else if (calories != null && calories! > 250) {
      points.add(ProductPoint('Calorique', '${calories!.toStringAsFixed(0)} kcal pour 100g', PointImpact.moderate));
    }
    if (sugars != null && sugars! > 20) {
      points.add(ProductPoint('Trop de sucres', '${sugars!.toStringAsFixed(1)}g pour 100g - Risque de diabète et obésité', PointImpact.negative));
    } else if (sugars != null && sugars! > 10) {
      points.add(ProductPoint('Sucres en quantité élevée', '${sugars!.toStringAsFixed(1)}g pour 100g', PointImpact.moderate));
    }
    if (saturatedFat != null && saturatedFat! > 10) {
      points.add(ProductPoint('Trop de graisses saturées', '${saturatedFat!.toStringAsFixed(1)}g pour 100g - Risque cardiovasculaire', PointImpact.negative));
    } else if (saturatedFat != null && saturatedFat! > 5) {
      points.add(ProductPoint('Graisses saturées élevées', '${saturatedFat!.toStringAsFixed(1)}g pour 100g', PointImpact.moderate));
    }
    if (salt != null && salt! > 1.5) {
      points.add(ProductPoint('Trop de sel', '${salt!.toStringAsFixed(2)}g pour 100g - Risque d\'hypertension', PointImpact.negative));
    } else if (salt != null && salt! > 0.5) {
      points.add(ProductPoint('Sel en quantité élevée', '${salt!.toStringAsFixed(2)}g pour 100g', PointImpact.moderate));
    }
    if (novaGroup != null && novaGroup! == 4) {
      points.add(ProductPoint('Ultra-transformé (NOVA 4)', 'Contient des additifs et procédés industriels', PointImpact.negative));
    } else if (novaGroup != null && novaGroup! == 3) {
      points.add(ProductPoint('Transformé (NOVA 3)', 'Produit ayant subi des transformations', PointImpact.moderate));
    }
    if (fat != null && fat! > 20) {
      points.add(ProductPoint('Trop de matières grasses', '${fat!.toStringAsFixed(1)}g pour 100g', PointImpact.negative));
    }
    return points;
  }

  /// Parse les additifs depuis le champ additives ou ingredients
  List<Additive> get parsedAdditives {
    final source = additives ?? ingredients ?? '';
    final regex = RegExp(r'E\d{3,4}[a-z]?', caseSensitive: false);
    final matches = regex.allMatches(source);
    return matches.map((m) => Additive.fromCode(m.group(0)!.toUpperCase())).toSet().toList();
  }

  /// Calcul de l'Eco-Score si non fourni par l'API
  String get computedEcoScore {
    if (ecoScore != null) return ecoScore!.toUpperCase();
    // Estimation basique basée sur les caractéristiques du produit
    int score = 50;
    if (isOrganic) score += 20;
    if (isPalmOilFree) score += 10;
    if (isVegan) score += 10;
    if (novaGroup != null) {
      if (novaGroup! <= 1) score += 10;
      if (novaGroup! >= 4) score -= 15;
    }
    if (score >= 80) return 'A';
    if (score >= 60) return 'B';
    if (score >= 40) return 'C';
    if (score >= 20) return 'D';
    return 'E';
  }
}

class ProductSearch {
  final int id;
  final String barcode;
  final String name;
  final String? brand;
  final String? imageUrl;
  final String? nutriScore;
  final int? healthScore;
  final String? categories;

  ProductSearch({
    required this.id,
    required this.barcode,
    required this.name,
    this.brand,
    this.imageUrl,
    this.nutriScore,
    this.healthScore,
    this.categories,
  });

  factory ProductSearch.fromJson(Map<String, dynamic> json) {
    return ProductSearch(
      id: json['id'] as int,
      barcode: json['barcode'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String?,
      imageUrl: json['imageUrl'] as String?,
      nutriScore: json['nutriScore'] as String?,
      healthScore: json['healthScore'] as int?,
      categories: json['categories'] as String?,
    );
  }
}

enum PointImpact { positive, moderate, negative }

class ProductPoint {
  final String title;
  final String description;
  final PointImpact impact;

  const ProductPoint(this.title, this.description, this.impact);
}

/// Représente un additif alimentaire avec son niveau de risque
class Additive {
  final String code;
  final String name;
  final AdditiveRisk risk;
  final String description;

  const Additive({
    required this.code,
    required this.name,
    required this.risk,
    required this.description,
  });

  factory Additive.fromCode(String code) {
    return _additiveDatabase[code] ?? Additive(
      code: code,
      name: 'Additif $code',
      risk: AdditiveRisk.unknown,
      description: 'Données non disponibles pour cet additif',
    );
  }
}

enum AdditiveRisk { none, limited, moderate, high, unknown }

/// Base de données des additifs les plus courants
const Map<String, Additive> _additiveDatabase = {
  'E100': Additive(code: 'E100', name: 'Curcumine', risk: AdditiveRisk.none, description: 'Colorant naturel jaune issu du curcuma'),
  'E101': Additive(code: 'E101', name: 'Riboflavine (B2)', risk: AdditiveRisk.none, description: 'Vitamine B2, colorant jaune naturel'),
  'E110': Additive(code: 'E110', name: 'Jaune orangé S', risk: AdditiveRisk.high, description: 'Colorant azoïque synthétique, controversé'),
  'E120': Additive(code: 'E120', name: 'Cochenille', risk: AdditiveRisk.moderate, description: 'Colorant rouge d\'origine animale, peut provoquer des allergies'),
  'E122': Additive(code: 'E122', name: 'Azorubine', risk: AdditiveRisk.high, description: 'Colorant azoïque rouge synthétique'),
  'E124': Additive(code: 'E124', name: 'Ponceau 4R', risk: AdditiveRisk.high, description: 'Colorant rouge synthétique, effet possible sur l\'activité des enfants'),
  'E129': Additive(code: 'E129', name: 'Rouge allura AC', risk: AdditiveRisk.high, description: 'Colorant azoïque synthétique controversé'),
  'E131': Additive(code: 'E131', name: 'Bleu patenté V', risk: AdditiveRisk.moderate, description: 'Colorant bleu synthétique'),
  'E132': Additive(code: 'E132', name: 'Indigotine', risk: AdditiveRisk.limited, description: 'Colorant bleu, risque allergique faible'),
  'E133': Additive(code: 'E133', name: 'Bleu brillant FCF', risk: AdditiveRisk.limited, description: 'Colorant bleu synthétique'),
  'E140': Additive(code: 'E140', name: 'Chlorophylle', risk: AdditiveRisk.none, description: 'Colorant vert naturel issu des plantes'),
  'E150a': Additive(code: 'E150a', name: 'Caramel E150a', risk: AdditiveRisk.none, description: 'Caramel ordinaire, sans risque'),
  'E150b': Additive(code: 'E150b', name: 'Caramel de sulfite caustique', risk: AdditiveRisk.moderate, description: 'Caramel pouvant contenir des résidus de sulfite'),
  'E150c': Additive(code: 'E150c', name: 'Caramel ammoniacal', risk: AdditiveRisk.moderate, description: 'Caramel contenant du 4-MEI potentiellement nocif'),
  'E150d': Additive(code: 'E150d', name: 'Caramel au sulfite d\'ammonium', risk: AdditiveRisk.high, description: 'Contient du 4-MEI classé cancérigène possible'),
  'E160a': Additive(code: 'E160a', name: 'Bêta-carotène', risk: AdditiveRisk.none, description: 'Provitamine A, colorant orange naturel'),
  'E160b': Additive(code: 'E160b', name: 'Annatto', risk: AdditiveRisk.limited, description: 'Colorant orange naturel'),
  'E162': Additive(code: 'E162', name: 'Rouge de betterave', risk: AdditiveRisk.none, description: 'Colorant rouge naturel issu de la betterave'),
  'E170': Additive(code: 'E170', name: 'Carbonate de calcium', risk: AdditiveRisk.none, description: 'Minéral naturel, sans danger'),
  'E200': Additive(code: 'E200', name: 'Acide sorbique', risk: AdditiveRisk.limited, description: 'Conservateur, peut irriter la peau'),
  'E202': Additive(code: 'E202', name: 'Sorbate de potassium', risk: AdditiveRisk.limited, description: 'Conservateur courant, faible risque allergique'),
  'E210': Additive(code: 'E210', name: 'Acide benzoïque', risk: AdditiveRisk.moderate, description: 'Conservateur pouvant provoquer des allergies'),
  'E211': Additive(code: 'E211', name: 'Benzoate de sodium', risk: AdditiveRisk.moderate, description: 'Conservateur, peut former du benzène avec la vitamine C'),
  'E220': Additive(code: 'E220', name: 'Dioxyde de soufre', risk: AdditiveRisk.high, description: 'Conservateur pouvant provoquer des crises d\'asthme'),
  'E221': Additive(code: 'E221', name: 'Sulfite de sodium', risk: AdditiveRisk.high, description: 'Conservateur, risque allergique élevé pour les asthmatiques'),
  'E223': Additive(code: 'E223', name: 'Disulfite de sodium', risk: AdditiveRisk.high, description: 'Conservateur sulfité, allergisant'),
  'E249': Additive(code: 'E249', name: 'Nitrite de potassium', risk: AdditiveRisk.high, description: 'Conservateur de charcuterie, cancérigène probable'),
  'E250': Additive(code: 'E250', name: 'Nitrite de sodium', risk: AdditiveRisk.high, description: 'Conservateur de charcuterie, classé cancérigène probable'),
  'E251': Additive(code: 'E251', name: 'Nitrate de sodium', risk: AdditiveRisk.high, description: 'Se transforme en nitrites, cancérigène probable'),
  'E252': Additive(code: 'E252', name: 'Nitrate de potassium', risk: AdditiveRisk.high, description: 'Se transforme en nitrites dans l\'organisme'),
  'E270': Additive(code: 'E270', name: 'Acide lactique', risk: AdditiveRisk.none, description: 'Conservateur naturel, sans danger'),
  'E300': Additive(code: 'E300', name: 'Acide ascorbique (Vitamine C)', risk: AdditiveRisk.none, description: 'Antioxydant naturel, vitamine C'),
  'E301': Additive(code: 'E301', name: 'Ascorbate de sodium', risk: AdditiveRisk.none, description: 'Forme de vitamine C, antioxydant'),
  'E306': Additive(code: 'E306', name: 'Tocophérols (Vitamine E)', risk: AdditiveRisk.none, description: 'Antioxydant naturel, vitamine E'),
  'E307': Additive(code: 'E307', name: 'Alpha-tocophérol', risk: AdditiveRisk.none, description: 'Vitamine E synthétique, antioxydant'),
  'E310': Additive(code: 'E310', name: 'Gallate de propyle', risk: AdditiveRisk.moderate, description: 'Antioxydant pouvant provoquer des allergies'),
  'E320': Additive(code: 'E320', name: 'BHA', risk: AdditiveRisk.high, description: 'Antioxydant synthétique, cancérigène possible'),
  'E321': Additive(code: 'E321', name: 'BHT', risk: AdditiveRisk.high, description: 'Antioxydant synthétique, perturbateur endocrinien suspecté'),
  'E322': Additive(code: 'E322', name: 'Lécithine', risk: AdditiveRisk.none, description: 'Émulsifiant naturel, souvent issu du soja'),
  'E330': Additive(code: 'E330', name: 'Acide citrique', risk: AdditiveRisk.none, description: 'Acidifiant naturel, présent dans les agrumes'),
  'E331': Additive(code: 'E331', name: 'Citrate de sodium', risk: AdditiveRisk.none, description: 'Régulateur d\'acidité, sans danger'),
  'E332': Additive(code: 'E332', name: 'Citrate de potassium', risk: AdditiveRisk.none, description: 'Régulateur d\'acidité naturel'),
  'E338': Additive(code: 'E338', name: 'Acide phosphorique', risk: AdditiveRisk.moderate, description: 'Acidifiant, peut réduire l\'absorption du calcium'),
  'E339': Additive(code: 'E339', name: 'Phosphate de sodium', risk: AdditiveRisk.moderate, description: 'Émulsifiant, excès néfaste pour les reins'),
  'E340': Additive(code: 'E340', name: 'Phosphate de potassium', risk: AdditiveRisk.limited, description: 'Régulateur d\'acidité'),
  'E341': Additive(code: 'E341', name: 'Phosphate de calcium', risk: AdditiveRisk.limited, description: 'Agent de levée, anti-agglomérant'),
  'E392': Additive(code: 'E392', name: 'Extraits de romarin', risk: AdditiveRisk.none, description: 'Antioxydant naturel'),
  'E400': Additive(code: 'E400', name: 'Acide alginique', risk: AdditiveRisk.none, description: 'Épaississant naturel issu des algues'),
  'E401': Additive(code: 'E401', name: 'Alginate de sodium', risk: AdditiveRisk.none, description: 'Gélifiant naturel issu des algues'),
  'E406': Additive(code: 'E406', name: 'Agar-agar', risk: AdditiveRisk.none, description: 'Gélifiant naturel végétal'),
  'E407': Additive(code: 'E407', name: 'Carraghénanes', risk: AdditiveRisk.moderate, description: 'Épaississant controversé, peut irriter l\'intestin'),
  'E410': Additive(code: 'E410', name: 'Gomme de caroube', risk: AdditiveRisk.none, description: 'Épaississant naturel'),
  'E412': Additive(code: 'E412', name: 'Gomme de guar', risk: AdditiveRisk.none, description: 'Épaississant naturel issu des graines de guar'),
  'E414': Additive(code: 'E414', name: 'Gomme arabique', risk: AdditiveRisk.none, description: 'Épaississant naturel'),
  'E415': Additive(code: 'E415', name: 'Gomme xanthane', risk: AdditiveRisk.none, description: 'Épaississant, peut causer des ballonnements'),
  'E420': Additive(code: 'E420', name: 'Sorbitol', risk: AdditiveRisk.limited, description: 'Édulcorant, effet laxatif à forte dose'),
  'E421': Additive(code: 'E421', name: 'Mannitol', risk: AdditiveRisk.limited, description: 'Édulcorant, effet laxatif à forte dose'),
  'E422': Additive(code: 'E422', name: 'Glycérol', risk: AdditiveRisk.none, description: 'Humectant, sans danger'),
  'E440': Additive(code: 'E440', name: 'Pectine', risk: AdditiveRisk.none, description: 'Gélifiant naturel issu des fruits'),
  'E450': Additive(code: 'E450', name: 'Diphosphates', risk: AdditiveRisk.moderate, description: 'Agent levant, excès néfaste pour les reins'),
  'E451': Additive(code: 'E451', name: 'Triphosphates', risk: AdditiveRisk.moderate, description: 'Émulsifiant, peut perturber l\'équilibre phosphocalcique'),
  'E460': Additive(code: 'E460', name: 'Cellulose', risk: AdditiveRisk.none, description: 'Fibre végétale, sans danger'),
  'E466': Additive(code: 'E466', name: 'Carboxyméthylcellulose', risk: AdditiveRisk.moderate, description: 'Épaississant, peut altérer le microbiote'),
  'E471': Additive(code: 'E471', name: 'Mono- et diglycérides', risk: AdditiveRisk.limited, description: 'Émulsifiant, risque limité'),
  'E472': Additive(code: 'E472', name: 'Esters de mono-/diglycérides', risk: AdditiveRisk.limited, description: 'Émulsifiant courant'),
  'E500': Additive(code: 'E500', name: 'Bicarbonate de sodium', risk: AdditiveRisk.none, description: 'Agent levant naturel'),
  'E501': Additive(code: 'E501', name: 'Carbonate de potassium', risk: AdditiveRisk.none, description: 'Régulateur d\'acidité'),
  'E503': Additive(code: 'E503', name: 'Carbonate d\'ammonium', risk: AdditiveRisk.none, description: 'Agent levant, s\'évapore à la cuisson'),
  'E504': Additive(code: 'E504', name: 'Carbonate de magnésium', risk: AdditiveRisk.none, description: 'Anti-agglomérant, sans danger'),
  'E509': Additive(code: 'E509', name: 'Chlorure de calcium', risk: AdditiveRisk.none, description: 'Affermissant, sel naturel'),
  'E516': Additive(code: 'E516', name: 'Sulfate de calcium', risk: AdditiveRisk.none, description: 'Plâtre alimentaire, sans danger'),
  'E621': Additive(code: 'E621', name: 'Glutamate monosodique', risk: AdditiveRisk.moderate, description: 'Exhausteur de goût, peut provoquer des maux de tête'),
  'E627': Additive(code: 'E627', name: 'Guanylate disodique', risk: AdditiveRisk.moderate, description: 'Exhausteur de goût, à éviter pour les goutteux'),
  'E631': Additive(code: 'E631', name: 'Inosinate disodique', risk: AdditiveRisk.moderate, description: 'Exhausteur de goût, déconseillé aux goutteux'),
  'E635': Additive(code: 'E635', name: 'Ribonucléotide disodique', risk: AdditiveRisk.moderate, description: 'Exhausteur de goût'),
  'E900': Additive(code: 'E900', name: 'Diméthylpolysiloxane', risk: AdditiveRisk.limited, description: 'Anti-moussant, utilisé dans les huiles de friture'),
  'E901': Additive(code: 'E901', name: 'Cire d\'abeille', risk: AdditiveRisk.none, description: 'Agent d\'enrobage naturel'),
  'E903': Additive(code: 'E903', name: 'Cire de carnauba', risk: AdditiveRisk.none, description: 'Agent d\'enrobage naturel'),
  'E904': Additive(code: 'E904', name: 'Gomme laque', risk: AdditiveRisk.limited, description: 'Agent d\'enrobage d\'origine animale'),
  'E920': Additive(code: 'E920', name: 'L-Cystéine', risk: AdditiveRisk.limited, description: 'Agent de traitement des farines'),
  'E950': Additive(code: 'E950', name: 'Acésulfame K', risk: AdditiveRisk.moderate, description: 'Édulcorant artificiel, effets à long terme débattus'),
  'E951': Additive(code: 'E951', name: 'Aspartame', risk: AdditiveRisk.high, description: 'Édulcorant artificiel, classé cancérigène possible par l\'OMS'),
  'E952': Additive(code: 'E952', name: 'Cyclamate', risk: AdditiveRisk.high, description: 'Édulcorant artificiel, interdit dans certains pays'),
  'E953': Additive(code: 'E953', name: 'Isomalt', risk: AdditiveRisk.limited, description: 'Édulcorant, effet laxatif à forte dose'),
  'E954': Additive(code: 'E954', name: 'Saccharine', risk: AdditiveRisk.moderate, description: 'Édulcorant artificiel, controversé'),
  'E955': Additive(code: 'E955', name: 'Sucralose', risk: AdditiveRisk.moderate, description: 'Édulcorant artificiel, peut altérer le microbiote'),
  'E960': Additive(code: 'E960', name: 'Stéviol', risk: AdditiveRisk.limited, description: 'Édulcorant d\'origine naturelle (stévia)'),
  'E965': Additive(code: 'E965', name: 'Maltitol', risk: AdditiveRisk.limited, description: 'Édulcorant, effet laxatif possible'),
  'E966': Additive(code: 'E966', name: 'Lactitol', risk: AdditiveRisk.limited, description: 'Édulcorant, effet laxatif'),
  'E967': Additive(code: 'E967', name: 'Xylitol', risk: AdditiveRisk.limited, description: 'Édulcorant, bon pour les dents mais laxatif'),
  'E968': Additive(code: 'E968', name: 'Érythritol', risk: AdditiveRisk.none, description: 'Édulcorant naturel bien toléré'),
};

class ScanHistoryItem {
  final int id;
  final ProductSearch product;
  final DateTime scannedAt;

  ScanHistoryItem({
    required this.id,
    required this.product,
    required this.scannedAt,
  });

  factory ScanHistoryItem.fromJson(Map<String, dynamic> json) {
    return ScanHistoryItem(
      id: json['id'] as int,
      product: ProductSearch.fromJson(json['product'] as Map<String, dynamic>),
      scannedAt: DateTime.parse(json['scannedAt'] as String),
    );
  }
}
