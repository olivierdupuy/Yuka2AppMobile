import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../services/tracking_service.dart';
import '../theme/app_theme.dart';
import '../widgets/nutri_score_badge.dart';
import '../widgets/eco_score_badge.dart';
import '../providers/auth_provider.dart';
import '../providers/compare_provider.dart';
import '../providers/review_provider.dart';
import '../providers/shopping_list_provider.dart';
import '../models/allergen_check.dart';
import '../widgets/star_rating.dart';
import '../widgets/allergen_banner.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  AllergenCheckResult? _allergenCheck;

  @override
  void initState() {
    super.initState();
    try {
      TrackingService.instance.trackPageView('product_detail');
      TrackingService.instance.trackEvent('product_view', data: {'productId': widget.productId});
    } catch (_) {}
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProductProvider>();
      provider.loadProductById(widget.productId).then((_) async {
        final product = provider.selectedProduct;
        if (product != null) {
          provider.loadAlternatives(product.categories, product.healthScore, product.id);
          // Check allergens
          final auth = context.read<AuthProvider>();
          if (auth.isAuthenticated) {
            final result = await auth.api.checkAllergens(product.id);
            if (mounted) setState(() => _allergenCheck = result);
            // Load reviews
            context.read<ReviewProvider>().loadReviews(product.id);
          }
        }
      });
    });
  }

  void _shareProduct(Product product) {
    final text = StringBuffer();
    text.writeln('${product.name}${product.brand != null ? ' - ${product.brand}' : ''}');
    text.writeln('Score santé : ${product.healthScore ?? '?'}/100 (${product.qualityLabel})');
    text.writeln('Nutri-Score : ${product.nutriScore ?? '?'}');
    text.writeln('Eco-Score : ${product.computedEcoScore}');
    if (product.novaGroup != null) text.writeln('NOVA : ${product.novaGroup}');
    text.writeln('');
    text.writeln('Analysé avec Yuka2');

    Clipboard.setData(ClipboardData(text: text.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Analyse copiée dans le presse-papier', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
          ],
        ),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final product = provider.selectedProduct;

    return Scaffold(
      body: product == null
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : CustomScrollView(
              slivers: [
                // ==================== HERO HEADER ====================
                SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.healthScoreColor(product.healthScore),
                          AppTheme.healthScoreColor(product.healthScore).withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top bar
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                                  ),
                                ),
                                Row(
                                  children: [
                                    // Compare button
                                    Consumer<CompareProvider>(
                                      builder: (ctx, compareProv, _) => GestureDetector(
                                        onTap: () => compareProv.toggleProduct(ProductSearch(
                                          id: product.id, barcode: product.barcode, name: product.name,
                                          brand: product.brand, imageUrl: product.imageUrl,
                                          nutriScore: product.nutriScore, healthScore: product.healthScore,
                                          categories: product.categories,
                                        )),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(Icons.compare_arrows, color: Colors.white, size: 22),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Add to shopping list button
                                    GestureDetector(
                                      onTap: () => _showAddToListSheet(product),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.add_shopping_cart, color: Colors.white, size: 22),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Share button
                                    GestureDetector(
                                      onTap: () => _shareProduct(product),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.share_rounded, color: Colors.white, size: 22),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (product.quantity != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          product.quantity!,
                                          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Score circle + quality label
                            Center(
                              child: Column(
                                children: [
                                  CircularPercentIndicator(
                                    radius: 60,
                                    lineWidth: 10,
                                    percent: (product.healthScore ?? 0) / 100,
                                    center: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${product.healthScore ?? '?'}',
                                          style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white),
                                        ),
                                        Text(
                                          '/100',
                                          style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
                                        ),
                                      ],
                                    ),
                                    progressColor: Colors.white,
                                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                                    circularStrokeCap: CircularStrokeCap.round,
                                  ).animate().scale(begin: const Offset(0.5, 0.5), duration: 500.ms, curve: Curves.elasticOut),
                                  const SizedBox(height: 12),

                                  // Quality label like Yuka
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _qualityIcon(product.healthScore),
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          product.qualityLabel,
                                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Product name & brand
                            Center(
                              child: Column(
                                children: [
                                  Text(
                                    product.name,
                                    style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (product.brand != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      product.brand!,
                                      style: GoogleFonts.inter(fontSize: 16, color: Colors.white.withValues(alpha: 0.85)),
                                    ),
                                  ],
                                ],
                              ),
                            ).animate().fadeIn(delay: 200.ms),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                if (_allergenCheck != null && _allergenCheck!.hasAlert)
                  SliverToBoxAdapter(
                    child: AllergenBanner(matchedAllergens: _allergenCheck!.matchedAllergens),
                  ),

                // ==================== CONTENT ====================
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    transform: Matrix4.translationValues(0, -24, 0),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ==================== POSITIVE/NEGATIVE POINTS ====================
                          if (product.positivePoints.isNotEmpty || product.negativePoints.isNotEmpty)
                            _buildPointsSummary(product).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),

                          if (product.positivePoints.isNotEmpty || product.negativePoints.isNotEmpty)
                            const SizedBox(height: 16),

                          // ==================== NUTRI-SCORE ====================
                          _SectionCard(
                            title: 'Nutri-Score',
                            child: Center(
                              child: NutriScoreBadge(score: product.nutriScore, size: 44),
                            ),
                          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

                          const SizedBox(height: 16),

                          // ==================== ECO-SCORE ====================
                          _SectionCard(
                            title: 'Eco-Score',
                            subtitle: 'Impact environnemental',
                            icon: Icons.eco_rounded,
                            iconColor: EcoScoreBadge.ecoScoreColor(product.computedEcoScore),
                            child: Column(
                              children: [
                                Center(
                                  child: EcoScoreBadge(score: product.computedEcoScore, size: 44),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _ecoScoreDescription(product.computedEcoScore),
                                  style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 320.ms).slideY(begin: 0.1),

                          const SizedBox(height: 16),

                          // ==================== BADGES ====================
                          Row(
                            children: [
                              if (product.isOrganic)
                                _Badge(label: 'Bio', icon: Icons.eco_rounded, color: AppTheme.nutriA),
                              if (product.isPalmOilFree)
                                _Badge(label: 'Sans huile de palme', icon: Icons.block_rounded, color: AppTheme.nutriB),
                              if (product.isVegan)
                                _Badge(label: 'Vegan', icon: Icons.spa_rounded, color: const Color(0xFF7CB342)),
                            ].map((w) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: w))).toList(),
                          ).animate().fadeIn(delay: 350.ms),

                          const SizedBox(height: 16),

                          // ==================== NOVA GROUP ====================
                          if (product.novaGroup != null)
                            _SectionCard(
                              title: 'Groupe NOVA',
                              subtitle: 'Niveau de transformation',
                              child: Row(
                                children: [
                                  Container(
                                    width: 44, height: 44,
                                    decoration: BoxDecoration(color: _novaColor(product.novaGroup!), borderRadius: BorderRadius.circular(12)),
                                    alignment: Alignment.center,
                                    child: Text('${product.novaGroup}', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _novaLabel(product.novaGroup!),
                                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _novaDescription(product.novaGroup!),
                                          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

                          const SizedBox(height: 16),

                          // ==================== NUTRITION FACTS ====================
                          _SectionCard(
                            title: 'Valeurs nutritionnelles (100g)',
                            child: Column(
                              children: [
                                _NutrientRow(label: 'Calories', value: '${product.calories?.toStringAsFixed(0) ?? '-'} kcal', level: _calorieLevel(product.calories)),
                                _NutrientRow(label: 'Matières grasses', value: '${product.fat?.toStringAsFixed(1) ?? '-'} g', level: _fatLevel(product.fat)),
                                _NutrientRow(label: '  dont saturées', value: '${product.saturatedFat?.toStringAsFixed(1) ?? '-'} g', level: _satFatLevel(product.saturatedFat), isSubRow: true),
                                _NutrientRow(label: 'Glucides', value: '${product.carbohydrates?.toStringAsFixed(1) ?? '-'} g'),
                                _NutrientRow(label: '  dont sucres', value: '${product.sugars?.toStringAsFixed(1) ?? '-'} g', level: _sugarLevel(product.sugars), isSubRow: true),
                                _NutrientRow(label: 'Fibres', value: '${product.fiber?.toStringAsFixed(1) ?? '-'} g', level: _fiberLevel(product.fiber), isGood: true),
                                _NutrientRow(label: 'Protéines', value: '${product.proteins?.toStringAsFixed(1) ?? '-'} g'),
                                _NutrientRow(label: 'Sel', value: '${product.salt?.toStringAsFixed(2) ?? '-'} g', level: _saltLevel(product.salt)),
                              ],
                            ),
                          ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1),

                          const SizedBox(height: 16),

                          // ==================== ADDITIVES ANALYSIS ====================
                          if (product.parsedAdditives.isNotEmpty)
                            _buildAdditivesSection(product).animate().fadeIn(delay: 480.ms).slideY(begin: 0.1),

                          if (product.parsedAdditives.isNotEmpty)
                            const SizedBox(height: 16),

                          // ==================== INGREDIENTS ====================
                          if (product.ingredients != null && product.ingredients!.isNotEmpty)
                            _SectionCard(
                              title: 'Ingrédients',
                              child: Text(
                                product.ingredients!,
                                style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
                              ),
                            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),

                          const SizedBox(height: 16),

                          // ==================== ALLERGENS ====================
                          if (product.allergens != null && product.allergens!.isNotEmpty)
                            _SectionCard(
                              title: 'Allergènes',
                              icon: Icons.warning_amber_rounded,
                              iconColor: AppTheme.nutriE,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: product.allergens!.split(',').map((a) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.nutriE.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppTheme.nutriE.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.warning_rounded, size: 14, color: AppTheme.nutriE.withValues(alpha: 0.7)),
                                      const SizedBox(width: 4),
                                      Text(
                                        a.trim(),
                                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.nutriE),
                                      ),
                                    ],
                                  ),
                                )).toList(),
                              ),
                            ).animate().fadeIn(delay: 550.ms).slideY(begin: 0.1),

                          const SizedBox(height: 16),

                          // ==================== BETTER ALTERNATIVES ====================
                          if (provider.alternatives.isNotEmpty)
                            _buildAlternativesSection(provider.alternatives).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),

                          // ==================== REVIEWS SECTION ====================
                          const SizedBox(height: 16),
                          Consumer<ReviewProvider>(
                            builder: (ctx, reviewProv, _) => _SectionCard(
                              title: 'Avis & Notes',
                              icon: Icons.star_rounded,
                              iconColor: const Color(0xFFFFA726),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if ((reviewProv.summary?.averageRating ?? 0) > 0) ...[
                                    Row(
                                      children: [
                                        Text(
                                          (reviewProv.summary?.averageRating ?? 0).toStringAsFixed(1),
                                          style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            StarRating(rating: reviewProv.summary?.averageRating ?? 0, size: 22),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${(reviewProv.summary?.reviews ?? []).length} avis',
                                              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  if ((reviewProv.summary?.reviews ?? []).isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: Center(
                                        child: Text(
                                          'Aucun avis pour le moment',
                                          style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary),
                                        ),
                                      ),
                                    )
                                  else
                                    ...(reviewProv.summary?.reviews ?? []).take(5).map((review) => Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surface,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              StarRating(rating: review.rating.toDouble(), size: 16),
                                              const Spacer(),
                                              Text(
                                                review.username.isEmpty ? 'Anonyme' : review.username,
                                                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                          if (review.comment != null && review.comment!.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Text(
                                              review.comment!,
                                              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textPrimary, height: 1.4),
                                            ),
                                          ],
                                        ],
                                      ),
                                    )),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () => _showReviewSheet(product.id),
                                      icon: const Icon(Icons.rate_review_rounded),
                                      label: const Text('Laisser un avis'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFF1B5E20),
                                        side: const BorderSide(color: Color(0xFF1B5E20)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ).animate().fadeIn(delay: 620.ms).slideY(begin: 0.1),

                          // ==================== COMPARE BUTTON ====================
                          const SizedBox(height: 16),
                          _buildCompareButton(product).animate().fadeIn(delay: 650.ms).slideY(begin: 0.1),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ==================== POSITIVE/NEGATIVE POINTS WIDGET ====================
  Widget _buildPointsSummary(Product product) {
    return _SectionCard(
      title: 'Analyse du produit',
      icon: Icons.analytics_rounded,
      iconColor: AppTheme.healthScoreColor(product.healthScore),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Negative points first (like Yuka)
          if (product.negativePoints.isNotEmpty) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: AppTheme.nutriE.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: const Icon(Icons.remove_circle_rounded, color: AppTheme.nutriE, size: 16),
                ),
                const SizedBox(width: 8),
                Text('Points négatifs', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.nutriE)),
              ],
            ),
            const SizedBox(height: 8),
            ...product.negativePoints.map((p) => _PointRow(point: p)),
            const SizedBox(height: 16),
          ],

          // Positive points
          if (product.positivePoints.isNotEmpty) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: AppTheme.nutriA.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: const Icon(Icons.add_circle_rounded, color: AppTheme.nutriA, size: 16),
                ),
                const SizedBox(width: 8),
                Text('Points positifs', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.nutriA)),
              ],
            ),
            const SizedBox(height: 8),
            ...product.positivePoints.map((p) => _PointRow(point: p)),
          ],
        ],
      ),
    );
  }

  // ==================== ADDITIVES SECTION ====================
  Widget _buildAdditivesSection(Product product) {
    final additives = product.parsedAdditives;
    final highRisk = additives.where((a) => a.risk == AdditiveRisk.high).length;
    final modRisk = additives.where((a) => a.risk == AdditiveRisk.moderate).length;

    return _SectionCard(
      title: 'Additifs (${additives.length})',
      icon: Icons.science_rounded,
      iconColor: highRisk > 0 ? AppTheme.nutriE : modRisk > 0 ? AppTheme.nutriD : AppTheme.nutriA,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: (highRisk > 0 ? AppTheme.nutriE : modRisk > 0 ? AppTheme.nutriD : AppTheme.nutriA).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  highRisk > 0 ? Icons.error_rounded : modRisk > 0 ? Icons.warning_rounded : Icons.check_circle_rounded,
                  color: highRisk > 0 ? AppTheme.nutriE : modRisk > 0 ? AppTheme.nutriD : AppTheme.nutriA,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    highRisk > 0
                        ? '$highRisk additif(s) à risque élevé détecté(s)'
                        : modRisk > 0
                            ? '$modRisk additif(s) à risque modéré'
                            : 'Aucun additif à risque détecté',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: highRisk > 0 ? AppTheme.nutriE : modRisk > 0 ? AppTheme.nutriD : AppTheme.nutriA,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Additive list
          ...additives.map((additive) => _AdditiveRow(additive: additive)),
        ],
      ),
    );
  }

  // ==================== ALTERNATIVES SECTION ====================
  Widget _buildAlternativesSection(List<ProductSearch> alternatives) {
    return _SectionCard(
      title: 'Meilleures alternatives',
      icon: Icons.swap_horiz_rounded,
      iconColor: AppTheme.nutriA,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Produits similaires avec un meilleur score',
            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          ...alternatives.take(3).map((alt) => _AlternativeRow(
            product: alt,
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: alt.id)),
            ),
          )),
        ],
      ),
    );
  }

  // ==================== COMPARE BUTTON ====================
  Widget _buildCompareButton(Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => _CompareSelectionScreen(baseProduct: product)),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: const Color(0xFF1565C0).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.compare_arrows_rounded, color: Colors.white, size: 24),
            const SizedBox(width: 10),
            Text(
              'Comparer avec un autre produit',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== HELPERS ====================
  IconData _qualityIcon(int? score) {
    if (score == null) return Icons.help_outline_rounded;
    if (score >= 75) return Icons.sentiment_very_satisfied_rounded;
    if (score >= 50) return Icons.sentiment_satisfied_rounded;
    if (score >= 25) return Icons.sentiment_dissatisfied_rounded;
    return Icons.sentiment_very_dissatisfied_rounded;
  }

  Color _novaColor(int group) {
    switch (group) {
      case 1: return AppTheme.nutriA;
      case 2: return AppTheme.nutriB;
      case 3: return AppTheme.nutriD;
      case 4: return AppTheme.nutriE;
      default: return Colors.grey;
    }
  }

  String _novaLabel(int group) {
    switch (group) {
      case 1: return 'Aliments non transformés ou transformés minimalement';
      case 2: return 'Ingrédients culinaires transformés';
      case 3: return 'Aliments transformés';
      case 4: return 'Produits alimentaires ultra-transformés';
      default: return 'Inconnu';
    }
  }

  String _novaDescription(int group) {
    switch (group) {
      case 1: return 'Fruits, légumes, oeufs, viande fraîche...';
      case 2: return 'Huile, beurre, sucre, sel, farine...';
      case 3: return 'Conserves, fromages, pains artisanaux...';
      case 4: return 'Sodas, chips, plats préparés, charcuterie...';
      default: return '';
    }
  }

  String _ecoScoreDescription(String score) {
    switch (score) {
      case 'A': return 'Très faible impact environnemental';
      case 'B': return 'Faible impact environnemental';
      case 'C': return 'Impact environnemental modéré';
      case 'D': return 'Impact environnemental élevé';
      case 'E': return 'Impact environnemental très élevé';
      default: return 'Impact environnemental non évalué';
    }
  }

  int _calorieLevel(double? v) => v == null ? 0 : v > 400 ? 3 : v > 200 ? 2 : 1;
  int _fatLevel(double? v) => v == null ? 0 : v > 20 ? 3 : v > 10 ? 2 : 1;
  int _satFatLevel(double? v) => v == null ? 0 : v > 10 ? 3 : v > 5 ? 2 : 1;
  int _sugarLevel(double? v) => v == null ? 0 : v > 20 ? 3 : v > 10 ? 2 : 1;
  int _saltLevel(double? v) => v == null ? 0 : v > 1.5 ? 3 : v > 0.5 ? 2 : 1;
  int _fiberLevel(double? v) => v == null ? 0 : v > 3 ? 1 : v > 1 ? 2 : 3;

  void _showAddToListSheet(Product product) {
    final provider = context.read<ShoppingListProvider>();
    provider.loadLists();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Consumer<ShoppingListProvider>(
        builder: (ctx, listProvider, _) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ajouter à une liste', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                if (listProvider.lists.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: Text('Aucune liste. Créez-en une depuis le profil.')),
                  )
                else
                  ...listProvider.lists.map((list) => ListTile(
                    leading: const Icon(Icons.list_alt, color: Color(0xFF1B5E20)),
                    title: Text(list.name),
                    subtitle: Text('${list.itemCount} articles'),
                    onTap: () async {
                      await listProvider.addItem(list.id, productId: product.id, name: product.name);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Ajouté à "${list.name}"'), backgroundColor: const Color(0xFF1B5E20)),
                        );
                      }
                    },
                  )),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showReviewSheet(int productId) {
    int rating = 0;
    final commentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: StatefulBuilder(
          builder: (ctx, setSheetState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Laisser un avis', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Center(
                child: StarRating(
                  rating: rating.toDouble(),
                  size: 40,
                  onRatingChanged: (val) => setSheetState(() => rating = val),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Votre commentaire (optionnel)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: rating > 0
                      ? () async {
                          final success = await context.read<ReviewProvider>().submitReview(
                            productId, rating, commentController.text.trim().isEmpty ? null : commentController.text.trim(),
                          );
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Avis publié !'), backgroundColor: Color(0xFF1B5E20)),
                              );
                            }
                          }
                        }
                      : null,
                  child: const Text('Publier'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== SECTION CARD ====================
class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final IconData? icon;
  final Color? iconColor;

  const _SectionCard({required this.title, required this.child, this.subtitle, this.icon, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: (iconColor ?? AppTheme.primary).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor ?? AppTheme.primary, size: 16),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                    if (subtitle != null)
                      Text(subtitle!, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ==================== NUTRIENT ROW ====================
class _NutrientRow extends StatelessWidget {
  final String label;
  final String value;
  final int level;
  final bool isSubRow;
  final bool isGood;

  const _NutrientRow({
    required this.label,
    required this.value,
    this.level = 0,
    this.isSubRow = false,
    this.isGood = false,
  });

  Color get _levelColor {
    if (level == 0) return Colors.grey;
    if (isGood) {
      return level == 1 ? AppTheme.nutriA : level == 2 ? AppTheme.nutriC : AppTheme.nutriE;
    }
    return level == 1 ? AppTheme.nutriA : level == 2 ? AppTheme.nutriD : AppTheme.nutriE;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 10, left: isSubRow ? 8 : 0),
      child: Row(
        children: [
          if (level > 0)
            Container(
              width: 10, height: 10,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(color: _levelColor, shape: BoxShape.circle),
            ),
          if (level == 0) const SizedBox(width: 20),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: isSubRow ? 13 : 14,
                color: isSubRow ? AppTheme.textSecondary : AppTheme.textPrimary,
                fontWeight: isSubRow ? FontWeight.w400 : FontWeight.w500,
              ),
            ),
          ),
          Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}

// ==================== BADGE ====================
class _Badge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _Badge({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: color), textAlign: TextAlign.center, maxLines: 2),
        ],
      ),
    );
  }
}

