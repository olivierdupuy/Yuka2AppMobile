import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../services/tracking_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    try { TrackingService.instance.trackPageView('profile'); } catch (_) {}
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated) {
        auth.loadProfile();
        auth.loadStats();
      }
      _checkBiometric();
    });
  }

  Future<void> _checkBiometric() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _biometricAvailable = canCheck && isSupported;
        _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      });
    } catch (_) {
      setState(() => _biometricAvailable = false);
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      // Vérifier l'empreinte avant d'activer
      try {
        final authenticated = await _localAuth.authenticate(
          localizedReason: 'Confirmez votre identité pour activer l\'authentification biométrique',
          biometricOnly: true,
          persistAcrossBackgrounding: true,
        );
        if (!authenticated) return;
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Impossible d\'activer la biométrie', style: GoogleFonts.inter()),
          backgroundColor: AppTheme.nutriE,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        return;
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', value);
    if (!value) {
      // Supprimer le token biométrique quand on désactive
      await prefs.remove('biometric_refresh_token');
    }
    setState(() => _biometricEnabled = value);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        value ? 'Authentification biométrique activée' : 'Authentification biométrique désactivée',
        style: GoogleFonts.inter(),
      ),
      backgroundColor: value ? AppTheme.nutriA : AppTheme.textSecondary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isAuthenticated) {
      return _buildUnauthenticated(context);
    }

    final profile = auth.profile;
    final stats = auth.stats;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 14),

            // Avatar + Name
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  profile?.initials ?? 'U',
                  style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ).animate().scale(begin: const Offset(0.8, 0.8), duration: 400.ms, curve: Curves.elasticOut),
            const SizedBox(height: 12),
            Text(
              profile?.displayName ?? 'Utilisateur',
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ).animate().fadeIn(delay: 200.ms),
            if (profile?.email != null)
              Text(
                profile!.email,
                style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
              ).animate().fadeIn(delay: 250.ms),
            if (profile != null && profile.isEmailVerified)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded, size: 16, color: AppTheme.nutriA),
                    const SizedBox(width: 4),
                    Text('Email vérifié', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.nutriA)),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // Stats cards
            if (stats != null) ...[
              Row(
                children: [
                  _StatCard(icon: Icons.qr_code_scanner_rounded, value: '${stats.totalScans}', label: 'Scans', color: AppTheme.primary),
                  const SizedBox(width: 10),
                  _StatCard(icon: Icons.favorite_rounded, value: '${stats.totalFavorites}', label: 'Favoris', color: AppTheme.nutriE),
                  const SizedBox(width: 10),
                  _StatCard(icon: Icons.trending_up_rounded, value: stats.averageHealthScore > 0 ? '${stats.averageHealthScore.round()}' : '-', label: 'Score moy.', color: AppTheme.accent),
                ],
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05),
              const SizedBox(height: 10),
              Row(
                children: [
                  _StatCard(icon: Icons.calendar_today_rounded, value: '${stats.scansThisWeek}', label: 'Cette semaine', color: AppTheme.nutriB),
                  const SizedBox(width: 10),
                  _StatCard(icon: Icons.calendar_month_rounded, value: '${stats.scansThisMonth}', label: 'Ce mois', color: AppTheme.nutriC),
                  const SizedBox(width: 10),
                  _StatCard(icon: Icons.inventory_2_rounded, value: '${stats.totalProducts}', label: 'Produits', color: AppTheme.primaryLight),
                ],
              ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.05),
              const SizedBox(height: 8),
              if (stats.nutriScoreDistribution.isNotEmpty)
                _NutriScoreDistribution(distribution: stats.nutriScoreDistribution).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 16),
            ],

            // Menu sections
            _SectionTitle(title: 'Mon profil'),
            _MenuItem(
              icon: Icons.edit_rounded, label: 'Modifier mon profil',
              subtitle: 'Nom, prénom, téléphone', color: AppTheme.primary,
              onTap: () => _showEditProfileSheet(context),
            ).animate().fadeIn(delay: 420.ms).slideX(begin: 0.03),
            _MenuItem(
              icon: Icons.restaurant_rounded, label: 'Préférences alimentaires',
              subtitle: profile?.dietType ?? 'Non défini', color: AppTheme.nutriA,
              onTap: () => _showPreferencesSheet(context),
            ).animate().fadeIn(delay: 440.ms).slideX(begin: 0.03),

            const SizedBox(height: 8),
            _SectionTitle(title: 'Sécurité'),
            _MenuItem(
              icon: Icons.lock_rounded, label: 'Changer le mot de passe',
              subtitle: 'Modifier votre mot de passe actuel', color: AppTheme.accent,
              onTap: () => _showChangePasswordSheet(context),
            ).animate().fadeIn(delay: 460.ms).slideX(begin: 0.03),

            // Biometric toggle
            if (_biometricAvailable)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  leading: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.fingerprint_rounded, color: AppTheme.primary, size: 20),
                  ),
                  title: Text('Empreinte digitale', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textPrimary)),
                  subtitle: Text(
                    _biometricEnabled ? 'Activée' : 'Désactivée',
                    style: GoogleFonts.inter(fontSize: 12, color: _biometricEnabled ? AppTheme.nutriA : AppTheme.textSecondary),
                  ),
                  trailing: Switch(
                    value: _biometricEnabled,
                    onChanged: _toggleBiometric,
                    activeTrackColor: AppTheme.primary.withValues(alpha: 0.4),
                    activeThumbColor: AppTheme.primary,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ).animate().fadeIn(delay: 470.ms).slideX(begin: 0.03),

            _MenuItem(
              icon: Icons.devices_rounded, label: 'Déconnecter tous les appareils',
              subtitle: 'Fermer toutes les sessions actives', color: AppTheme.nutriD,
              onTap: () => _showLogoutAllDialog(context),
            ).animate().fadeIn(delay: 480.ms).slideX(begin: 0.03),

            const SizedBox(height: 8),
            _SectionTitle(title: 'Informations'),
            _MenuItem(
              icon: Icons.info_outline_rounded, label: 'À propos de Yuka2',
              subtitle: 'Version 1.0.0', color: AppTheme.primaryLight, onTap: () {},
            ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.03),
            if (profile != null)
              _MenuItem(
                icon: Icons.cake_rounded, label: 'Membre depuis',
                subtitle: _formatDate(profile.createdAt), color: AppTheme.nutriB, onTap: null,
              ).animate().fadeIn(delay: 520.ms).slideX(begin: 0.03),

            const SizedBox(height: 16),

            // Logout
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async => await auth.logout(),
                icon: const Icon(Icons.logout_rounded, color: AppTheme.nutriE),
                label: Text('Se déconnecter', style: GoogleFonts.inter(color: AppTheme.nutriE, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.nutriE),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ).animate().fadeIn(delay: 560.ms),
            const SizedBox(height: 10),

            // Delete account
            TextButton(
              onPressed: () => _showDeleteAccountDialog(context),
              child: Text('Supprimer mon compte', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey, decoration: TextDecoration.underline)),
            ).animate().fadeIn(delay: 600.ms),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildUnauthenticated(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 110, height: 110,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  shape: BoxShape.circle,
                  boxShadow: AppTheme.elevatedShadow(AppTheme.primary),
                ),
                child: const Icon(Icons.person_rounded, size: 52, color: Colors.white),
              ).animate().scale(begin: const Offset(0.8, 0.8), duration: 400.ms, curve: Curves.elasticOut),
              const SizedBox(height: 28),
              Text('Bienvenue sur Yuka2', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 10),
              Text('Connectez-vous pour sauvegarder vos scans,\ngérer vos favoris et suivre votre alimentation',
                style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary, height: 1.5), textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                  },
                  child: const Text('Se connecter'),
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen(isRegister: true)));
                },
                child: Text('Créer un compte', style: GoogleFonts.inter(color: AppTheme.primary, fontWeight: FontWeight.w700)),
              ).animate().fadeIn(delay: 500.ms),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['jan.', 'fév.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // ==================== BOTTOM SHEETS ====================

  void _showEditProfileSheet(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final profile = auth.profile;
    final usernameC = TextEditingController(text: profile?.username);
    final firstNameC = TextEditingController(text: profile?.firstName);
    final lastNameC = TextEditingController(text: profile?.lastName);
    final phoneC = TextEditingController(text: profile?.phone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BottomSheetWrapper(
        title: 'Modifier mon profil',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sheetField('Nom d\'utilisateur', usernameC, Icons.alternate_email_rounded),
            _sheetField('Prénom', firstNameC, Icons.person_outline_rounded),
            _sheetField('Nom', lastNameC, Icons.person_outline_rounded),
            _sheetField('Téléphone', phoneC, Icons.phone_outlined, keyboard: TextInputType.phone),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  final (success, error) = await auth.updateProfile(
                    username: usernameC.text.trim(), firstName: firstNameC.text.trim(),
                    lastName: lastNameC.text.trim(), phone: phoneC.text.trim(),
                  );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(success ? 'Profil mis à jour' : (error ?? 'Erreur'), style: GoogleFonts.inter()),
                      backgroundColor: success ? AppTheme.nutriA : AppTheme.nutriE,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ));
                  }
                },
                child: const Text('Enregistrer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPreferencesSheet(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final profile = auth.profile;
    String? selectedDiet = profile?.dietType;
    final allergiesC = TextEditingController(text: profile?.allergies);
    final goalsC = TextEditingController(text: profile?.dietaryGoals);
    final diets = ['Omnivore', 'Végétarien', 'Végétalien', 'Vegan', 'Sans gluten', 'Sans lactose', 'Halal', 'Casher', 'Autre'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => _BottomSheetWrapper(
          title: 'Préférences alimentaires',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Type de régime', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: diets.map((diet) => ChoiceChip(
                  label: Text(diet, style: GoogleFonts.inter(fontSize: 13)),
                  selected: selectedDiet == diet,
                  onSelected: (v) => setSheetState(() => selectedDiet = v ? diet : null),
                  selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                  labelStyle: GoogleFonts.inter(
                    color: selectedDiet == diet ? AppTheme.primary : AppTheme.textPrimary,
                    fontWeight: selectedDiet == diet ? FontWeight.w600 : FontWeight.w400,
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),
              _sheetField('Allergies', allergiesC, Icons.warning_amber_rounded),
              _sheetField('Objectifs alimentaires', goalsC, Icons.flag_rounded),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final (success, error) = await auth.updatePreferences(
                      dietType: selectedDiet ?? '', allergies: allergiesC.text.trim(), dietaryGoals: goalsC.text.trim(),
                    );
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(success ? 'Préférences mises à jour' : (error ?? 'Erreur'), style: GoogleFonts.inter()),
                        backgroundColor: success ? AppTheme.nutriA : AppTheme.nutriE,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ));
                    }
                  },
                  child: const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordSheet(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final currentC = TextEditingController();
    final newC = TextEditingController();
    final confirmC = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BottomSheetWrapper(
        title: 'Changer le mot de passe',
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentC, obscureText: true,
                decoration: const InputDecoration(labelText: 'Mot de passe actuel', prefixIcon: Icon(Icons.lock_outline_rounded, color: AppTheme.primary)),
                validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: newC, obscureText: true,
                decoration: const InputDecoration(labelText: 'Nouveau mot de passe', prefixIcon: Icon(Icons.lock_rounded, color: AppTheme.primary)),
                validator: (v) { if (v == null || v.isEmpty) return 'Requis'; if (v.length < 8) return '8 caractères minimum'; return null; },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmC, obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirmer le nouveau mot de passe', prefixIcon: Icon(Icons.lock_rounded, color: AppTheme.primary)),
                validator: (v) { if (v != newC.text) return 'Les mots de passe ne correspondent pas'; return null; },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final (success, error) = await auth.changePassword(currentC.text, newC.text);
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(success ? 'Mot de passe modifié. Veuillez vous reconnecter.' : (error ?? 'Erreur'), style: GoogleFonts.inter()),
                        backgroundColor: success ? AppTheme.nutriA : AppTheme.nutriE,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ));
                    }
                  },
                  child: const Text('Modifier'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutAllDialog(BuildContext context) {
    final auth = context.read<AuthProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Déconnecter tous les appareils ?', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18)),
        content: Text('Toutes vos sessions actives seront fermées. Vous devrez vous reconnecter sur chaque appareil.',
          style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Annuler', style: GoogleFonts.inter(color: AppTheme.textSecondary))),
          ElevatedButton(
            onPressed: () async { Navigator.pop(ctx); await auth.logoutAll(); },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.nutriD),
            child: const Text('Déconnecter tout'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final passwordC = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_rounded, color: AppTheme.nutriE, size: 24),
            const SizedBox(width: 8),
            Text('Supprimer le compte', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cette action est irréversible. Toutes vos données seront supprimées définitivement.',
              style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            TextField(controller: passwordC, obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirmez votre mot de passe', prefixIcon: Icon(Icons.lock_rounded, color: AppTheme.nutriE))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Annuler', style: GoogleFonts.inter(color: AppTheme.textSecondary))),
          ElevatedButton(
            onPressed: () async {
              if (passwordC.text.isEmpty) return;
              final (success, error) = await auth.deleteAccount(passwordC.text);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(error ?? 'Erreur', style: GoogleFonts.inter()),
                    backgroundColor: AppTheme.nutriE, behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.nutriE),
            child: const Text('Supprimer définitivement'),
          ),
        ],
      ),
    );
  }

  Widget _sheetField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller, keyboardType: keyboard,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: AppTheme.primary)),
      ),
    );
  }
}

