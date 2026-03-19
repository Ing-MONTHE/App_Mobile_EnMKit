// ============================================================================
// Modifications appliquées :
// 1. Design épuré sans ombres lourdes
// 2. Bordures réduites et subtiles
// 3. Espacement optimisé
// 4. Fond d'icône léger au lieu de gradient
// ============================================================================

import 'package:flutter/material.dart';
import 'package:enmkit/ui/screens/faq_account_screen.dart';
import 'package:enmkit/ui/screens/faq_device_screen.dart';
import 'package:enmkit/ui/screens/faq_qr_screen.dart';
import 'package:enmkit/ui/screens/faq_troubleshoot_screen.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQ'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF1E293B),
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _buildSettingCard(
                context,
                'Compte & Connexion',
                'Problèmes d\'accès et sécurité',
                Icons.lock_outline,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FaqAccountScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),  // ✅ Réduit de 16 → 10
              _buildSettingCard(
                context,
                'Appareil / Kit',
                'Installation et utilisation du kit',
                Icons.memory,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FaqDeviceScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),  // ✅ Réduit
              _buildSettingCard(
                context,
                'QR & Configuration',
                'Génération et import du QR code',
                Icons.qr_code,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FaqQrScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),  // ✅ Réduit
              _buildSettingCard(
                context,
                'Dépannage',
                'Erreurs, pannes et solutions',
                Icons.build_outlined,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FaqTroubleshootScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// FONCTION _buildSettingCard STYLISÉE
// ============================================================================
/*
Widget _buildSettingCard(
  BuildContext context,
  String title,
  String subtitle,
  IconData icon,
  VoidCallback onTap,
) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(20),  // ← Trop d'espacement
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),  // ← Bordures larges
        boxShadow: const [  // ← Ombres lourdes
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(  // ← Gradient lourd
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            color: Colors.black38,
            size: 16,
          ),
        ],
      ),
    ),
  );
}
*/

Widget _buildSettingCard(
  BuildContext context,
  String title,
  String subtitle,
  IconData icon,
  VoidCallback onTap,
) {
  return InkWell(  // ✅ InkWell pour effet ripple
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,  // ✅ Réduit de 20 → 16
        vertical: 14,    // ✅ Réduit de 20 → 14
      ),
      decoration: BoxDecoration(
        color: Colors.white,  // ✅ Blanc pur
        borderRadius: BorderRadius.circular(12),  // ✅ Bordures réduites (16 → 12)
        border: Border.all(  // ✅ Bordure subtile au lieu d'ombre
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        // ✅ OMBRES RETIRÉES
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),  // ✅ Réduit de 12 → 10
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),  // ✅ Fond léger au lieu de gradient
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon, 
              color: const Color(0xFF3B82F6),  // ✅ Icône bleue
              size: 22,  // ✅ Réduit de 24 → 22
            ),
          ),
          const SizedBox(width: 14),  // ✅ Réduit de 16 → 14
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,  // ✅ Réduit de 16 → 15
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,  // ✅ Changé de arrow_forward_ios
            color: Color(0xFF94A3B8),
            size: 20,
          ),
        ],
      ),
    ),
  );
}