// ==================== POINT ROW (positive/negative) ====================
class _PointRow extends StatelessWidget {
  final ProductPoint point;

  const _PointRow({required this.point});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    switch (point.impact) {
      case PointImpact.positive:
        color = AppTheme.nutriA;
        icon = Icons.check_circle_rounded;
        break;
      case PointImpact.moderate:
        color = AppTheme.nutriD;
        icon = Icons.error_rounded;
        break;
      case PointImpact.negative:
        color = AppTheme.nutriE;
        icon = Icons.cancel_rounded;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(point.title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                Text(point.description, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== ADDITIVE ROW ====================
class _AdditiveRow extends StatelessWidget {
  final Additive additive;

  const _AdditiveRow({required this.additive});

  Color get _riskColor {
    switch (additive.risk) {
      case AdditiveRisk.none: return AppTheme.nutriA;
      case AdditiveRisk.limited: return AppTheme.nutriB;
      case AdditiveRisk.moderate: return AppTheme.nutriD;
      case AdditiveRisk.high: return AppTheme.nutriE;
      case AdditiveRisk.unknown: return Colors.grey;
    }
  }

  String get _riskLabel {
    switch (additive.risk) {
      case AdditiveRisk.none: return 'Sans risque';
      case AdditiveRisk.limited: return 'Risque limité';
      case AdditiveRisk.moderate: return 'Risque modéré';
      case AdditiveRisk.high: return 'Risque élevé';
      case AdditiveRisk.unknown: return 'Risque inconnu';
    }
  }

  IconData get _riskIcon {
    switch (additive.risk) {
      case AdditiveRisk.none: return Icons.check_circle_rounded;
      case AdditiveRisk.limited: return Icons.info_rounded;
      case AdditiveRisk.moderate: return Icons.warning_rounded;
      case AdditiveRisk.high: return Icons.dangerous_rounded;
      case AdditiveRisk.unknown: return Icons.help_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _riskColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _riskColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: _riskColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Icon(_riskIcon, color: _riskColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(additive.code, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: _riskColor)),
                    const SizedBox(width: 6),
                    Text('- ${additive.name}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(additive.description, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: _riskColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                  child: Text(_riskLabel, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: _riskColor)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== ALTERNATIVE ROW ====================
class _AlternativeRow extends StatelessWidget {
  final ProductSearch product;
  final VoidCallback onTap;

  const _AlternativeRow({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scoreColor = AppTheme.healthScoreColor(product.healthScore);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.nutriA.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.nutriA.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: scoreColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text('${product.healthScore ?? '?'}', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: scoreColor)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(product.brand ?? '', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.nutriScoreColor(product.nutriScore).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(product.nutriScore ?? '?', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.nutriScoreColor(product.nutriScore))),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

// ==================== COMPARE SELECTION SCREEN ====================
class _CompareSelectionScreen extends StatelessWidget {
  final Product baseProduct;

  const _CompareSelectionScreen({required this.baseProduct});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final products = provider.products.where((p) => p.id != baseProduct.id).toList();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text('Comparer avec...', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: products.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.compare_arrows_rounded, size: 56, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text('Aucun produit disponible pour la comparaison', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                final scoreColor = AppTheme.healthScoreColor(product.healthScore);
                return GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CompareScreen(
                          productId1: baseProduct.id,
                          productId2: product.id,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(color: scoreColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                          alignment: Alignment.center,
                          child: Text('${product.healthScore ?? '?'}', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: scoreColor)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product.name, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text(product.brand ?? '', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                        NutriScoreBadge(score: product.nutriScore, size: 22),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: Duration(milliseconds: index * 40)).slideX(begin: 0.05);
              },
            ),
    );
  }
}

// ==================== COMPARE SCREEN ====================
class CompareScreen extends StatefulWidget {
  final int productId1;
  final int productId2;

  const CompareScreen({super.key, required this.productId1, required this.productId2});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  Product? _product1;
  Product? _product2;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final provider = context.read<ProductProvider>();
    // Load both products
    await provider.loadProductById(widget.productId1);
    _product1 = provider.selectedProduct;
    await provider.loadProductById(widget.productId2);
    _product2 = provider.selectedProduct;
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text('Comparaison', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : (_product1 == null || _product2 == null)
              ? Center(child: Text('Erreur de chargement', style: GoogleFonts.inter(color: AppTheme.textSecondary)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Product headers
                      Row(
                        children: [
                          Expanded(child: _CompareProductHeader(product: _product1!)),
                          const SizedBox(width: 12),
                          Expanded(child: _CompareProductHeader(product: _product2!)),
                        ],
                      ).animate().fadeIn(duration: 400.ms),

                      const SizedBox(height: 20),

                      // Comparison rows
                      _CompareRow(
                        label: 'Score santé',
                        value1: '${_product1!.healthScore ?? '?'}/100',
                        value2: '${_product2!.healthScore ?? '?'}/100',
                        color1: AppTheme.healthScoreColor(_product1!.healthScore),
                        color2: AppTheme.healthScoreColor(_product2!.healthScore),
                        winner: _compareInt(_product1!.healthScore, _product2!.healthScore, higher: true),
                      ).animate().fadeIn(delay: 100.ms),
                      _CompareRow(
                        label: 'Nutri-Score',
                        value1: _product1!.nutriScore ?? '?',
                        value2: _product2!.nutriScore ?? '?',
                        color1: AppTheme.nutriScoreColor(_product1!.nutriScore),
                        color2: AppTheme.nutriScoreColor(_product2!.nutriScore),
                        winner: _compareNutriScore(_product1!.nutriScore, _product2!.nutriScore),
                      ).animate().fadeIn(delay: 150.ms),
                      _CompareRow(
                        label: 'Eco-Score',
                        value1: _product1!.computedEcoScore,
                        value2: _product2!.computedEcoScore,
                        color1: EcoScoreBadge.ecoScoreColor(_product1!.computedEcoScore),
                        color2: EcoScoreBadge.ecoScoreColor(_product2!.computedEcoScore),
                        winner: _compareNutriScore(_product1!.computedEcoScore, _product2!.computedEcoScore),
                      ).animate().fadeIn(delay: 200.ms),
                      _CompareRow(
                        label: 'NOVA',
                        value1: '${_product1!.novaGroup ?? '?'}',
                        value2: '${_product2!.novaGroup ?? '?'}',
                        winner: _compareInt(_product1!.novaGroup, _product2!.novaGroup, higher: false),
                      ).animate().fadeIn(delay: 250.ms),
                      _CompareRow(
                        label: 'Calories',
                        value1: '${_product1!.calories?.toStringAsFixed(0) ?? '-'} kcal',
                        value2: '${_product2!.calories?.toStringAsFixed(0) ?? '-'} kcal',
                        winner: _compareDouble(_product1!.calories, _product2!.calories, higher: false),
                      ).animate().fadeIn(delay: 300.ms),
                      _CompareRow(
                        label: 'Sucres',
                        value1: '${_product1!.sugars?.toStringAsFixed(1) ?? '-'} g',
                        value2: '${_product2!.sugars?.toStringAsFixed(1) ?? '-'} g',
                        winner: _compareDouble(_product1!.sugars, _product2!.sugars, higher: false),
                      ).animate().fadeIn(delay: 350.ms),
                      _CompareRow(
                        label: 'Graisses sat.',
                        value1: '${_product1!.saturatedFat?.toStringAsFixed(1) ?? '-'} g',
                        value2: '${_product2!.saturatedFat?.toStringAsFixed(1) ?? '-'} g',
                        winner: _compareDouble(_product1!.saturatedFat, _product2!.saturatedFat, higher: false),
                      ).animate().fadeIn(delay: 400.ms),
                      _CompareRow(
                        label: 'Sel',
                        value1: '${_product1!.salt?.toStringAsFixed(2) ?? '-'} g',
                        value2: '${_product2!.salt?.toStringAsFixed(2) ?? '-'} g',
                        winner: _compareDouble(_product1!.salt, _product2!.salt, higher: false),
                      ).animate().fadeIn(delay: 450.ms),
                      _CompareRow(
                        label: 'Fibres',
                        value1: '${_product1!.fiber?.toStringAsFixed(1) ?? '-'} g',
                        value2: '${_product2!.fiber?.toStringAsFixed(1) ?? '-'} g',
                        winner: _compareDouble(_product1!.fiber, _product2!.fiber, higher: true),
                      ).animate().fadeIn(delay: 500.ms),
                      _CompareRow(
                        label: 'Protéines',
                        value1: '${_product1!.proteins?.toStringAsFixed(1) ?? '-'} g',
                        value2: '${_product2!.proteins?.toStringAsFixed(1) ?? '-'} g',
                        winner: _compareDouble(_product1!.proteins, _product2!.proteins, higher: true),
                      ).animate().fadeIn(delay: 550.ms),
                      _CompareRow(
                        label: 'Additifs',
                        value1: '${_product1!.parsedAdditives.length}',
                        value2: '${_product2!.parsedAdditives.length}',
                        winner: _compareInt(
                          _product1!.parsedAdditives.length,
                          _product2!.parsedAdditives.length,
                          higher: false,
                        ),
                      ).animate().fadeIn(delay: 600.ms),

                      const SizedBox(height: 24),

                      // Verdict
                      _buildVerdict().animate().fadeIn(delay: 700.ms).scale(begin: const Offset(0.9, 0.9)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildVerdict() {
    if (_product1 == null || _product2 == null) return const SizedBox();

    final score1 = _product1!.healthScore ?? 0;
    final score2 = _product2!.healthScore ?? 0;
    final winner = score1 >= score2 ? _product1! : _product2!;
    final diff = (score1 - score2).abs();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.healthScoreColor(winner.healthScore),
            AppTheme.healthScoreColor(winner.healthScore).withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 36),
          const SizedBox(height: 8),
          Text(
            score1 == score2 ? 'Match nul !' : 'Meilleur choix',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 4),
          Text(
            score1 == score2 ? 'Les deux produits sont équivalents' : winner.name,
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          if (diff > 0) ...[
            const SizedBox(height: 4),
            Text(
              '+$diff points de score santé',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withValues(alpha: 0.9)),
            ),
          ],
        ],
      ),
    );
  }

  // 0=tie, 1=product1 wins, 2=product2 wins
  int _compareInt(int? v1, int? v2, {required bool higher}) {
    if (v1 == null || v2 == null) return 0;
    if (v1 == v2) return 0;
    return higher ? (v1 > v2 ? 1 : 2) : (v1 < v2 ? 1 : 2);
  }

  int _compareDouble(double? v1, double? v2, {required bool higher}) {
    if (v1 == null || v2 == null) return 0;
    if ((v1 - v2).abs() < 0.01) return 0;
    return higher ? (v1 > v2 ? 1 : 2) : (v1 < v2 ? 1 : 2);
  }

  int _compareNutriScore(String? s1, String? s2) {
    if (s1 == null || s2 == null) return 0;
    final order = ['A', 'B', 'C', 'D', 'E'];
    final i1 = order.indexOf(s1.toUpperCase());
    final i2 = order.indexOf(s2.toUpperCase());
    if (i1 == i2) return 0;
    return i1 < i2 ? 1 : 2;
  }
}

// ==================== COMPARE PRODUCT HEADER ====================
class _CompareProductHeader extends StatelessWidget {
  final Product product;

  const _CompareProductHeader({required this.product});

  @override
  Widget build(BuildContext context) {
    final scoreColor = AppTheme.healthScoreColor(product.healthScore);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [scoreColor, scoreColor.withValues(alpha: 0.7)]),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text('${product.healthScore ?? '?'}', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
          const SizedBox(height: 10),
          Text(product.name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(product.brand ?? '', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary), maxLines: 1),
          const SizedBox(height: 8),
          NutriScoreBadge(score: product.nutriScore, size: 20),
        ],
      ),
    );
  }
}

// ==================== COMPARE ROW ====================
class _CompareRow extends StatelessWidget {
  final String label;
  final String value1;
  final String value2;
  final Color? color1;
  final Color? color2;
  final int winner; // 0=tie, 1=left, 2=right

  const _CompareRow({
    required this.label,
    required this.value1,
    required this.value2,
    this.color1,
    this.color2,
    this.winner = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Value 1
          Expanded(
            child: Row(
              children: [
                if (winner == 1)
                  Container(
                    width: 6, height: 6,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: const BoxDecoration(color: AppTheme.nutriA, shape: BoxShape.circle),
                  ),
                Expanded(
                  child: Text(
                    value1,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: winner == 1 ? FontWeight.w700 : FontWeight.w500,
                      color: color1 ?? (winner == 1 ? AppTheme.nutriA : AppTheme.textPrimary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(8)),
            child: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          ),
          // Value 2
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    value2,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: winner == 2 ? FontWeight.w700 : FontWeight.w500,
                      color: color2 ?? (winner == 2 ? AppTheme.nutriA : AppTheme.textPrimary),
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                if (winner == 2)
                  Container(
                    width: 6, height: 6,
                    margin: const EdgeInsets.only(left: 6),
                    decoration: const BoxDecoration(color: AppTheme.nutriA, shape: BoxShape.circle),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
