import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../services/tracking_service.dart';
import '../theme/app_theme.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';
import 'login_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    try { TrackingService.instance.trackPageView('history'); } catch (_) {}
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated) {
        final provider = context.read<ProductProvider>();
        provider.loadHistory();
        provider.loadFavorites();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<ProductProvider>();

    if (!auth.isAuthenticated) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primary.withValues(alpha: 0.12), AppTheme.primaryLight.withValues(alpha: 0.06)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_outline_rounded, size: 48, color: AppTheme.primary),
                ).animate().scale(begin: const Offset(0.8, 0.8), duration: 400.ms, curve: Curves.elasticOut),
                const SizedBox(height: 24),
                Text(
                  'Connectez-vous',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 8),
                Text(
                  'Pour accéder à votre historique et vos favoris',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                    },
                    child: const Text('Se connecter'),
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
              ],
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Text(
              'Mon activité',
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 18),
          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
              dividerHeight: 0,
              tabs: const [
                Tab(text: 'Historique'),
                Tab(text: 'Favoris'),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // History tab
                provider.isLoading
                    ? _buildShimmerList()
                    : provider.history.isEmpty
                        ? _EmptyState(
                            icon: Icons.history_rounded,
                            message: 'Aucun scan récent',
                            subtitle: 'Scannez des produits pour les retrouver ici',
                          )
                        : RefreshIndicator(
                            onRefresh: () => provider.loadHistory(),
                            color: AppTheme.primary,
                            child: ListView.builder(
                              padding: const EdgeInsets.only(top: 8),
                              itemCount: provider.history.length,
                              itemBuilder: (context, index) {
                                final item = provider.history[index];
                                return ProductCard(
                                  product: item.product,
                                  index: index,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProductDetailScreen(productId: item.product.id),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),

                // Favorites tab
                provider.isLoading
                    ? _buildShimmerList()
                    : provider.favorites.isEmpty
                        ? _EmptyState(
                            icon: Icons.favorite_border_rounded,
                            message: 'Aucun favori',
                            subtitle: 'Ajoutez des produits en favoris pour les retrouver',
                          )
                        : RefreshIndicator(
                            onRefresh: () => provider.loadFavorites(),
                            color: AppTheme.primary,
                            child: ListView.builder(
                              padding: const EdgeInsets.only(top: 8),
                              itemCount: provider.favorites.length,
                              itemBuilder: (context, index) {
                                final product = provider.favorites[index];
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
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return Padding(
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
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subtitle;

  const _EmptyState({required this.icon, required this.message, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.textSecondary.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: AppTheme.textSecondary.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