// ==================== WIDGETS ====================

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 0.5)),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatCard({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.06)),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.12), color.withValues(alpha: 0.04)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _NutriScoreDistribution extends StatelessWidget {
  final Map<String, int> distribution;
  const _NutriScoreDistribution({required this.distribution});

  @override
  Widget build(BuildContext context) {
    final total = distribution.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();
    final colors = {'A': AppTheme.nutriA, 'B': AppTheme.nutriB, 'C': AppTheme.nutriC, 'D': AppTheme.nutriD, 'E': AppTheme.nutriE};

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.06)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Répartition NutriScore', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 12),
          ...['A', 'B', 'C', 'D', 'E'].map((score) {
            final count = distribution[score] ?? 0;
            final pct = count / total;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(color: colors[score], borderRadius: BorderRadius.circular(6)),
                    child: Center(child: Text(score, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(value: pct, backgroundColor: Colors.grey.shade100, color: colors[score], minHeight: 8),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(width: 30, child: Text('$count', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13), textAlign: TextAlign.right)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  const _MenuItem({required this.icon, required this.label, required this.subtitle, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.06)),
        boxShadow: AppTheme.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap != null ? () {
            HapticFeedback.selectionClick();
            onTap!();
          } : null,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withValues(alpha: 0.12), color.withValues(alpha: 0.04)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textPrimary)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
                if (onTap != null)
                  const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomSheetWrapper extends StatelessWidget {
  final String title;
  final Widget child;
  const _BottomSheetWrapper({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final navBarHeight = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + navBarHeight + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 44, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(3))),
            const SizedBox(height: 20),
            Text(title, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}
