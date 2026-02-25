import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/product_provider.dart';
import '../services/tracking_service.dart';
import '../theme/app_theme.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String? _selectedNutriScore;
  bool _searchOFF = false;

  final _nutriFilters = ['A', 'B', 'C', 'D', 'E'];

  @override
  void initState() {
    super.initState();
    try { TrackingService.instance.trackPageView('search'); } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (query.isNotEmpty) {
        try { TrackingService.instance.trackEvent('search', data: {'query': query}); } catch (_) {}
      }
      if (_searchOFF && query.isNotEmpty) {
        context.read<ProductProvider>().searchOpenFoodFacts(query);
      } else {
        context.read<ProductProvider>().loadProducts(
              search: query.isEmpty ? null : query,
              nutriScore: _selectedNutriScore,
            );
      }
    });
  }

  void _onNutriFilterTap(String score) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedNutriScore = _selectedNutriScore == score ? null : score;
    });
    context.read<ProductProvider>().loadProducts(
          search: _searchController.text.isEmpty ? null : _searchController.text,
          nutriScore: _selectedNutriScore,
        );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rechercher',
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ).animate().fadeIn(duration: 300.ms),
                const SizedBox(height: 18),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Nom du produit ou marque...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primary),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                    ),
                  ),
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                const SizedBox(height: 16),
                // Nutri-Score filters
                Row(
                  children: [
                    Text(
                      'Nutri-Score:',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    ...List.generate(5, (index) {
                      final score = _nutriFilters[index];
                      final isActive = _selectedNutriScore == score;
                      final color = AppTheme.nutriScoreColor(score);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => _onNutriFilterTap(score),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isActive ? color : color.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: isActive ? null : Border.all(color: color.withValues(alpha: 0.25)),
                              boxShadow: isActive ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))] : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              score,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isActive ? Colors.white : color,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 12),
                // Toggle Open Food Facts
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _searchOFF = !_searchOFF);
                    if (_searchController.text.isNotEmpty) {
                      _onSearchChanged(_searchController.text);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _searchOFF
                          ? AppTheme.accent.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _searchOFF
                            ? AppTheme.accent.withValues(alpha: 0.3)
                            : Colors.grey.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.public_rounded,
                          size: 18,
                          color: _searchOFF ? AppTheme.accent : AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Open Food Facts',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _searchOFF ? AppTheme.accent : AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 40,
                          height: 22,
                          decoration: BoxDecoration(
                            color: _searchOFF ? AppTheme.accent : Colors.grey[300],
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: AnimatedAlign(
                            duration: const Duration(milliseconds: 200),
                            alignment: _searchOFF ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              width: 18,
                              height: 18,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4)],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 250.ms),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // Results
          Expanded(
            child: provider.isLoading
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: List.generate(5, (i) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Shimmer.fromColors(
                          baseColor: Colors.grey.shade200,
                          highlightColor: Colors.grey.shade50,
                          child: Container(
                            height: 90,
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      )),
                    ),
                  )
                : provider.products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppTheme.textSecondary.withValues(alpha: 0.06),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.search_off_rounded, size: 48, color: AppTheme.textSecondary.withValues(alpha: 0.4)),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun résultat',
                              style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Essayez un autre mot-clé',
                              style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 8),
                        itemCount: provider.products.length,
                        itemBuilder: (context, index) {
                          final product = provider.products[index];
                          return ProductCard(
                            product: product,
                            index: index,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailScreen(productId: product.id),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
