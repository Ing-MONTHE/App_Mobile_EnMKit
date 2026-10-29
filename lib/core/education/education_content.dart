// Contenu pédagogique « Smart Home Learning Lab » — banc EnMKit à 4 lignes
// (L1–L2 : ampoules, L3–L4 : prises). Sept travaux pratiques TP1…TP7, quiz,
// éco-gestes et glossaire, contextualisés au Cameroun (ENEO, FCFA, 220 V).
//
// Bilingue FR/EN : chaque texte est un [Bi] résolu selon la langue courante
// (même logique de repli que AppStrings : l'anglais retombe sur le français).
// Le contenu long vit ici plutôt que dans le catalogue `strings.dart`, réservé
// aux libellés d'interface. Même forme que `GET /education/modules` (§5).

/// Texte bilingue.
class Bi {
  const Bi(this.fr, this.en);
  final String fr;
  final String en;
  String of(String locale) => locale == 'en' ? en : fr;
}

class QuizQuestion {
  const QuizQuestion({
    required this.question,
    required this.choices,
    required this.answerIndex,
    required this.explanation,
  });
  final Bi question;
  final List<Bi> choices;
  final int answerIndex;
  final Bi explanation;
}

/// Type de données « en direct » rattaché à un TP (carte affichée sur la fiche).
enum EduLive {
  /// Compteur, impulsions, index : réglages du kit + dernière trame.
  meter,

  /// Lignes du banc (état ON/OFF) et calcul I = P / U.
  circuits,

  /// Pilotage SMS : ouverture du kit, accusés.
  remote,

  /// Comparaison Scénario A / Scénario B à partir des trames horaires.
  compare,

  /// Analyse IA : veille, pointe, score.
  efficiency,

  /// Trames brutes et qualité des données.
  iot,
}

class EduModule {
  const EduModule({
    required this.code,
    required this.title,
    required this.objective,
    required this.durationMin,
    required this.steps,
    required this.outcomes,
    required this.quiz,
    required this.keyIdea,
    this.live,
    this.scenarioHint,
  });
  final String code;
  final Bi title;
  final Bi objective;
  final int durationMin;
  final List<Bi> steps;
  final List<Bi> outcomes;
  final List<QuizQuestion> quiz;

  /// Notion clé à retenir (encadré en tête de fiche).
  final Bi keyIdea;
  final EduLive? live;

  /// Pour les TP comparatifs : ce que représentent les scénarios A et B.
  final Bi? scenarioHint;
}

/// Catégories d'éco-gestes (mêmes codes que `GET /education/tips`).
enum TipCategory { standby, lighting, peak, cooling, habits, cost }

class EcoTip {
  const EcoTip(this.id, this.category, this.title, this.body);
  final String id;
  final TipCategory category;
  final Bi title;
  final Bi body;
}

class GlossaryEntry {
  const GlossaryEntry(this.term, this.definition);
  final Bi term;
  final Bi definition;
}

class EducationContent {
  EducationContent._();

  static EduModule? byCode(String code) {
    for (final m in modules) {
      if (m.code == code) return m;
    }
    return null;
  }

