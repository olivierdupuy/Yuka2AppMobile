import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../services/remote_config_service.dart';
import '../services/tracking_service.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  final bool isRegister;
  const LoginScreen({super.key, this.isRegister = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late bool _isRegister;
  bool _isForgotPassword = false;
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  double _passwordStrength = 0;
  String _passwordStrengthText = '';
  Color _passwordStrengthColor = Colors.grey;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _isRegister = widget.isRegister;
    try { TrackingService.instance.trackPageView('login'); } catch (_) {}
    _passwordController.addListener(_updatePasswordStrength);
    _checkBiometricLogin();
  }

  Future<void> _checkBiometricLogin() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('biometric_enabled') ?? false;
      final hasBioToken = prefs.getString('biometric_refresh_token') != null;
      final hasToken = prefs.getString('access_token') != null;
      setState(() {
        _biometricAvailable = canCheck && isSupported;
        _biometricEnabled = enabled && (hasBioToken || hasToken);
      });
      if (_biometricEnabled && !_isRegister && RemoteConfigService.instance.config.biometricAuthEnabled) {
        _authenticateWithBiometric();
      }
    } catch (_) {}
  }

  Future<void> _authenticateWithBiometric() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Connectez-vous avec votre empreinte digitale',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      if (authenticated && mounted) {
        final auth = context.read<AuthProvider>();
        var refreshed = await auth.api.tryRefreshToken();
        if (!refreshed) {
          refreshed = await auth.api.tryBiometricRefresh();
        }
        if (refreshed) {
          await auth.checkAuth();
          if (mounted) Navigator.pop(context);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Session expirée, veuillez vous reconnecter avec vos identifiants.', style: GoogleFonts.inter()),
            backgroundColor: AppTheme.nutriD,
          ));
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _updatePasswordStrength() {
    final pwd = _passwordController.text;
    double strength = 0;
    if (pwd.length >= 8) strength += 0.2;
    if (pwd.length >= 12) strength += 0.1;
    if (RegExp(r'[A-Z]').hasMatch(pwd)) strength += 0.2;
    if (RegExp(r'[a-z]').hasMatch(pwd)) strength += 0.1;
    if (RegExp(r'[0-9]').hasMatch(pwd)) strength += 0.2;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(pwd)) strength += 0.2;

    String text;
    Color color;
    if (strength <= 0.2) {
      text = 'Très faible';
      color = AppTheme.nutriE;
    } else if (strength <= 0.4) {
      text = 'Faible';
      color = AppTheme.nutriD;
    } else if (strength <= 0.6) {
      text = 'Moyen';
      color = AppTheme.nutriC;
    } else if (strength <= 0.8) {
      text = 'Fort';
      color = AppTheme.nutriB;
    } else {
      text = 'Très fort';
      color = AppTheme.nutriA;
    }

    setState(() {
      _passwordStrength = strength;
      _passwordStrengthText = pwd.isEmpty ? '' : text;
      _passwordStrengthColor = color;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();
    final auth = context.read<AuthProvider>();

    if (_isForgotPassword) {
      final (success, _) = await auth.forgotPassword(_emailController.text.trim());
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Si un compte existe avec cet email, un lien de réinitialisation a été envoyé.', style: GoogleFonts.inter()),
            backgroundColor: AppTheme.nutriA,
          ),
        );
        setState(() => _isForgotPassword = false);
      }
      return;
    }

    bool success;
    String? error;

    if (_isRegister) {
      (success, error) = await auth.register(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim().isEmpty ? null : _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim().isEmpty ? null : _lastNameController.text.trim(),
      );
    } else {
      (success, error) = await auth.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }

    if (!mounted) return;

    if (success) {
      try { TrackingService.instance.trackEvent(_isRegister ? 'register' : 'login'); } catch (_) {}
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Une erreur est survenue', style: GoogleFonts.inter()),
          backgroundColor: AppTheme.nutriE,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: const Alignment(0, -0.3),
            colors: [
              AppTheme.primary.withValues(alpha: 0.06),
              AppTheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  // Back button
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      if (_isForgotPassword) {
                        setState(() => _isForgotPassword = false);
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary, size: 20),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Logo
                  Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, AppTheme.primaryLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: AppTheme.elevatedShadow(AppTheme.primary),
                      ),
                      child: Icon(
                        _isForgotPassword ? Icons.lock_reset_rounded : Icons.eco_rounded,
                        size: 42,
                        color: Colors.white,
                      ),
                    ),
                  ).animate().scale(begin: const Offset(0.5, 0.5), duration: 500.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 28),

                  // Title
                  Center(
                    child: Text(
                      _isForgotPassword
                          ? 'Mot de passe oublié'
                          : _isRegister
                              ? 'Créer un compte'
                              : 'Connexion',
                      style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      _isForgotPassword
                          ? 'Entrez votre email pour réinitialiser'
                          : _isRegister
                              ? 'Rejoignez la communauté Yuka2'
                              : 'Accédez à votre espace personnel',
                      style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary),
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 36),

                  // Forgot password
                  if (_isForgotPassword) ...[
                    _buildLabel('Email'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'votre@email.com',
                        prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primary),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Champ requis';
                        if (!v.contains('@')) return 'Email invalide';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Register fields
                  if (_isRegister && !_isForgotPassword) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Prénom'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _firstNameController,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  hintText: 'Jean',
                                  prefixIcon: Icon(Icons.person_outline_rounded, color: AppTheme.primary),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Nom'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _lastNameController,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  hintText: 'Dupont',
                                  prefixIcon: Icon(Icons.person_outline_rounded, color: AppTheme.primary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 320.ms).slideX(begin: 0.05),
                    const SizedBox(height: 16),

                    _buildLabel('Nom d\'utilisateur'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        hintText: 'Votre pseudo unique',
                        prefixIcon: Icon(Icons.alternate_email_rounded, color: AppTheme.primary),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Champ requis';
                        if (v.length < 3) return '3 caractères minimum';
                        return null;
                      },
                    ).animate().fadeIn(delay: 350.ms).slideX(begin: 0.05),
                    const SizedBox(height: 16),
                  ],

                  // Email + Password
                  if (!_isForgotPassword) ...[
                    _buildLabel('Email'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'votre@email.com',
                        prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primary),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Champ requis';
                        if (!v.contains('@')) return 'Email invalide';
                        return null;
                      },
                    ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.05),
                    const SizedBox(height: 16),

                    _buildLabel('Mot de passe'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Votre mot de passe',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.primary),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            color: AppTheme.textSecondary,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Champ requis';
                        if (v.length < 8) return '8 caractères minimum';
                        return null;
                      },
                    ).animate().fadeIn(delay: 450.ms).slideX(begin: 0.05),

                    // Password strength
                    if (_isRegister && _passwordStrengthText.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: _passwordStrength,
                          backgroundColor: Colors.grey.shade200,
                          color: _passwordStrengthColor,
                          minHeight: 5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _passwordStrengthText,
                            style: GoogleFonts.inter(fontSize: 12, color: _passwordStrengthColor, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Min. 8 car., majuscule, chiffre, symbole',
                            style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Confirm password
                    if (_isRegister) ...[
                      _buildLabel('Confirmer le mot de passe'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          hintText: 'Retapez votre mot de passe',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.primary),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              color: AppTheme.textSecondary,
                            ),
                            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Champ requis';
                          if (v != _passwordController.text) return 'Les mots de passe ne correspondent pas';
                          return null;
                        },
                      ).animate().fadeIn(delay: 480.ms).slideX(begin: 0.05),
                      const SizedBox(height: 16),
                    ],

                    // Forgot password link
                    if (!_isRegister && RemoteConfigService.instance.config.passwordResetEnabled)
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () => setState(() => _isForgotPassword = true),
                          child: Text(
                            'Mot de passe oublié ?',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 480.ms),
                  ],

                  const SizedBox(height: 32),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _submit,
                      child: auth.isLoading
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text(
                              _isForgotPassword
                                  ? 'Envoyer le lien'
                                  : _isRegister
                                      ? 'Créer mon compte'
                                      : 'Se connecter',
                            ),
                    ),
                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),

                  // Biometric
                  if (!_isRegister && !_isForgotPassword && _biometricAvailable && _biometricEnabled && RemoteConfigService.instance.config.biometricAuthEnabled) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('ou', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary)),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ).animate().fadeIn(delay: 520.ms),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: _authenticateWithBiometric,
                        icon: const Icon(Icons.fingerprint_rounded, size: 26, color: AppTheme.primary),
                        label: Text('Se connecter avec l\'empreinte', style: GoogleFonts.inter(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                      ),
                    ).animate().fadeIn(delay: 540.ms).slideY(begin: 0.1),
                  ],
                  const SizedBox(height: 24),

                  // Toggle
                  if (!_isForgotPassword && (RemoteConfigService.instance.config.registrationEnabled || _isRegister))
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          if (!_isRegister && !RemoteConfigService.instance.config.registrationEnabled) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('L\'inscription est temporairement désactivée')),
                            );
                            return;
                          }
                          setState(() {
                            _isRegister = !_isRegister;
                            _formKey.currentState?.reset();
                          });
                        },
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary),
                            children: [
                              TextSpan(text: _isRegister ? 'Déjà un compte ? ' : 'Pas de compte ? '),
                              TextSpan(
                                text: _isRegister ? 'Se connecter' : 'S\'inscrire',
                                style: GoogleFonts.inter(color: AppTheme.primary, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 600.ms),

                  const SizedBox(height: 32),

                  if (_isRegister && !_isForgotPassword)
                    Center(
                      child: Text(
                        'En créant un compte, vous acceptez nos\nConditions d\'utilisation et Politique de confidentialité',
                        style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary, height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                    ).animate().fadeIn(delay: 650.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
    );
  }
}
