import 'package:enmkit/core/ai/energy_insights.dart';
import 'package:enmkit/core/education/education_content.dart';

/// Assistant HORS-LIGNE : répond sans Internet à partir des recommandations
/// du moteur d'analyse, des éco-gestes et du glossaire. C'est le repli de
/// l'assistant en ligne (serveur non configuré, pas de réseau, 503…).
///
/// Simple appariement de mots-clés : pas de « génération », uniquement du
/// contenu pédagogique validé et les résultats chiffrés du kit.
class LocalAssistant {
  LocalAssistant._();

  static const Map<TipCategory, List<String>> _keywords = {
    TipCategory.standby: ['veille', 'standby', 'nuit', 'night', 'chargeur', 'charger', 'décodeur', 'decoder'],
    TipCategory.lighting: ['led', 'ampoule', 'bulb', 'lampe', 'lamp', 'éclairage', 'eclairage', 'lighting', 'light'],
    TipCategory.peak: ['pointe', 'peak', 'soir', 'evening', 'délestage', 'delestage', 'fer', 'iron'],
    TipCategory.cooling: ['frigo', 'réfrigérateur', 'refrigerateur', 'fridge', 'clim', 'air', 'ventilateur', 'fan', 'froid', 'cool'],
    TipCategory.cost: ['facture', 'bill', 'fcfa', 'coût', 'cout', 'cost', 'prix', 'price', 'tarif', 'tariff', 'eneo', 'prépayé', 'prepaid', 'argent', 'money'],
    TipCategory.habits: ['conseil', 'tip', 'astuce', 'habitude', 'habit', 'économiser', 'economiser', 'save', 'réduire', 'reduire', 'reduce'],
  };

  /// Codes de recommandation reliés à chaque catégorie.
  static const Map<String, TipCategory> _recoCategory = {
    'HIGH_STANDBY': TipCategory.standby,
    'PEAK_HEAVY': TipCategory.peak,
    'RISING_TREND': TipCategory.habits,
    'ANOMALIES': TipCategory.habits,
    'DATA_GAPS': TipCategory.habits,
    'ALL_ZERO': TipCategory.habits,
    'GOOD_JOB': TipCategory.habits,
  };

  static String _norm(String s) => s.toLowerCase();

  /// Réponse hors-ligne à [question]. [insights] (optionnel) : analyse du kit.
  static String answer(String question, {required String lang, EnergyInsights? insights}) {
    final en = lang == 'en';
    final q = _norm(question);
    final parts = <String>[];

    // 1) Définition si un terme du glossaire est cité.
    for (final g in EducationContent.glossary) {
      final head = _norm(g.term.of(lang)).split('(').first.trim();
      final headFr = _norm(g.term.fr).split('(').first.trim();
      if ((head.length > 2 && q.contains(head)) || (headFr.length > 2 && q.contains(headFr))) {
        parts.add('• ${g.term.of(lang)} : ${g.definition.of(lang)}');
        if (parts.length >= 2) break;
      }
    }

    // 2) Catégories évoquées.
    final cats = <TipCategory>{
      for (final e in _keywords.entries)
        if (e.value.any(q.contains)) e.key,
    };

    // 3) Résultats chiffrés du kit (si disponibles).
    final hasData = insights != null && insights.hasData;
    final wantsData = ['ma conso', 'mon kit', 'my kit', 'my consumption', 'analyse', 'analysis', 'score', 'prévision', 'prevision', 'forecast', 'mois', 'month', 'anomal', 'combien', 'how much']
        .any(q.contains);
    if (hasData && (wantsData || cats.isNotEmpty || parts.isEmpty)) {
      final i = insights;
      parts.add(en
          ? '• Your kit: score ${i.score.value.round()}/100 (grade ${i.score.grade}), '
              '≈ ${i.avgDailyKwh.toStringAsFixed(2)} kWh/day, month forecast '
              '${i.forecast.monthKwh.toStringAsFixed(1)} kWh ≈ ${i.forecast.monthCostFcfa.round()} FCFA.'
          : '• Votre kit : score ${i.score.value.round()}/100 (note ${i.score.grade}), '
              '≈ ${i.avgDailyKwh.toStringAsFixed(2)} kWh/jour, prévision du mois '
              '${i.forecast.monthKwh.toStringAsFixed(1)} kWh ≈ ${i.forecast.monthCostFcfa.round()} FCFA.');
      final recos = i.recommendations
          .where((r) => cats.isEmpty || cats.contains(_recoCategory[r.code]))
          .take(2);
      for (final r in recos) {
        parts.add('• ${r.title}${en ? ':' : ' :'} ${r.body}');
      }
    }

    // 4) Éco-gestes correspondants (2 au plus).
    final tips = EducationContent.tips
        .where((t) => cats.isEmpty ? t.category == TipCategory.habits || t.category == TipCategory.standby : cats.contains(t.category))
        .take(2);
    for (final t in tips) {
      parts.add('• ${t.title.of(lang)} : ${t.body.of(lang)}');
    }

    final intro = en
        ? 'Offline answer (built from your kit data and the EnMKit guides):'
        : 'Réponse hors-ligne (issue des données de votre kit et des fiches EnMKit) :';
    final outro = en
        ? 'Tip: the "Energy education" module (TP1-TP7) details these notions.'
        : 'Astuce : le module « Éducation énergétique » (TP1-TP7) détaille ces notions.';
    return [intro, ...parts, outro].join('\n\n');
  }
}
