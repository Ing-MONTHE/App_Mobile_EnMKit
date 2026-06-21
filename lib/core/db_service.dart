import 'package:enmkit/core/constants/defaults.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBService {
  static final DBService _instance = DBService._internal();
  static Database? _database;

  factory DBService() {
    return _instance;
  }

  DBService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, "kit_control.db");

    return await openDatabase(
      path,
      version: 12,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // TABLE User
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        phoneNumber TEXT NOT NULL,
        password TEXT NOT NULL,
        isAdmin INTEGER NOT NULL DEFAULT 0,
        hasConnected INTEGER NOT NULL DEFAULT 0
      );
    ''');

    // TABLE AllowedNumbers (relation kit -> numéros autorisés)
    await db.execute('''
      CREATE TABLE allowed_numbers  (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        phoneNumber TEXT NOT NULL,
        kitNumber TEXT
      );
    ''');


    // TABLE Consumption (historique des consommations)
    await db.execute('''
      CREATE TABLE consumptions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kWh REAL NOT NULL,
        timestamp TEXT NOT NULL,
        kitNumber TEXT
      );
    ''');

    // TABLE Configuration (langue, thème…)
    await db.execute('''
      CREATE TABLE configurations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        language TEXT NOT NULL,
        themeMode TEXT NOT NULL,
        notificationsEnabled INTEGER NOT NULL DEFAULT 1
      );
    ''');

    // TABLE Sécurité : code d'accès (PIN) haché de l'application
    await db.execute('''
      CREATE TABLE app_security (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        pinHash TEXT NOT NULL,
        salt TEXT NOT NULL,
        q1 TEXT,
        a1Hash TEXT,
        q2 TEXT,
        a2Hash TEXT
      );
    ''');

    // TABLE Réglages de l'app (thème, langue, couleur d'accent)
    await db.execute('''
      CREATE TABLE app_settings (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        themeMode TEXT NOT NULL DEFAULT 'system',
        locale TEXT NOT NULL DEFAULT 'fr',
        accent TEXT NOT NULL DEFAULT 'indigo',
        onboardingSeen INTEGER NOT NULL DEFAULT 0,
        securityCodeEnabled INTEGER NOT NULL DEFAULT 0,
        securityPromptSeen INTEGER NOT NULL DEFAULT 0,
        biometricEnabled INTEGER NOT NULL DEFAULT 0
      );
    ''');

     await db.execute('''
    CREATE TABLE kits(
      kitNumber TEXT PRIMARY KEY,
      name TEXT,
      initialConsumption REAL,
      pulseCount INTEGER
    )
  ''');

  await db.execute('''
    CREATE TABLE relays(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT,
      isActive INTEGER,
      amperage INTEGER,
      ackReceived INTEGER NOT NULL DEFAULT 0,
      kitNumber TEXT
    )
  ''');

  // TABLE relay_acks : historique horodaté des accusés de réception du kit
  // (un enregistrement à chaque écho « rXon » / « rXoff » confirmé).
  await db.execute('''
    CREATE TABLE relay_acks(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      relayId INTEGER NOT NULL,
      kitNumber TEXT,
      isActive INTEGER NOT NULL,
      at INTEGER NOT NULL,
      raw TEXT
    )
  ''');

  // insertion admin par défaut
  await db.insert('users', {
    'phoneNumber': DefaultData.adminPhoneNumber,
    'password': DefaultData.adminPassword,
    'isAdmin': 1,
    'hasConnected': 0,
  }); 

   // insertion des 3 relais par défaut
  for (var relay in DefaultData.defaultRelays) {
    await db.insert('relays', {
      'name': relay['name'],
      'isActive': relay['isActive'],
      'amperage': relay['amperage'],
    });
  } 
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE relays ADD COLUMN ackReceived INTEGER NOT NULL DEFAULT 0');
    }
    if (oldVersion < 3) {
      // Multi-kits : nom de kit + rattachement des entités à un kit (kitNumber).
      await db.execute('ALTER TABLE kits ADD COLUMN name TEXT');
      await db.execute('ALTER TABLE relays ADD COLUMN kitNumber TEXT');
      await db.execute('ALTER TABLE consumptions ADD COLUMN kitNumber TEXT');
      await db.execute('ALTER TABLE allowed_numbers ADD COLUMN kitNumber TEXT');
    }
    if (oldVersion < 4) {
      // Code d'accès (PIN) remplaçant l'écran de connexion.
      await db.execute('''
        CREATE TABLE app_security (
          id INTEGER PRIMARY KEY CHECK (id = 1),
          pinHash TEXT NOT NULL,
          salt TEXT NOT NULL
        );
      ''');
    }
    if (oldVersion < 5) {
      // Réglages de l'app (thème, langue, accent).
      await db.execute('''
        CREATE TABLE app_settings (
          id INTEGER PRIMARY KEY CHECK (id = 1),
          themeMode TEXT NOT NULL DEFAULT 'system',
          locale TEXT NOT NULL DEFAULT 'fr',
          accent TEXT NOT NULL DEFAULT 'indigo'
        );
      ''');
    }
    if (oldVersion < 6) {
      // Onboarding : mémorise si le tutoriel d'accueil a déjà été vu.
      await db.execute(
          "ALTER TABLE app_settings ADD COLUMN onboardingSeen INTEGER NOT NULL DEFAULT 0");
    }
    if (oldVersion < 7) {
      // Code de sécurité devenu optionnel (réglable dans les paramètres).
      await db.execute(
          "ALTER TABLE app_settings ADD COLUMN securityCodeEnabled INTEGER NOT NULL DEFAULT 0");
      // Les installations déjà protégées par un code le restent (migration douce).
      final sec = await db.query('app_security', limit: 1);
      if (sec.isNotEmpty) {
        final existing = await db.query('app_settings', where: 'id = 1', limit: 1);
        if (existing.isEmpty) {
          await db.insert('app_settings', {'id': 1, 'securityCodeEnabled': 1});
        } else {
          await db.update('app_settings', {'securityCodeEnabled': 1}, where: 'id = 1');
        }
      }
    }
    if (oldVersion < 8) {
      // « Relais » renommé « Ligne » : on aligne les noms déjà stockés
      // (ex. « Relais 2 » -> « Ligne 2 »). Seul le préfixe par défaut est
      // remplacé ; les noms personnalisés par l'utilisateur restent intacts.
      await db.execute(
          "UPDATE relays SET name = 'Ligne ' || substr(name, 8) "
          "WHERE name LIKE 'Relais %'");
    }
    if (oldVersion < 9) {
      // Proposition de code skippable au 1er lancement : nouveau drapeau.
      await db.execute(
          "ALTER TABLE app_settings ADD COLUMN securityPromptSeen INTEGER NOT NULL DEFAULT 0");
      // Les installations existantes ont déjà passé le 1er lancement : on évite
      // de leur présenter la proposition (marquée comme déjà vue).
      await db.execute("UPDATE app_settings SET securityPromptSeen = 1");
    }
    if (oldVersion < 10) {
      // Récupération du code par questions mémo + déverrouillage par empreinte.
      await db.execute('ALTER TABLE app_security ADD COLUMN q1 TEXT');
      await db.execute('ALTER TABLE app_security ADD COLUMN a1Hash TEXT');
      await db.execute('ALTER TABLE app_security ADD COLUMN q2 TEXT');
      await db.execute('ALTER TABLE app_security ADD COLUMN a2Hash TEXT');
      await db.execute(
          "ALTER TABLE app_settings ADD COLUMN biometricEnabled INTEGER NOT NULL DEFAULT 0");
    }
    if (oldVersion < 11) {
      // Historique horodaté des accusés de réception, par ligne.
      await db.execute('''
        CREATE TABLE relay_acks(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          relayId INTEGER NOT NULL,
          kitNumber TEXT,
          isActive INTEGER NOT NULL,
          at INTEGER NOT NULL
        )
      ''');
    }
    if (oldVersion < 12) {
      // L'accusé brut (texte du SMS du kit) est joint à chaque entrée d'historique.
      await db.execute('ALTER TABLE relay_acks ADD COLUMN raw TEXT');
    }
  }
}