  // ===========================================================================
  // TRAVAUX PRATIQUES
  // ===========================================================================
  static const List<EduModule> modules = [
    // ---- TP1 ----------------------------------------------------------------
    EduModule(
      code: 'TP1',
      title: Bi('Comprendre et mesurer l\'énergie',
          'Understanding and measuring energy'),
      objective: Bi(
        'Distinguer puissance (W) et énergie (kWh), lire un compteur et sa '
            'constante d\'impulsions, puis chiffrer une consommation en FCFA.',
        'Tell power (W) from energy (kWh), read a meter and its pulse '
            'constant, then put a cost in FCFA on a consumption.',
      ),
      durationMin: 60,
      live: EduLive.meter,
      keyIdea: Bi(
        'Énergie = Puissance × Durée. Une ampoule de 100 W allumée 10 h '
            'consomme 100 × 10 = 1 000 Wh = 1 kWh. ENEO facture des kWh, pas '
            'des watts.',
        'Energy = Power × Time. A 100 W bulb on for 10 h uses 100 × 10 = '
            '1,000 Wh = 1 kWh. ENEO bills kWh, not watts.',
      ),
      steps: [
        Bi(
          'Observer le banc : repérer le disjoncteur, le compteur, le kit EnMKit '
              'et les 4 lignes (L1–L2 ampoules, L3–L4 prises). Le réseau délivre '
              '220 V / 50 Hz.',
          'Look at the bench: find the circuit breaker, the meter, the EnMKit '
              'kit and the 4 lines (L1–L2 bulbs, L3–L4 sockets). The grid '
              'supplies 220 V / 50 Hz.',
        ),
        Bi(
          'Relever la puissance inscrite sur l\'ampoule de L1 (ex. 9 W LED) et '
              'sur l\'appareil branché en L3 (ex. ventilateur 50 W, fer 1 000 W).',
          'Read the power printed on the L1 bulb (e.g. 9 W LED) and on the '
              'appliance plugged into L3 (e.g. 50 W fan, 1,000 W iron).',
        ),
        Bi(
          'Noter l\'index du compteur (kWh) et sa constante, inscrite en façade '
              '(ex. 1 000 imp/kWh, soit 1 impulsion = 1 Wh).',
          'Write down the meter index (kWh) and its constant printed on the '
              'front (e.g. 1,000 imp/kWh, i.e. 1 pulse = 1 Wh).',
        ),
        Bi(
          'Allumer uniquement L3 avec l\'appareil, puis compter les clignotements '
              'du voyant du compteur pendant 1 minute.',
          'Switch on L3 only with the appliance, then count the meter LED '
              'flashes for 1 minute.',
        ),
        Bi(
          'Calculer la puissance : P (W) = impulsions par minute × 60 × 1 000 / '
              'constante. Comparer à la valeur de la plaque signalétique.',
          'Compute the power: P (W) = pulses per minute × 60 × 1,000 / '
              'constant. Compare with the rating plate.',
        ),
        Bi(
          'Calculer l\'énergie pour 1 h puis pour un mois (4 h/jour × 30 j), et '
              'son coût à 50 FCFA/kWh (tranche sociale) et à 79 FCFA/kWh.',
          'Compute the energy for 1 h then for a month (4 h/day × 30 days), and '
              'its cost at 50 FCFA/kWh (social block) and at 79 FCFA/kWh.',
        ),
        Bi(
          'Laisser L3 allumée une heure pleine, puis comparer votre calcul avec la '
              'trame horaire reçue par SMS (onglet « Analyse IA » du kit).',
          'Leave L3 on for one full hour, then compare your calculation with '
              'the hourly frame received by SMS ("AI analysis" tab of the kit).',
        ),
      ],
      outcomes: [
        Bi('Différencier W, kW et kWh.', 'Tell W, kW and kWh apart.'),
        Bi('Appliquer la relation E = P × t.', 'Apply the relation E = P × t.'),
        Bi('Lire un compteur et utiliser sa constante imp/kWh.',
            'Read a meter and use its imp/kWh constant.'),
        Bi('Estimer un coût mensuel en FCFA.',
            'Estimate a monthly cost in FCFA.'),
      ],
      quiz: [
        QuizQuestion(
          question: Bi('Quelle grandeur ENEO facture-t-elle ?',
              'Which quantity does ENEO bill?'),
          choices: [
            Bi('La puissance, en kW', 'Power, in kW'),
            Bi('L\'énergie, en kWh', 'Energy, in kWh'),
            Bi('La tension, en V', 'Voltage, in V'),
            Bi('Le courant, en A', 'Current, in A'),
          ],
          answerIndex: 1,
          explanation: Bi(
            'La facture compte l\'énergie consommée (kWh) ; la puissance (kW) '
                'n\'est qu\'un débit instantané.',
            'The bill counts the energy used (kWh); power (kW) is only an '
                'instantaneous rate.',
          ),
        ),
        QuizQuestion(
          question: Bi('Une ampoule de 100 W allumée 10 h consomme :',
              'A 100 W bulb on for 10 h uses:'),
          choices: [
            Bi('0,1 kWh', '0.1 kWh'),
            Bi('1 kWh', '1 kWh'),
            Bi('10 kWh', '10 kWh'),
            Bi('1 000 kWh', '1,000 kWh'),
          ],
          answerIndex: 1,
          explanation: Bi('100 W × 10 h = 1 000 Wh = 1 kWh.',
              '100 W × 10 h = 1,000 Wh = 1 kWh.'),
        ),
        QuizQuestion(
          question: Bi(
              'Un compteur de constante 1 000 imp/kWh : une impulsion vaut…',
              'A meter with a 1,000 imp/kWh constant: one pulse is worth…'),
          choices: [
            Bi('1 kWh', '1 kWh'),
            Bi('10 Wh', '10 Wh'),
            Bi('1 Wh', '1 Wh'),
            Bi('0,1 Wh', '0.1 Wh'),
          ],
          answerIndex: 2,
          explanation: Bi('1 kWh = 1 000 Wh réparti sur 1 000 impulsions.',
              '1 kWh = 1,000 Wh spread over 1,000 pulses.'),
        ),
        QuizQuestion(
          question: Bi('2 kWh facturés à 79 FCFA/kWh coûtent :',
              '2 kWh billed at 79 FCFA/kWh cost:'),
          choices: [
            Bi('79 FCFA', '79 FCFA'),
            Bi('158 FCFA', '158 FCFA'),
            Bi('1 580 FCFA', '1,580 FCFA'),
            Bi('40 FCFA', '40 FCFA'),
          ],
          answerIndex: 1,
          explanation: Bi('2 × 79 = 158 FCFA.', '2 × 79 = 158 FCFA.'),
        ),
      ],
    ),

    // ---- TP2 ----------------------------------------------------------------
    EduModule(
      code: 'TP2',
      title: Bi('Comprendre les circuits', 'Understanding circuits'),
      objective: Bi(
        'Identifier les conducteurs, comprendre le montage en parallèle des '
            'lignes et le rôle du disjoncteur, et calculer le courant appelé.',
        'Identify the conductors, understand why lines are wired in parallel '
            'and what the circuit breaker does, and compute the current drawn.',
      ),
      durationMin: 60,
      live: EduLive.circuits,
      keyIdea: Bi(
        'Toutes les lignes sont en parallèle : chacune reçoit 220 V. Le courant '
            'appelé vaut I = P / U ; les courants des lignes s\'additionnent dans '
            'le disjoncteur général.',
        'All lines are in parallel: each one gets 220 V. The current drawn is '
            'I = P / U; the line currents add up in the main breaker.',
      ),
      steps: [
        Bi(
          'SÉCURITÉ : couper le disjoncteur général et vérifier l\'absence de '
              'tension avec un testeur avant toute manipulation.',
          'SAFETY: switch off the main breaker and check there is no voltage '
              'with a tester before touching anything.',
        ),
        Bi(
          'Repérer les conducteurs : phase (rouge/marron), neutre (bleu), terre '
              '(vert-jaune).',
          'Identify the conductors: live (red/brown), neutral (blue), earth '
              '(green-yellow).',
        ),
        Bi(
          'Suivre chaque ligne du disjoncteur jusqu\'à sa charge (L1–L2 ampoules, '
              'L3–L4 prises) et dessiner le schéma du banc.',
          'Follow each line from the breaker to its load (L1–L2 bulbs, L3–L4 '
              'sockets) and draw the bench diagram.',
        ),
        Bi(
          'Remettre sous tension, allumer L1 puis L2 depuis l\'application : '
              'constater que couper une ligne n\'éteint pas les autres.',
          'Power up again, switch L1 then L2 on from the app: notice that '
              'switching one line off does not affect the others.',
        ),
        Bi(
          'Calculer le courant de chaque charge : I = P / 220. Ex. fer 1 100 W → '
              '5 A ; ampoule 9 W → 0,04 A.',
          'Compute the current of each load: I = P / 220. E.g. 1,100 W iron → '
              '5 A; 9 W bulb → 0.04 A.',
        ),
        Bi(
          'Additionner les courants et comparer au calibre du disjoncteur (ex. '
              '10 A éclairage, 16 A prises) : que se passe-t-il en surcharge ?',
          'Add up the currents and compare with the breaker rating (e.g. 10 A '
              'lighting, 16 A sockets): what happens on overload?',
        ),
      ],
      outcomes: [
        Bi('Reconnaître phase, neutre et terre.',
            'Recognise live, neutral and earth.'),
        Bi('Expliquer le montage en parallèle d\'une installation domestique.',
            'Explain why a home installation is wired in parallel.'),
        Bi('Calculer un courant avec I = P / U.',
            'Compute a current with I = P / U.'),
        Bi('Justifier le calibre d\'un disjoncteur.',
            'Justify a circuit-breaker rating.'),
      ],
      quiz: [
        QuizQuestion(
          question: Bi('Dans une maison, les lampes sont montées :',
              'In a house, lamps are wired:'),
          choices: [
            Bi('En série', 'In series'),
            Bi('En parallèle', 'In parallel'),
            Bi('Au hasard', 'Randomly'),
          ],
          answerIndex: 1,
          explanation: Bi(
            'En parallèle, chaque lampe reçoit la pleine tension et fonctionne '
                'indépendamment des autres.',
            'In parallel, each lamp gets the full voltage and works '
                'independently of the others.',
          ),
        ),
        QuizQuestion(
          question: Bi('Courant appelé par un fer de 2 200 W sous 220 V ?',
              'Current drawn by a 2,200 W iron at 220 V?'),
          choices: [
            Bi('1 A', '1 A'),
            Bi('10 A', '10 A'),
            Bi('22 A', '22 A'),
            Bi('100 A', '100 A'),
          ],
          answerIndex: 1,
          explanation: Bi('I = P / U = 2 200 / 220 = 10 A.',
              'I = P / U = 2,200 / 220 = 10 A.'),
        ),
        QuizQuestion(
          question: Bi('Le rôle du disjoncteur est de :',
              'The role of the circuit breaker is to:'),
          choices: [
            Bi('Mesurer la consommation', 'Measure consumption'),
            Bi('Couper le circuit en cas de surcharge ou de court-circuit',
                'Cut the circuit on overload or short circuit'),
            Bi('Augmenter la tension', 'Increase the voltage'),
          ],
          answerIndex: 1,
          explanation: Bi(
            'Il protège les câbles et les personnes en ouvrant le circuit quand '
                'le courant devient dangereux.',
            'It protects cables and people by opening the circuit when the '
                'current becomes dangerous.',
          ),
        ),
        QuizQuestion(
          question: Bi('Le fil vert-jaune est :', 'The green-yellow wire is:'),
          choices: [
            Bi('La phase', 'Live'),
            Bi('Le neutre', 'Neutral'),
            Bi('La terre', 'Earth'),
          ],
          answerIndex: 2,
          explanation: Bi(
            'La terre évacue les courants de défaut et protège des chocs '
                'électriques.',
            'Earth carries fault currents away and protects from electric '
                'shocks.',
          ),
        ),
      ],
    ),

    // ---- TP3 ----------------------------------------------------------------
    EduModule(
      code: 'TP3',
      title: Bi('Commander à distance par SMS', 'Remote control by SMS'),
      objective: Bi(
        'Piloter une ligne par SMS sans Internet, comprendre l\'accusé de '
            'réception et la sécurité par numéros autorisés.',
        'Control a line by SMS without Internet, understand the '
            'acknowledgement and the authorised-number security.',
      ),
      durationMin: 45,
      live: EduLive.remote,
      keyIdea: Bi(
        'Commande → réseau GSM → kit → relais → accusé « r1on ». Sans accusé, on '
            'ne sait pas si l\'ordre a été exécuté : c\'est la boucle de retour.',
        'Command → GSM network → kit → relay → "r1on" acknowledgement. Without '
            'an acknowledgement we do not know if the order was executed: that '
            'is the feedback loop.',
      ),
      steps: [
        Bi('Ouvrir le kit du banc dans l\'application, onglet « Lignes ».',
            'Open the bench kit in the app, "Lines" tab.'),
        Bi(
          'Allumer L1 : l\'application envoie le SMS « r1on ». Chronométrer le '
              'délai jusqu\'à l\'accusé du kit.',
          'Switch L1 on: the app sends the SMS "r1on". Time the delay until '
              'the kit acknowledgement.',
        ),
        Bi('Éteindre L1 (« r1off ») puis piloter L3 (prise) de la même façon.',
            'Switch L1 off ("r1off") then control L3 (socket) the same way.'),
        Bi(
          'Consulter l\'historique des accusés (icône horloge) : heure et texte '
              'exact renvoyé par le kit.',
          'Look at the acknowledgement history (clock icon): time and exact '
              'text sent back by the kit.',
        ),
        Bi(
          'Envoyer « r2on » depuis un téléphone NON autorisé : le kit doit '
              'l\'ignorer. Expliquer pourquoi.',
          'Send "r2on" from a NON-authorised phone: the kit must ignore it. '
              'Explain why.',
        ),
        Bi(
          'Imaginer trois usages utiles au Cameroun (chauffe-eau, pompe, '
              'éclairage extérieur…) et leurs risques.',
          'Imagine three useful uses in Cameroon (water heater, pump, outdoor '
              'lighting…) and their risks.',
        ),
      ],
      outcomes: [
        Bi('Décrire la chaîne de commande à distance par GSM.',
            'Describe the GSM remote-control chain.'),
        Bi('Expliquer le rôle d\'un accusé de réception.',
            'Explain the role of an acknowledgement.'),
        Bi('Justifier la liste de numéros autorisés.',
            'Justify the list of authorised numbers.'),
      ],
      quiz: [
        QuizQuestion(
          question: Bi('Après « r2on », le kit renvoie :',
              'After "r2on", the kit sends back:'),
          choices: [
            Bi('Rien', 'Nothing'),
            Bi('L\'accusé « r2on »', 'The "r2on" acknowledgement'),
            Bi('Sa consommation totale', 'Its total consumption'),
          ],
          answerIndex: 1,
          explanation: Bi(
            'L\'écho confirme que la ligne 2 est réellement passée sur ON.',
            'The echo confirms that line 2 really switched ON.',
          ),
        ),
        QuizQuestion(
          question: Bi('La commande par SMS nécessite-t-elle Internet ?',
              'Does SMS control need Internet?'),
          choices: [
            Bi('Oui, toujours', 'Yes, always'),
            Bi('Non, le réseau GSM suffit', 'No, the GSM network is enough'),
          ],
          answerIndex: 1,
          explanation: Bi(
            'Le SMS passe par le réseau GSM, disponible même sans données '
                'mobiles.',
            'SMS goes through the GSM network, available even without mobile '
                'data.',
          ),
        ),
        QuizQuestion(
          question: Bi('Pourquoi limiter les numéros autorisés (n1, n2) ?',
              'Why restrict the authorised numbers (n1, n2)?'),
          choices: [
            Bi('Pour économiser du crédit', 'To save airtime'),
            Bi('Pour qu\'un inconnu ne puisse pas piloter l\'installation',
                'So that a stranger cannot control the installation'),
            Bi('Pour accélérer les SMS', 'To speed up SMS'),
          ],
          answerIndex: 1,
          explanation: Bi('C\'est la sécurité du kit : il ignore les autres numéros.',
              'It is the kit\'s security: it ignores other numbers.'),
        ),
      ],
    ),

    // ---- TP4 ----------------------------------------------------------------
    EduModule(
      code: 'TP4',
      title: Bi('Comparer les usages', 'Comparing uses'),
      objective: Bi(
        'Mesurer et comparer deux usages sur une même durée à partir des trames '
            'horaires du kit, puis extrapoler l\'écart en kWh et en FCFA.',
        'Measure and compare two uses over the same duration from the kit\'s '
            'hourly frames, then extrapolate the gap in kWh and FCFA.',
      ),
      durationMin: 90,
      live: EduLive.compare,
      scenarioHint: Bi(
        'Scénario A : L1 + L2 avec ampoules classiques (incandescence ou '
            'halogène). Scénario B : mêmes lignes avec ampoules LED.',
        'Scenario A: L1 + L2 with classic bulbs (incandescent or halogen). '
            'Scenario B: same lines with LED bulbs.',
      ),
      keyIdea: Bi(
        'Comparer équitablement = même durée, mêmes conditions, une seule '
            'variable changée. Les trames étant horaires, chaque scénario doit '
            'couvrir des heures pleines.',
        'A fair comparison = same duration, same conditions, one single '
            'variable changed. Frames being hourly, each scenario must cover '
            'whole hours.',
      ),
      steps: [
        Bi(
          'Choisir les deux usages à comparer et éteindre toutes les autres '
              'lignes.',
          'Choose the two uses to compare and switch every other line off.',
        ),
        Bi(
          'Scénario A : à une heure pile (ex. 09:00), allumer L1 + L2 avec les '
              'ampoules classiques. Enregistrer le début dans la carte ci-dessous.',
          'Scenario A: on the hour (e.g. 09:00), switch L1 + L2 on with the '
              'classic bulbs. Record the start in the card below.',
        ),
        Bi('À l\'heure pile suivante (10:00), éteindre et enregistrer la fin de A.',
            'At the next full hour (10:00), switch off and record the end of A.'),
        Bi(
          'Scénario B : remplacer par des LED (hors tension !) et refaire la même '
              'durée (10:00–11:00).',
          'Scenario B: swap for LEDs (power off!) and repeat the same duration '
              '(10:00–11:00).',
        ),
        Bi(
          'Attendre les trames horaires (elles arrivent après la fin de chaque '
              'heure), puis lire la comparaison calculée.',
          'Wait for the hourly frames (they arrive after the end of each hour), '
              'then read the computed comparison.',
        ),
        Bi(
          'Extrapoler : écart × 5 h/jour × 30 jours, puis en FCFA. Discuter des '
              'sources d\'erreur (heures incomplètes, autres charges).',
          'Extrapolate: gap × 5 h/day × 30 days, then in FCFA. Discuss the error '
              'sources (incomplete hours, other loads).',
        ),
      ],
      outcomes: [
        Bi('Concevoir une comparaison équitable.', 'Design a fair comparison.'),
        Bi('Calculer un écart absolu et relatif (%).',
            'Compute an absolute and relative (%) gap.'),
        Bi('Extrapoler une économie mensuelle en FCFA.',
            'Extrapolate a monthly saving in FCFA.'),
      ],
      quiz: [
        QuizQuestion(
          question: Bi(
              'Une LED de 9 W remplace une ampoule de 60 W. Économie d\'énergie ?',
              'A 9 W LED replaces a 60 W bulb. Energy saving?'),
          choices: [
            Bi('Environ 15 %', 'About 15%'),
            Bi('Environ 50 %', 'About 50%'),
            Bi('Environ 85 %', 'About 85%'),
          ],
          answerIndex: 2,
          explanation: Bi('(60 − 9) / 60 = 85 % pour la même lumière.',
              '(60 − 9) / 60 = 85% for the same light.'),
        ),
        QuizQuestion(
          question: Bi('Pourquoi garder la même durée pour A et B ?',
              'Why keep the same duration for A and B?'),
          choices: [
            Bi('Pour que seule la variable étudiée change',
                'So that only the studied variable changes'),
            Bi('Pour économiser des SMS', 'To save SMS'),
            Bi('Ce n\'est pas nécessaire', 'It is not necessary'),
          ],
          answerIndex: 0,
          explanation: Bi('Sinon la différence mesurée mélange durée et usage.',
              'Otherwise the measured gap mixes duration and use.'),
        ),
        QuizQuestion(
          question: Bi('Quelle est la résolution temporelle des données du kit ?',
              'What is the time resolution of the kit data?'),
          choices: [
            Bi('La seconde', 'One second'),
            Bi('L\'heure', 'One hour'),
            Bi('Le mois', 'One month'),
          ],
          answerIndex: 1,
          explanation: Bi(
            'Le kit envoie une trame par heure (JJ/MM/AA;HH;KWH) : un scénario '
                'doit couvrir des heures pleines.',
            'The kit sends one frame per hour (DD/MM/YY;HH;KWH): a scenario must '
                'cover whole hours.',
          ),
        ),
      ],
    ),

    // ---- TP5 ----------------------------------------------------------------
    EduModule(
      code: 'TP5',
      title: Bi('Efficacité énergétique', 'Energy efficiency'),
      objective: Bi(
        'Mesurer la consommation de veille, comprendre la pointe du soir et '
            'interpréter le score d\'efficacité calculé par l\'IA.',
        'Measure standby consumption, understand the evening peak and '
            'interpret the efficiency score computed by the AI.',
      ),
      durationMin: 90,
      live: EduLive.efficiency,
      scenarioHint: Bi(
        'Scénario A : appareils en veille branchés sur L3–L4 (décodeur, '
            'chargeurs, TV), lumières éteintes. Scénario B : tout débranché.',
        'Scenario A: appliances on standby plugged into L3–L4 (decoder, '
            'chargers, TV), lights off. Scenario B: everything unplugged.',
      ),
      keyIdea: Bi(
        'Une veille de 20 W coûte 20 W × 24 h × 30 j = 14,4 kWh par mois, sans '
            'aucun service rendu. Le meilleur kWh est celui qu\'on ne consomme pas.',
        'A 20 W standby costs 20 W × 24 h × 30 days = 14.4 kWh per month, '
            'with no service at all. The best kWh is the one you do not use.',
      ),
      steps: [
        Bi(
          'Scénario A : brancher les appareils en veille sur L3–L4 pendant une '
              'heure pleine, lumières éteintes ; enregistrer la fenêtre.',
          'Scenario A: plug the standby appliances into L3–L4 for one full '
              'hour, lights off; record the window.',
        ),
        Bi('Scénario B : tout débrancher pendant l\'heure suivante ; enregistrer.',
            'Scenario B: unplug everything for the next hour; record it.'),
        Bi(
          'Comparer A et B : l\'écart est la puissance de veille. L\'extrapoler sur '
              'un mois et un an, en kWh et en FCFA.',
          'Compare A and B: the gap is the standby power. Extrapolate it over a '
              'month and a year, in kWh and FCFA.',
        ),
        Bi(
          'Ouvrir l\'onglet « Analyse IA » : lire la charge de veille (00–05 h), '
              'l\'heure de pointe et le score A–E.',
          'Open the "AI analysis" tab: read the base load (00–05 h), the peak '
              'hour and the A–E score.',
        ),
        Bi(
          'Proposer trois actions pour améliorer le score (multiprise à '
              'interrupteur, décalage hors pointe 18–23 h, LED).',
          'Suggest three actions to improve the score (switchable power strip, '
              'shifting out of the 18–23 h peak, LEDs).',
        ),
      ],
      outcomes: [
        Bi('Mesurer une consommation de veille.',
            'Measure standby consumption.'),
        Bi('Expliquer l\'enjeu de la pointe du soir pour le réseau ENEO.',
            'Explain why the evening peak matters for the ENEO grid.'),
        Bi('Interpréter un score d\'efficacité et ses pénalités.',
            'Interpret an efficiency score and its penalties.'),
      ],
      quiz: [
        QuizQuestion(
          question: Bi('La consommation de veille, c\'est :',
              'Standby consumption is:'),
          choices: [
            Bi('L\'énergie des appareils éteints mais branchés',
                'The energy of appliances off but plugged in'),
            Bi('L\'énergie de l\'éclairage', 'The lighting energy'),
            Bi('Une coupure ENEO', 'An ENEO outage'),
          ],
          answerIndex: 0,
          explanation: Bi(
            'Voyants, horloges, transformateurs : ils consomment en continu.',
            'Indicator lights, clocks, power adapters: they draw power '
                'continuously.',
          ),
        ),
        QuizQuestion(
          question: Bi('Quand vaut-il mieux faire fonctionner un gros appareil ?',
              'When is it best to run a heavy appliance?'),
          choices: [
            Bi('Entre 18 h et 23 h', 'Between 18:00 and 23:00'),
            Bi('En journée, hors pointe', 'During the day, off-peak'),
            Bi('Peu importe', 'It does not matter'),
          ],
          answerIndex: 1,
          explanation: Bi(
            'Le soir, tout le monde consomme : le réseau est saturé (baisses de '
                'tension, délestages).',
            'In the evening everybody consumes: the grid is saturated (voltage '
                'drops, load shedding).',
          ),
        ),
        QuizQuestion(
          question: Bi('Une veille de 10 W permanente consomme par mois :',
              'A permanent 10 W standby uses per month:'),
          choices: [
            Bi('0,3 kWh', '0.3 kWh'),
            Bi('7,2 kWh', '7.2 kWh'),
            Bi('72 kWh', '72 kWh'),
          ],
          answerIndex: 1,
          explanation: Bi('10 W × 24 h × 30 j = 7 200 Wh = 7,2 kWh.',
              '10 W × 24 h × 30 days = 7,200 Wh = 7.2 kWh.'),
        ),
      ],
    ),

    // ---- TP6 ----------------------------------------------------------------
    EduModule(
      code: 'TP6',
      title: Bi('Internet des objets et données', 'Internet of Things and data'),
      objective: Bi(
        'Comprendre la chaîne IoT du kit (capteur → modem GSM → SMS → '
            'application → serveur), décoder une trame et évaluer la qualité '
            'des données.',
        'Understand the kit\'s IoT chain (sensor → GSM modem → SMS → app → '
            'server), decode a frame and assess data quality.',
      ),
      durationMin: 60,
      live: EduLive.iot,
      keyIdea: Bi(
        'Une donnée n\'a de valeur que si elle est fiable : complétude, '
            'absence de doublons et horodatage cohérent conditionnent toute '
            'analyse, y compris par l\'IA.',
        'Data is only valuable if it is reliable: completeness, no duplicates '
            'and consistent timestamps condition any analysis, including by AI.',
      ),
      steps: [
        Bi(
          'Dessiner la chaîne : impulsions du compteur → microcontrôleur du kit → '
              'modem GSM → SMS → téléphone → (option) serveur EnMKit.',
          'Draw the chain: meter pulses → kit microcontroller → GSM modem → SMS '
              '→ phone → (optional) EnMKit server.',
        ),
        Bi(
          'Décoder la dernière trame reçue (carte ci-dessous) : date, heure de '
              'début du créneau, énergie de l\'heure.',
          'Decode the latest frame received (card below): date, slot start '
              'hour, energy for the hour.',
        ),
        Bi(
          'Expliquer pourquoi la valeur est un « delta » (énergie de l\'heure) et '
              'non un index cumulé.',
          'Explain why the value is a "delta" (energy of the hour) and not a '
              'cumulative index.',
        ),
        Bi(
          'Lire la complétude et les trous de données dans « Analyse IA » ; '
              'proposer des causes (réseau, crédit SMS, coupure).',
          'Read completeness and data gaps in "AI analysis"; suggest causes '
              '(network, SMS credit, outage).',
        ),
        Bi(
          'Expliquer pourquoi recevoir deux fois la même trame ne compte pas '
              'double (clé unique kit + heure, le dernier reçu gagne).',
          'Explain why receiving the same frame twice does not count double '
              '(unique key kit + hour, last received wins).',
        ),
        Bi(
          'Débattre : quelles données partager, avec qui, et comment protéger la '
              'vie privée d\'un ménage ?',
          'Debate: which data to share, with whom, and how to protect a '
              'household\'s privacy?',
        ),
      ],
      outcomes: [
        Bi('Décrire l\'architecture d\'un objet connecté.',
            'Describe the architecture of a connected object.'),
        Bi('Décoder et valider une trame de données.',
            'Decode and validate a data frame.'),
        Bi('Évaluer la qualité d\'un jeu de données.',
            'Assess the quality of a dataset.'),
      ],
      quiz: [
        QuizQuestion(
          question: Bi('Dans « 27/06/26;09;0.12 », que signifie « 09 » ?',
              'In "27/06/26;09;0.12", what does "09" mean?'),
          choices: [
            Bi('La consommation entre 09:00 et 10:00',
                'Consumption between 09:00 and 10:00'),
            Bi('Le numéro de la ligne', 'The line number'),
            Bi('9 kWh', '9 kWh'),
          ],
          answerIndex: 0,
          explanation: Bi('HH est l\'heure de DÉBUT du créneau d\'une heure.',
              'HH is the START hour of the one-hour slot.'),
        ),
        QuizQuestion(
          question: Bi('Dans cette trame, « 0.12 » est :',
              'In this frame, "0.12" is:'),
          choices: [
            Bi('L\'index total du compteur', 'The total meter index'),
            Bi('L\'énergie consommée pendant cette heure',
                'The energy used during that hour'),
            Bi('La puissance maximale', 'The maximum power'),
          ],
          answerIndex: 1,
          explanation: Bi('C\'est un delta : 0,12 kWh entre 09:00 et 10:00.',
              'It is a delta: 0.12 kWh between 09:00 and 10:00.'),
        ),
        QuizQuestion(
          question: Bi('Une complétude de 75 % signifie :',
              'A 75% completeness means:'),
          choices: [
            Bi('75 % des heures attendues ont été reçues',
                '75% of the expected hours were received'),
            Bi('La consommation a baissé de 25 %', 'Consumption fell by 25%'),
            Bi('Le kit est chargé à 75 %', 'The kit is 75% charged'),
          ],
          answerIndex: 0,
          explanation: Bi('Un quart des créneaux horaires manque : prudence dans l\'analyse.',
              'A quarter of the hourly slots is missing: be careful with the analysis.'),
        ),
      ],
    ),

    // ---- TP7 ----------------------------------------------------------------
    EduModule(
      code: 'TP7',
      title: Bi('Mini-projet d\'apprenants', 'Learners\' mini-project'),
      objective: Bi(
        'Mener en équipe un projet complet : problème réel, mesure de référence, '
            'action, mesure après, présentation chiffrée des résultats.',
        'Run a complete team project: real problem, baseline measurement, '
            'action, after measurement, quantified presentation of results.',
      ),
      durationMin: 180,
      live: EduLive.compare,
      scenarioHint: Bi(
        'Scénario A : situation de référence (avant). Scénario B : situation '
            'après votre action.',
        'Scenario A: baseline (before). Scenario B: situation after your '
            'action.',
      ),
      keyIdea: Bi(
        'Sans mesure « avant », pas de preuve « après ». Un bon projet énergie '
            'annonce un gain chiffré (kWh, FCFA, %) et sa méthode.',
        'Without a "before" measurement there is no "after" proof. A good '
            'energy project states a quantified gain (kWh, FCFA, %) and its '
            'method.',
      ),
      steps: [
        Bi(
          'Choisir un problème réel (facture d\'une salle de classe, éclairage '
              'd\'une boutique, veille d\'un bureau…) et formuler un objectif '
              'chiffré.',
          'Pick a real problem (a classroom bill, a shop\'s lighting, an '
              'office\'s standby…) and state a quantified goal.',
        ),
        Bi('Reproduire la situation sur le banc et mesurer la référence (Scénario A).',
            'Reproduce the situation on the bench and measure the baseline (Scenario A).'),
        Bi(
          'Concevoir l\'action : remplacement d\'équipement, programmation par SMS, '
              'changement d\'habitude.',
          'Design the action: equipment swap, SMS scheduling, habit change.',
        ),
        Bi('Mettre en œuvre puis mesurer sur la même durée (Scénario B).',
            'Implement it then measure over the same duration (Scenario B).'),
        Bi(
          'Calculer le gain en kWh, %, FCFA par mois et le temps de retour sur '
              'investissement.',
          'Compute the gain in kWh, %, FCFA per month and the payback time.',
        ),
        Bi(
          'Présenter en 5 minutes : problème, méthode, résultats, limites. '
              'Évaluation par les pairs.',
          'Present in 5 minutes: problem, method, results, limits. Peer '
              'assessment.',
        ),
      ],
      outcomes: [
        Bi('Conduire une démarche de projet complète.',
            'Run a complete project approach.'),
        Bi('Argumenter avec des données mesurées.',
            'Argue with measured data.'),
        Bi('Calculer un temps de retour sur investissement.',
            'Compute a payback time.'),
        Bi('Travailler et présenter en équipe.', 'Work and present as a team.'),
      ],
      quiz: [
        QuizQuestion(
          question: Bi('Qu\'est-ce qu\'une mesure de référence ?',
              'What is a baseline measurement?'),
          choices: [
            Bi('La mesure avant l\'action, pour comparer',
                'The measurement before the action, to compare with'),
            Bi('La meilleure mesure obtenue', 'The best measurement obtained'),
            Bi('La mesure du voisin', 'The neighbour\'s measurement'),
          ],
          answerIndex: 0,
          explanation: Bi('Elle sert de point de comparaison au résultat.',
              'It is the comparison point for the result.'),
        ),
        QuizQuestion(
          question: Bi(
              'Une LED à 1 500 FCFA fait économiser 300 FCFA/mois. Retour sur '
                  'investissement ?',
              'A 1,500 FCFA LED saves 300 FCFA/month. Payback time?'),
          choices: [
            Bi('5 mois', '5 months'),
            Bi('15 mois', '15 months'),
            Bi('3 mois', '3 months'),
          ],
          answerIndex: 0,
          explanation: Bi('1 500 / 300 = 5 mois.', '1,500 / 300 = 5 months.'),
        ),
        QuizQuestion(
          question: Bi('Quel indicateur convainc le mieux un décideur ?',
              'Which indicator best convinces a decision maker?'),
          choices: [
            Bi('« On consomme moins »', '"We use less"'),
            Bi('« −12 kWh/mois, soit −950 FCFA/mois »',
                '"−12 kWh/month, i.e. −950 FCFA/month"'),
            Bi('« L\'application est jolie »', '"The app looks nice"'),
          ],
          answerIndex: 1,
          explanation: Bi('Un gain chiffré, en énergie et en argent, est vérifiable.',
              'A quantified gain, in energy and money, can be checked.'),
        ),
      ],
    ),
  ];

