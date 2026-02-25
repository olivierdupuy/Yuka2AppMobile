import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
                const SizedBox(height: 16),
                TextField(
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
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                const SizedBox(height: 14),
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
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () => _onNutriFilterTap(score),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isActive ? color : color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: isActive ? null : Border.all(color: color.withValues(alpha: 0.3)),
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
                const SizedBox(height: 10),
                // Toggle Open Food Facts
                GestureDetector(
                  onTap: () {
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
                          : Colors.grey.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _searchOFF
                            ? AppTheme.accent.withValues(alpha: 0.4)
                            : Colors.grey.withValues(alpha: 0.2),
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
                        const SizedBox(width: 8),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 36,
                          height: 20,
                          decoration: BoxDecoration(
                            color: _searchOFF ? AppTheme.accent : Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: AnimatedAlign(
                            duration: const Duration(milliseconds: 200),
                            alignment: _searchOFF ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              width: 16,
                              height: 16,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
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
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : provider.products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off_rounded, size: 56, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text(
                              'Aucun résultat',
                              style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 16),
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
