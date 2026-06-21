import 'package:flutter/material.dart';
import 'package:enmkit/ui/theme/app_theme.dart';

/// Illustrations vectorielles (flat design) des pages d'onboarding.
/// Chaque illustration est une scène composée (halo + formes + éléments)
/// dans un carré ~240, dans l'esprit des apps fintech modernes.

/// Cadre commun : halo radial doux + petits points décoratifs.
class _ArtFrame extends StatelessWidget {
  const _ArtFrame({required this.accent, required this.child});
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Halo lumineux TRÈS diffus, en deux couches pour un fondu plus doux.
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  accent.withValues(alpha: 0.16),
                  accent.withValues(alpha: 0.05),
                  accent.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
          Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  accent.withValues(alpha: 0.10),
                  accent.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          // "Scène" : plaque arrondie très douce (ombre diffuse, bord tendre).
          Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: 0.13),
                  accent.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(60),
              border: Border.all(color: accent.withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.16),
                  blurRadius: 36,
                  spreadRadius: -6,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
          ),
          // Pastilles décoratives, plus douces et discrètes.
          Positioned(top: 14, right: 26, child: _dot(accent, 11)),
          Positioned(bottom: 22, left: 18, child: _dot(accent, 7)),
          Positioned(top: 56, left: 8, child: _ring(accent, 16)),
          Positioned(bottom: 34, right: 12, child: _ring(accent, 22)),
          child,
        ],
      ),
    );
  }

  Widget _dot(Color c, double s) => Container(
        width: s,
        height: s,
        decoration:
            BoxDecoration(color: c.withValues(alpha: 0.22), shape: BoxShape.circle),
      );

  Widget _ring(Color c, double s) => Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: c.withValues(alpha: 0.20), width: 2),
        ),
      );
}

/// Petite tuile arrondie à dégradé portant une icône (brique des scènes).
Widget _gradTile(IconData icon, Color color,
    {double size = 76, double iconSize = 38, double radius = 22}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color, Color.lerp(color, Colors.white, 0.35)!],
      ),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.28),
          blurRadius: 22,
          spreadRadius: -4,
          offset: const Offset(0, 12),
        ),
      ],
    ),
    child: Icon(icon, color: Colors.white, size: iconSize),
  );
}

Widget _chip(Widget child) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.elevedShadow(strength: 0.5),
      ),
      child: child,
    );

/// Page 1 — Pilotage à distance par SMS : téléphone + ondes + ampoule.
class ArtRemoteControl extends StatelessWidget {
  const ArtRemoteControl({super.key});

  @override
  Widget build(BuildContext context) {
    return _ArtFrame(
      accent: AppTheme.indigo,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ondes entre le téléphone et l'ampoule.
          Positioned(
            child: Icon(Icons.wifi_tethering_rounded,
                size: 120, color: AppTheme.indigo.withValues(alpha: 0.18)),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _gradTile(Icons.smartphone_rounded, AppTheme.indigo),
              const SizedBox(width: 40),
              _gradTile(Icons.lightbulb_rounded, AppTheme.amber, size: 64,
                  iconSize: 32, radius: 18),
            ],
          ),
          // Bulle "SMS" flottante (commande envoyée).
          Positioned(
            top: 30,
            child: _chip(Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sms_rounded, size: 16, color: AppTheme.indigo),
                const SizedBox(width: 6),
                Text('r1on',
                    style: TextStyle(
                        color: AppTheme.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ],
            )),
          ),
          // Bulle "confirmation" flottante (accusé reçu du kit) — la boucle
          // complète envoi → confirmation.
          Positioned(
            bottom: 30,
            child: _chip(Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded,
                    size: 16, color: AppTheme.emerald),
                const SizedBox(width: 6),
                Text('confirmé',
                    style: TextStyle(
                        color: AppTheme.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
              ],
            )),
          ),
        ],
      ),
    );
  }
}

/// Page 2 — Suivi de consommation : carte avec courbe + barres + éclair.
class ArtConsumption extends StatelessWidget {
  const ArtConsumption({super.key});

  @override
  Widget build(BuildContext context) {
    return _ArtFrame(
      accent: AppTheme.emerald,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Carte "graphe".
          Container(
            width: 168,
            height: 130,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: AppTheme.elevedShadow(tint: AppTheme.emerald, strength: 0.7),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppTheme.emerald.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Icon(Icons.bolt_rounded,
                          color: AppTheme.emerald, size: 14),
                    ),
                    const SizedBox(width: 8),
                    Text('245 kWh',
                        style: TextStyle(
                            color: AppTheme.ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 12),
                // Mini barres.
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _bar(0.45),
                      _bar(0.70),
                      _bar(0.35),
                      _bar(0.85),
                      _bar(0.60),
                      _bar(1.0),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Éclair flottant en pastille.
          Positioned(
            right: 26,
            top: 36,
            child: _gradTile(Icons.show_chart_rounded, AppTheme.emerald,
                size: 56, iconSize: 28, radius: 16),
          ),
          // Badge de tendance flottant (scène plus complète).
          Positioned(
            left: 22,
            bottom: 38,
            child: _chip(Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.trending_up_rounded,
                    size: 14, color: AppTheme.emerald),
                const SizedBox(width: 4),
                Text('+12%',
                    style: TextStyle(
                        color: AppTheme.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 12)),
              ],
            )),
          ),
        ],
      ),
    );
  }

  Widget _bar(double h) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: FractionallySizedBox(
            heightFactor: h,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [AppTheme.emerald, Color(0xFF6EE7B7)],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      );
}

/// Page 3 — Sécurité & multi-kits : bouclier devant une pile de cartes kit.
class ArtSecurity extends StatelessWidget {
  const ArtSecurity({super.key});

  @override
  Widget build(BuildContext context) {
    return _ArtFrame(
      accent: AppTheme.coral,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cartes "kits" empilées en arrière-plan.
          Transform.translate(
            offset: const Offset(-46, 18),
            child: Transform.rotate(
              angle: -0.18,
              child: _kitCard(AppTheme.indigo),
            ),
          ),
          Transform.translate(
            offset: const Offset(46, 18),
            child: Transform.rotate(
              angle: 0.18,
              child: _kitCard(AppTheme.emerald),
            ),
          ),
          // Bouclier central au premier plan.
          _gradTile(Icons.shield_rounded, AppTheme.coral,
              size: 96, iconSize: 48, radius: 28),
          // Pastille « PIN · empreinte » flottante (scène plus complète).
          Positioned(
            bottom: 28,
            child: _chip(Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.fingerprint_rounded,
                    size: 16, color: AppTheme.coral),
                const SizedBox(width: 6),
                Text('PIN · empreinte',
                    style: TextStyle(
                        color: AppTheme.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 11)),
              ],
            )),
          ),
        ],
      ),
    );
  }

  Widget _kitCard(Color c) => Container(
        width: 78,
        height: 96,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppTheme.elevedShadow(tint: c, strength: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.electrical_services_rounded, color: c, size: 18),
            ),
            const Spacer(),
            Container(
              width: 44,
              height: 7,
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 5),
            Container(
              width: 30,
              height: 7,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      );
}
