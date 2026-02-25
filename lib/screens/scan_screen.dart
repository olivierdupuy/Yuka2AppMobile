import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../services/tracking_service.dart';
import '../theme/app_theme.dart';
import 'product_detail_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with SingleTickerProviderStateMixin {
  final _barcodeController = TextEditingController();
  late AnimationController _animController;
  MobileScannerController? _scannerController;
  bool _isSearching = false;
  bool _hasScanned = false;
  bool _showManualInput = false;
  bool _torchOn = false;
  String? _lastScannedCode;

  @override
  void initState() {
    super.initState();
    try { TrackingService.instance.trackPageView('scan'); } catch (_) {}
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _animController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_hasScanned || _isSearching) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first.rawValue;
    if (barcode == null || barcode.isEmpty) return;
    if (barcode == _lastScannedCode) return;

    _lastScannedCode = barcode;
    _hasScanned = true;
    _scanBarcode(barcode);
  }

  Future<void> _scanBarcode(String barcode) async {
    if (barcode.isEmpty) return;
    setState(() => _isSearching = true);

    final product = await context.read<ProductProvider>().scanBarcode(barcode);

    if (!mounted) return;
    setState(() {
      _isSearching = false;
      _hasScanned = false;
    });

    if (product != null) {
      try { TrackingService.instance.trackEvent('scan', data: {'barcode': barcode}); } catch (_) {}
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(productId: product.id),
        ),
      );
    } else {
      _lastScannedCode = null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Produit non trouvé pour le code: $barcode',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppTheme.nutriE,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                  Text(
                    'Scanner',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    children: [
                      // Torch toggle
                      GestureDetector(
                        onTap: () {
                          _scannerController?.toggleTorch();
                          setState(() => _torchOn = !_torchOn);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _torchOn
                                ? AppTheme.accent.withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                            color: _torchOn ? AppTheme.accent : Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Camera scanner view
            Expanded(
              flex: _showManualInput ? 3 : 5,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Camera preview
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: MobileScanner(
                          controller: _scannerController!,
                          onDetect: _onBarcodeDetected,
                        ),
                      ),
                    ),
                  ),

                  // Overlay with scanning frame
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.3),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Transparent scan area
                            Center(
                              child: Container(
                                width: 280,
                                height: 160,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _isSearching ? AppTheme.accent : AppTheme.primaryLight,
                                    width: 2.5,
                                  ),
                                  color: Colors.transparent,
                                ),
                              ),
                            ),

                            // Corner decorations
                            Align(
                              alignment: Alignment.center + const Alignment(-0.75, -0.38),
                              child: const _CornerDecoration(isTopLeft: true),
                            ),
                            Align(
                              alignment: Alignment.center + const Alignment(0.75, -0.38),
                              child: const _CornerDecoration(isTopRight: true),
                            ),
                            Align(
                              alignment: Alignment.center + const Alignment(-0.75, 0.38),
                              child: const _CornerDecoration(isBottomLeft: true),
                            ),
                            Align(
                              alignment: Alignment.center + const Alignment(0.75, 0.38),
                              child: const _CornerDecoration(isBottomRight: true),
                            ),

                            // Scanning line animation
                            AnimatedBuilder(
                              animation: _animController,
                              builder: (context, child) {
                                return Positioned(
                                  top: MediaQuery.of(context).size.height * 0.15 +
                                      (_animController.value * 100),
                                  left: 60,
                                  right: 60,
                                  child: Container(
                                    height: 3,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          (_isSearching ? AppTheme.accent : AppTheme.primaryLight)
                                              .withValues(alpha: 0.8),
                                          _isSearching ? AppTheme.accent : AppTheme.primaryLight,
                                          (_isSearching ? AppTheme.accent : AppTheme.primaryLight)
                                              .withValues(alpha: 0.8),
                                          Colors.transparent,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (_isSearching ? AppTheme.accent : AppTheme.primaryLight)
                                              .withValues(alpha: 0.6),
                                          blurRadius: 16,
                                          spreadRadius: 3,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                            // Loading indicator
                            if (_isSearching)
                              Positioned(
                                bottom: 40,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppTheme.primaryLight,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Recherche en cours...',
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              Positioned(
                                bottom: 40,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Text(
                                    'Placez le code-barres dans le cadre',
                                    style: GoogleFonts.inter(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Toggle manual input button
            GestureDetector(
              onTap: () => setState(() => _showManualInput = !_showManualInput),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _showManualInput ? Icons.camera_alt_rounded : Icons.keyboard_rounded,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _showManualInput ? 'Retour au scanner' : 'Saisir le code manuellement',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Manual input section
            if (_showManualInput)
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saisie manuelle',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ).animate().fadeIn(delay: 100.ms),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _barcodeController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Entrez le code-barres...',
                                prefixIcon: const Icon(Icons.dialpad_rounded, color: AppTheme.primary),
                                suffixIcon: _isSearching
                                    ? const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                                        ),
                                      )
                                    : null,
                              ),
                              onSubmitted: _scanBarcode,
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => _scanBarcode(_barcodeController.text),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.search_rounded, color: Colors.white),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 14),
                      Text(
                        'Codes rapides',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: ListView(
                          children: [
                            ('3017620422003', 'Nutella'),
                            ('5449000000996', 'Coca-Cola'),
                            ('3228857000166', 'Camembert'),
                            ('8000500310427', 'Kinder Bueno'),
                            ('3046920028363', 'Lindt 70%'),
                          ].asMap().entries.map((entry) {
                            final (barcode, name) = entry.value;
                            return ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                              leading: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.qr_code_2_rounded, color: AppTheme.primary, size: 18),
                              ),
                              title: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                              subtitle: Text(barcode, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
                              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.textSecondary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              onTap: () => _scanBarcode(barcode),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _CornerDecoration extends StatelessWidget {
  final bool isTopLeft;
  final bool isTopRight;
  final bool isBottomLeft;
  final bool isBottomRight;

  const _CornerDecoration({
    this.isTopLeft = false,
    this.isTopRight = false,
    this.isBottomLeft = false,
    this.isBottomRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: CustomPaint(
        painter: _CornerPainter(
          isTopLeft: isTopLeft,
          isTopRight: isTopRight,
          isBottomLeft: isBottomLeft,
          isBottomRight: isBottomRight,
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final bool isTopLeft;
  final bool isTopRight;
  final bool isBottomLeft;
  final bool isBottomRight;

  _CornerPainter({
    this.isTopLeft = false,
    this.isTopRight = false,
    this.isBottomLeft = false,
    this.isBottomRight = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryLight
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (isTopLeft) {
      canvas.drawLine(const Offset(0, 20), const Offset(0, 0), paint);
      canvas.drawLine(const Offset(0, 0), const Offset(20, 0), paint);
    }
    if (isTopRight) {
      canvas.drawLine(Offset(size.width - 20, 0), Offset(size.width, 0), paint);
      canvas.drawLine(Offset(size.width, 0), Offset(size.width, 20), paint);
    }
    if (isBottomLeft) {
      canvas.drawLine(Offset(0, size.height - 20), Offset(0, size.height), paint);
      canvas.drawLine(Offset(0, size.height), Offset(20, size.height), paint);
    }
    if (isBottomRight) {
      canvas.drawLine(Offset(size.width, size.height - 20), Offset(size.width, size.height), paint);
      canvas.drawLine(Offset(size.width - 20, size.height), Offset(size.width, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
