import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
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
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_outline_rounded, size: 48, color: AppTheme.primary),
                ),
                const SizedBox(height: 20),
                Text(
                  'Connectez-vous',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pour accéder à votre historique et vos favoris',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                    },
                    child: const Text('Se connecter'),
                  ),
                ),
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(
              'Mon activité',
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 16),
          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(12),
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
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                    : provider.history.isEmpty
                        ? _EmptyState(
                            icon: Icons.history_rounded,
                            message: 'Aucun scan récent',
                          )
                        : RefreshIndicator(
                            onRefresh: () => provider.loadHistory(),
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
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                    : provider.favorites.isEmpty
                        ? _EmptyState(
                            icon: Icons.favorite_border_rounded,
                            message: 'Aucun favori',
                          )
                        : RefreshIndicator(
                            onRefresh: () => provider.loadFavorites(),
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
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            message,
            style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