  // ===========================================================================
  // ÉCO-GESTES
  // ===========================================================================
  static const List<EcoTip> tips = [
    EcoTip('led', TipCategory.lighting, Bi('Passez aux LED', 'Switch to LEDs'),
        Bi(
          'Une LED de 9 W éclaire comme une ampoule de 60 W et dure 15 fois plus '
              'longtemps : 85 % d\'énergie en moins sur l\'éclairage.',
          'A 9 W LED gives as much light as a 60 W bulb and lasts 15 times '
              'longer: 85% less energy for lighting.',
        )),
    EcoTip('daylight', TipCategory.lighting,
        Bi('Profitez de la lumière du jour', 'Use daylight'),
        Bi(
          'Ouvrez rideaux et volets en journée et éteignez en quittant une pièce.',
          'Open curtains and shutters during the day and switch off when '
              'leaving a room.',
        )),
    EcoTip('strip', TipCategory.standby,
        Bi('Multiprise à interrupteur', 'Switchable power strip'),
        Bi(
          'Décodeur, TV, chaîne hi-fi : coupez-les tous d\'un geste le soir. Une '
              'veille de 20 W représente 14 kWh par mois.',
          'Decoder, TV, hi-fi: switch them all off at once at night. A 20 W '
              'standby is 14 kWh per month.',
        )),
    EcoTip('chargers', TipCategory.standby,
        Bi('Débranchez les chargeurs', 'Unplug chargers'),
        Bi(
          'Un chargeur branché sans téléphone chauffe : il consomme pour rien.',
          'A charger plugged in without a phone gets warm: it is wasting energy.',
        )),
    EcoTip('peak', TipCategory.peak,
        Bi('Évitez la pointe 18 h – 23 h', 'Avoid the 18:00–23:00 peak'),
        Bi(
          'Repassage, pompage et lessive en journée soulagent le réseau ENEO et '
              'limitent les baisses de tension qui abîment les appareils.',
          'Ironing, pumping and laundry during the day relieve the ENEO grid and '
              'limit the voltage drops that damage appliances.',
        )),
    EcoTip('iron', TipCategory.peak,
        Bi('Repassez en une seule fois', 'Iron in one go'),
        Bi(
          'Un fer de 1 000 W chauffe longtemps : regroupez le linge et '
              'débranchez-le avant la fin, la chaleur résiduelle suffit.',
          'A 1,000 W iron takes long to heat: group the laundry and unplug it '
              'before the end, the residual heat is enough.',
        )),
    EcoTip('fridge', TipCategory.cooling,
        Bi('Réfrigérateur bien réglé', 'Well-set fridge'),
        Bi(
          'Réglez-le à +4 °C, éloignez-le des sources de chaleur, dégivrez au-delà '
              'de 3 mm de givre et vérifiez le joint de porte.',
          'Set it to +4 °C, keep it away from heat sources, defrost beyond 3 mm '
              'of ice and check the door seal.',
        )),
    EcoTip('fan', TipCategory.cooling,
        Bi('Ventilateur plutôt que climatiseur', 'Fan rather than air conditioner'),
        Bi(
          'Un ventilateur consomme 50 W, un climatiseur 1 000 W ou plus. Si vous '
              'climatisez, visez 26 °C et fermez portes et fenêtres.',
          'A fan uses 50 W, an air conditioner 1,000 W or more. If you use AC, '
              'aim for 26 °C and close doors and windows.',
        )),
    EcoTip('water', TipCategory.habits,
        Bi('Chauffe-eau programmé', 'Scheduled water heater'),
        Bi(
          'Coupez le chauffe-eau la nuit et en votre absence — le kit EnMKit peut '
              'le faire par SMS.',
          'Switch the water heater off at night and when away — the EnMKit kit '
              'can do it by SMS.',
        )),
    EcoTip('watch', TipCategory.habits,
        Bi('Suivez votre consommation', 'Track your consumption'),
        Bi(
          'Consultez l\'onglet « Analyse IA » chaque semaine : ce qui se mesure '
              's\'améliore.',
          'Check the "AI analysis" tab every week: what gets measured gets '
              'improved.',
        )),
    EcoTip('tranche', TipCategory.cost,
        Bi('Restez dans la tranche sociale', 'Stay in the social block'),
        Bi(
          'Les premiers 110 kWh du mois sont les moins chers (≈ 50 FCFA/kWh) ; '
              'au-delà le prix du kWh augmente. Chaque kWh évité en fin de mois '
              'vaut plus cher.',
          'The first 110 kWh of the month are the cheapest (≈ 50 FCFA/kWh); '
              'beyond that the price per kWh rises. Every kWh saved at the end '
              'of the month is worth more.',
        )),
    EcoTip('prepaid', TipCategory.cost,
        Bi('Compteur prépayé : anticipez', 'Prepaid meter: plan ahead'),
        Bi(
          'Avec un compteur prépayé, la prévision du mois de l\'application aide à '
              'acheter le bon montant de crédit et à éviter la coupure.',
          'With a prepaid meter, the app\'s monthly forecast helps you buy the '
              'right amount of credit and avoid being cut off.',
        )),
  ];

