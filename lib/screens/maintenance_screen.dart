import 'package:flutter/material.dart';
import '../services/remote_config_service.dart';

enum BlockingReason { maintenance, forceUpdate }

class MaintenanceScreen extends StatelessWidget {
  final BlockingReason reason;
  final VoidCallback onRetry;

  const MaintenanceScreen({
    super.key,
    required this.reason,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final config = RemoteConfigService.instance.config;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5F5F5), Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: reason == BlockingReason.maintenance
                        ? const Color(0xFFFFF3E0)
                        : const Color(0xFFE3F2FD),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    reason == BlockingReason.maintenance
                        ? Icons.construction_rounded
                        : Icons.system_update_rounded,
                    size: 56,
                    color: reason == BlockingReason.maintenance
                        ? const Color(0xFFE65100)
                        : const Color(0xFF1565C0),
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  reason == BlockingReason.maintenance
                      ? 'Maintenance en cours'
                      : 'Mise à jour requise',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Message
                Text(
                  reason == BlockingReason.maintenance
                      ? (config.maintenanceMessage ?? 'L\'application est en maintenance, veuillez réessayer plus tard.')
                      : (config.forceUpdateMessage ?? 'Une nouvelle version est disponible. Veuillez mettre à jour l\'application pour continuer.'),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Version info for force update
                if (reason == BlockingReason.forceUpdate && config.minAppVersion != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Version actuelle: ${RemoteConfigService.appVersion}  ·  Minimum: ${config.minAppVersion}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9CA3AF),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),

                const SizedBox(height: 40),

                // Retry button (maintenance only)
                if (reason == BlockingReason.maintenance)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Réessayer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
