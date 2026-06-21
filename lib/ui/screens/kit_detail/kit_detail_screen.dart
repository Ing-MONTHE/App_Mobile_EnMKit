import 'package:enmkit/models/kit_model.dart';
import 'package:enmkit/providers.dart';
import 'package:enmkit/ui/screens/kit_detail/widgets/config_tab.dart';
import 'package:enmkit/ui/screens/kit_detail/widgets/consumption_tab.dart';
import 'package:enmkit/ui/screens/kit_detail/widgets/relays_tab.dart';
import 'package:enmkit/ui/theme/app_theme.dart';
import 'package:enmkit/ui/widgets/common/doodle_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Détail d'un kit : pilotage isolé via 3 onglets (Relais / Conso / Config).
/// Données issues des providers `.family` scopés sur [kit.kitNumber].
class KitDetailScreen extends ConsumerStatefulWidget {
  const KitDetailScreen({super.key, required this.kit});
  final KitModel kit;

  @override
  ConsumerState<KitDetailScreen> createState() => _KitDetailScreenState();
}

class _KitDetailScreenState extends ConsumerState<KitDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  String? get _kitNumber => widget.kit.kitNumber;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Maintient l'écoute SMS du kit active tant qu'on reste sur le détail.
    ref.watch(kitSmsListenerProvider(_kitNumber));

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: DoodleBackground(
        child: SafeArea(
          child: Column(
            children: [
              _DetailHeader(kit: widget.kit),
              _SoftTabBar(controller: _tabController),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    RelaysTab(kitNumber: _kitNumber),
                    ConsumptionTab(kitNumber: _kitNumber),
                    ConfigTab(kit: widget.kit),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// En-tête du détail : retour, nom du kit et numéro.
class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.kit});
  final KitModel kit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 20, 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 2),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primary, Color.lerp(primary, Colors.white, 0.3)!],
              ),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.electrical_services_rounded,
                color: Colors.white, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kit.displayName,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (kit.kitNumber != null)
                  Text(
                    kit.kitNumber!,
                    style: TextStyle(
                        color: scheme.onSurfaceVariant, fontSize: 12.5),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Barre d'onglets "pilule" douce.
class _SoftTabBar extends ConsumerWidget {
  const _SoftTabBar({required this.controller});
  final TabController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = ref.watch(tProvider);
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 2, 20, 6),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.elevedShadow(strength: 0.4),
      ),
      child: TabBar(
        controller: controller,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: primary,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
        labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
        tabs: [
          Tab(height: 40, text: t.t('tab.relays')),
          Tab(height: 40, text: t.t('tab.consumption')),
          Tab(height: 40, text: t.t('tab.config')),
        ],
      ),
    );
  }
}