  // ===========================================================================
  // GLOSSAIRE
  // ===========================================================================
  static const List<GlossaryEntry> glossary = [
    GlossaryEntry(
        Bi('Énergie (kWh)', 'Energy (kWh)'),
        Bi(
          'Quantité d\'électricité consommée. 1 kWh = 1 000 W pendant 1 heure. '
              'C\'est l\'unité facturée par ENEO.',
          'Amount of electricity used. 1 kWh = 1,000 W for 1 hour. It is the '
              'unit billed by ENEO.',
        )),
    GlossaryEntry(
        Bi('Puissance (W, kW)', 'Power (W, kW)'),
        Bi(
          'Débit d\'énergie à un instant donné. 1 kW = 1 000 W. Inscrite sur la '
              'plaque signalétique des appareils.',
          'Rate of energy use at a given moment. 1 kW = 1,000 W. Printed on the '
              'appliance rating plate.',
        )),
    GlossaryEntry(
        Bi('Tension (V)', 'Voltage (V)'),
        Bi(
          '« Pression » électrique du réseau : 220 V – 50 Hz au Cameroun. Une '
              'baisse de tension peut endommager les moteurs et compresseurs.',
          'Electrical "pressure" of the grid: 220 V – 50 Hz in Cameroon. A '
              'voltage drop can damage motors and compressors.',
        )),
    GlossaryEntry(
        Bi('Courant (A)', 'Current (A)'),
        Bi('Intensité qui circule dans un câble : I = P / U.',
            'Intensity flowing in a cable: I = P / U.')),
    GlossaryEntry(
        Bi('Veille', 'Standby'),
        Bi(
          'Consommation d\'un appareil éteint mais resté branché (voyant, '
              'horloge, transformateur).',
          'Consumption of an appliance switched off but still plugged in '
              '(indicator light, clock, power adapter).',
        )),
    GlossaryEntry(
        Bi('Charge de base', 'Base load'),
        Bi(
          'Consommation permanente mesurée la nuit (00–05 h) : réfrigérateur, '
              'veilles, éclairage de sécurité.',
          'Permanent consumption measured at night (00–05 h): fridge, standby, '
              'security lighting.',
        )),
    GlossaryEntry(
        Bi('Pointe', 'Peak'),
        Bi(
          'Période de forte demande sur le réseau, en général 18 h – 23 h. '
              'Consommer hors pointe soulage le réseau ENEO.',
          'Period of high demand on the grid, usually 18:00–23:00. Using '
              'energy off-peak relieves the ENEO grid.',
        )),
    GlossaryEntry(
        Bi('Constante d\'impulsions (imp/kWh)', 'Pulse constant (imp/kWh)'),
        Bi(
          'Nombre de clignotements du compteur pour 1 kWh. À 1 000 imp/kWh, une '
              'impulsion = 1 Wh. Le kit compte ces impulsions (réglage « ip »).',
          'Number of meter flashes per kWh. At 1,000 imp/kWh, one pulse = '
              '1 Wh. The kit counts these pulses ("ip" setting).',
        )),
    GlossaryEntry(
        Bi('Index', 'Meter index'),
        Bi(
          'Total cumulé affiché par le compteur depuis sa pose. La conso d\'une '
              'période = index de fin − index de début.',
          'Cumulative total shown by the meter since installation. Consumption '
              'over a period = end index − start index.',
        )),
    GlossaryEntry(
        Bi('Disjoncteur', 'Circuit breaker'),
        Bi(
          'Appareil de protection qui coupe automatiquement le circuit en cas de '
              'surcharge ou de court-circuit. Son calibre (10 A, 16 A…) est adapté '
              'à la section du câble.',
          'Protective device that automatically cuts the circuit on overload '
              'or short circuit. Its rating (10 A, 16 A…) matches the cable size.',
        )),
    GlossaryEntry(
        Bi('Délestage', 'Load shedding'),
        Bi(
          'Coupure programmée d\'une zone par le distributeur quand la demande '
              'dépasse la production disponible.',
          'Planned outage of an area by the utility when demand exceeds '
              'available generation.',
        )),
    GlossaryEntry(
        Bi('Tranche tarifaire', 'Tariff block'),
        Bi(
          'Le prix du kWh dépend du volume mensuel : les premiers kWh coûtent '
              'moins cher que les suivants (barème par tranches).',
          'The kWh price depends on the monthly volume: the first kWh cost less '
              'than the following ones (block tariff).',
        )),
    GlossaryEntry(
        Bi('Trame horaire', 'Hourly frame'),
        Bi(
          'Ligne « JJ/MM/AA;HH;KWH » envoyée par SMS : énergie consommée pendant '
              'l\'heure qui commence à HH.',
          '"DD/MM/YY;HH;KWH" line sent by SMS: energy used during the hour '
              'starting at HH.',
        )),
    GlossaryEntry(
        Bi('IoT (Internet des objets)', 'IoT (Internet of Things)'),
        Bi(
          'Objets équipés de capteurs et d\'une liaison de communication (ici '
              'GSM) qui transmettent des données sans intervention humaine.',
          'Objects with sensors and a communication link (here GSM) that send '
              'data without human intervention.',
        )),
  ];
}
