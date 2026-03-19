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
      version: 2,
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
        phoneNumber TEXT NOT NULL
      );
    ''');


    // TABLE Consumption (historique des consommations)
    await db.execute('''
      CREATE TABLE consumptions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kWh REAL NOT NULL,
        timestamp TEXT NOT NULL
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

     await db.execute('''
    CREATE TABLE kits(
      kitNumber TEXT PRIMARY KEY,
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
      ackReceived INTEGER NOT NULL DEFAULT 0
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
  }
}
