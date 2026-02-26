import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/auth_provider.dart';
import '../providers/compare_provider.dart';
import '../providers/product_provider.dart';
import '../services/remote_config_service.dart';
import '../services/tracking_service.dart';
import '../theme/app_theme.dart';
import '../widgets/compare_fab.dart';
import '../widgets/product_card.dart';
import 'compare_screen.dart';
import 'product_detail_screen.dart';
import 'scan_screen.dart';
import 'search_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
    try { TrackingService.instance.trackPageView('home'); } catch (_) {}
  }

  void _goToSearch() {
    final config = RemoteConfigService.instance.config;
    if (!config.searchEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La recherche est temporairement désactivée')),
      );
      return;
    }
    setState(() => _currentIndex = 1);
  }

  void _goToScan() {
    final config = RemoteConfigService.instance.config;
    if (!config.scanEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le scanner est temporairement désactivé')),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const _HomeContent(),
      const SearchScreen(),
      const SizedBox(),
      const HistoryScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      floatingActionButton: _currentIndex == 0 ? const CompareFab() : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.home_rounded, label: 'Accueil', isActive: _currentIndex == 0, onTap: () => setState(() => _currentIndex = 0)),
                _NavItem(icon: Icons.search_rounded, label: 'Recherche', isActive: _currentIndex == 1, onTap: _goToSearch),
                GestureDetector(
                  onTap: _goToScan,
                  child: Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: AppTheme.primary.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 28),
                  ),
                ),
                _NavItem(icon: Icons.history_rounded, label: 'Historique', isActive: _currentIndex == 3, onTap: () {
                  final config = RemoteConfigService.instance.config;
                  if (!config.historyEnabled) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('L\'historique est temporairement désactivé')),
                    );
                    return;
                  }
                  setState(() => _currentIndex = 3);
                }),
                _NavItem(icon: Icons.person_rounded, label: 'Profil', isActive: _currentIndex == 4, onTap: () => setState(() => _currentIndex = 4)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 64,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(icon, color: isActive ? AppTheme.primary : AppTheme.textSecondary, size: isActive ? 26 : 24),
            ),
            const SizedBox(height: 3),
            Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: isActive ? FontWeight.w700 : FontWeight.w400, color: isActive ? AppTheme.primary : AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour';
    if (hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final productProvider = context.watch<ProductProvider>();
    final products = productProvider.products;

    final bestProducts = [...products]..sort((a, b) => (b.healthScore ?? 0).compareTo(a.healthScore ?? 0));
    final worstProducts = [...products]..sort((a, b) => (a.healthScore ?? 0).compareTo(b.healthScore ?? 0));

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ==================== HEADER ====================
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_getGreeting()}${auth.username != null ? ', ${auth.username}' : ''} !',
                              style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, height: 1.2),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2),
                            const SizedBox(height: 6),
                            Text(
                              'Mangez mieux, vivez mieux',
                              style: GoogleFonts.inter(fontSize: 15, color: AppTheme.textSecondary, fontWeight: FontWeight.w400),
                            ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.primary.withValues(alpha: 0.12), AppTheme.primaryLight.withValues(alpha: 0.08)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
                        ),
                        child: const Icon(Icons.eco_rounded, color: AppTheme.primary, size: 28),
                      ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8)),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // ==================== SEARCH BAR ====================
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                      homeState?._goToSearch();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.search_rounded, color: AppTheme.primary, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Text('Rechercher un produit...', style: GoogleFonts.inter(fontSize: 15, color: AppTheme.textSecondary.withValues(alpha: 0.6))),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.05),
                  const SizedBox(height: 22),

                  // ==================== SCAN CTA ====================
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen()));
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: AppTheme.elevatedShadow(AppTheme.primary),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Scanner un produit', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                                const SizedBox(height: 8),
                                Text('Scannez le code-barres pour\ndécouvrir sa qualité nutritionnelle',
                                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.85), height: 1.5)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                            ),
                            child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 32),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.08),
                  const SizedBox(height: 16),

                  // ==================== COMPARATOR SHORTCUT ====================
                  Consumer<CompareProvider>(
                    builder: (context, compare, _) {
                      if (compare.selectedCount == 0) return const SizedBox.shrink();
                      return GestureDetector(
                        onTap: () {
                          if (compare.canCompare) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const CompareScreen()));
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                            boxShadow: AppTheme.cardShadow,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.compare_arrows, color: AppTheme.primary, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Comparateur', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${compare.selectedCount} produit${compare.selectedCount > 1 ? 's' : ''} sélectionné${compare.selectedCount > 1 ? 's' : ''}',
                                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: compare.canCompare ? AppTheme.primary : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  compare.canCompare ? 'Comparer' : '${compare.selectedCount}/2 min',
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05);
                    },
                  ),
                  const SizedBox(height: 10),

                  // ==================== NUTRISCORE QUICK FILTER ====================
                  Text('NutriScore', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary))
                      .animate().fadeIn(delay: 250.ms),
                  const SizedBox(height: 12),
                  Row(
                    children: ['A', 'B', 'C', 'D', 'E'].map((score) {
                      final color = AppTheme.nutriScoreColor(score);
                      final count = products.where((p) => p.nutriScore?.toUpperCase() == score).length;
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
                          ),
                          child: Column(
                            children: [
                              Text(score, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
                              const SizedBox(height: 4),
                              Text('$count', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: color.withValues(alpha: 0.7))),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05),
                ],
              ),
            ),
          ),

          // ==================== TOP PRODUITS ====================
          if (bestProducts.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [AppTheme.nutriA.withValues(alpha: 0.15), AppTheme.nutriA.withValues(alpha: 0.05)]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.star_rounded, color: AppTheme.nutriA, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Text('Les meilleurs choix', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.nutriA.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Score sain', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.nutriA)),
                    ),
                  ],
                ).animate().fadeIn(delay: 350.ms),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: bestProducts.take(5).length,
                  itemBuilder: (context, index) {
                    final product = bestProducts[index];
                    final scoreColor = AppTheme.healthScoreColor(product.healthScore);
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: product.id)));
                      },
                      child: Container(
                        width: 160,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.06)),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [scoreColor.withValues(alpha: 0.15), scoreColor.withValues(alpha: 0.05)]),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(_getCategoryIcon(product.categories), color: scoreColor, size: 22),
                                ),
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [scoreColor, scoreColor.withValues(alpha: 0.7)]),
                                    boxShadow: [BoxShadow(color: scoreColor.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 3))],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text('${product.healthScore ?? '?'}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(product.name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(product.brand ?? '', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.nutriScoreColor(product.nutriScore).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Nutri-Score ${product.nutriScore ?? '?'}',
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.nutriScoreColor(product.nutriScore)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: Duration(milliseconds: 380 + index * 60)).slideX(begin: 0.08);
                  },
                ),
              ),
            ),
          ],

          // ==================== PRODUITS A EVITER ====================
          if (worstProducts.isNotEmpty && worstProducts.first.healthScore != null && worstProducts.first.healthScore! < 50) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppTheme.nutriE.withValues(alpha: 0.15), AppTheme.nutriE.withValues(alpha: 0.05)]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.warning_amber_rounded, color: AppTheme.nutriE, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text('A consommer avec modération', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  ],
                ).animate().fadeIn(delay: 500.ms),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: worstProducts.where((p) => (p.healthScore ?? 100) < 50).take(5).length,
                  itemBuilder: (context, index) {
                    final product = worstProducts.where((p) => (p.healthScore ?? 100) < 50).toList()[index];
                    final scoreColor = AppTheme.healthScoreColor(product.healthScore);
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: product.id)));
                      },
                      child: Container(
                        width: 240,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: scoreColor.withValues(alpha: 0.15)),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50, height: 50,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [scoreColor.withValues(alpha: 0.15), scoreColor.withValues(alpha: 0.05)]),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(_getCategoryIcon(product.categories), color: scoreColor, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(product.name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 3),
                                  Text(product.brand ?? '', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary), maxLines: 1),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(color: scoreColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                                        child: Text('${product.healthScore}/100', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: scoreColor)),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(color: AppTheme.nutriScoreColor(product.nutriScore).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                                        child: Text(product.nutriScore ?? '?', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.nutriScoreColor(product.nutriScore))),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: Duration(milliseconds: 530 + index * 60)).slideX(begin: 0.08);
                  },
                ),
              ),
            ),
          ],

          // ==================== TOUS LES PRODUITS ====================
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [AppTheme.accent.withValues(alpha: 0.15), AppTheme.accent.withValues(alpha: 0.05)]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.grid_view_rounded, color: AppTheme.accent, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Text('Tous les produits', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${products.length} produits', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.accent)),
                  ),
                ],
              ).animate().fadeIn(delay: 600.ms),
            ),
          ),

          if (productProvider.isLoading)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: List.generate(4, (index) => _ShimmerCard(index: index)),
                ),
              ),
            )
          else if (products.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.primary.withValues(alpha: 0.08), AppTheme.primaryLight.withValues(alpha: 0.04)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.qr_code_scanner_rounded, size: 56, color: AppTheme.primary.withValues(alpha: 0.4)),
                    ),
                    const SizedBox(height: 20),
                    Text('Aucun produit trouvé', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                    const SizedBox(height: 8),
                    Text('Scannez votre premier produit !', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14)),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final product = products[index];
                  return ProductCard(product: product, index: index,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: product.id))),
                  );
                },
                childCount: products.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  static IconData _getCategoryIcon(String? categories) {
    final cat = categories?.toLowerCase() ?? '';
    if (cat.contains('boisson') || cat.contains('eau')) return Icons.local_drink_rounded;
    if (cat.contains('fromage') || cat.contains('lait') || cat.contains('yaourt')) return Icons.breakfast_dining_rounded;
    if (cat.contains('chocolat') || cat.contains('biscuit') || cat.contains('sucr')) return Icons.cookie_rounded;
    if (cat.contains('légume') || cat.contains('salade')) return Icons.eco_rounded;
    if (cat.contains('fruit') || cat.contains('compote')) return Icons.apple_rounded;
    if (cat.contains('chip') || cat.contains('salé')) return Icons.fastfood_rounded;
    if (cat.contains('conserve')) return Icons.inventory_2_rounded;
    if (cat.contains('tartiner')) return Icons.brunch_dining_rounded;
    return Icons.restaurant_rounded;
  }
}

class _ShimmerCard extends StatelessWidget {
  final int index;
  const _ShimmerCard({required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade50,
        child: Container(
          height: 90,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}
