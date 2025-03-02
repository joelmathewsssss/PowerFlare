import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logging/logging.dart';
import '../models/user.dart';
import '../models/power_source.dart';
import '../models/chat_message.dart';
import 'database_initializer.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static DatabaseHelper get instance => _instance;

  static Database? _database;
  final _logger = Logger('DatabaseHelper');

  // Database version - increment this when schema changes
  static const int _databaseVersion = 1;
  static const String _databaseName = 'powerflare.db';

  // Table names
  static const String tableUsers = 'users';
  static const String tablePowerSources = 'power_sources';
  static const String tableChatMessages = 'chat_messages';

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;

    // Ensure database is initialized for the current platform
    DatabaseInitializer.initialize();

    try {
      _database = await _initDatabase();
      return _database!;
    } catch (e) {
      _logger.severe('Error initializing database: $e');
      rethrow;
    }
  }

  Future<Database> _initDatabase() async {
    try {
      final String path = join(await getDatabasesPath(), _databaseName);
      _logger.info('Opening database at path: $path');

      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onOpen: (db) {
          _logger.info('Database opened successfully');
        },
      );
    } catch (e) {
      _logger.severe('Error in _initDatabase: $e');
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create users table
    await db.execute('''
      CREATE TABLE $tableUsers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        email TEXT,
        password TEXT NOT NULL,
        isLoggedIn INTEGER DEFAULT 0
      )
    ''');

    // Create power sources table
    await db.execute('''
      CREATE TABLE $tablePowerSources (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        powerType TEXT NOT NULL,
        isFree INTEGER NOT NULL
      )
    ''');

    // Create chat messages table
    await db.execute('''
      CREATE TABLE $tableChatMessages (
        id TEXT PRIMARY KEY,
        powerSourceId TEXT NOT NULL,
        message TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        senderName TEXT NOT NULL,
        FOREIGN KEY (powerSourceId) REFERENCES $tablePowerSources (id) ON DELETE CASCADE
      )
    ''');
  }

  // User operations
  Future<int> insertUser(User user) async {
    final Database db = await database;
    return await db.insert(
      tableUsers,
      user.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<User>> getUsers() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableUsers);
    return List.generate(maps.length, (i) => User.fromJson(maps[i]));
  }

  Future<User?> getUserByUsername(String username) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableUsers,
      where: 'username = ?',
      whereArgs: [username],
    );
    if (maps.isEmpty) return null;
    return User.fromJson(maps.first);
  }

  Future<User?> getLoggedInUser() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableUsers,
      where: 'isLoggedIn = ?',
      whereArgs: [1],
    );
    if (maps.isEmpty) return null;
    return User.fromJson(maps.first);
  }

  Future<int> updateUserLoginStatus(String username, bool isLoggedIn) async {
    final Database db = await database;
    return await db.update(
      tableUsers,
      {'isLoggedIn': isLoggedIn ? 1 : 0},
      where: 'username = ?',
      whereArgs: [username],
    );
  }

  Future<int> logoutAllUsers() async {
    final Database db = await database;
    return await db.update(
      tableUsers,
      {'isLoggedIn': 0},
    );
  }

  // Power source operations
  Future<int> insertPowerSource(PowerSource source) async {
    final Database db = await database;

    // Start a transaction to insert power source and its chat messages
    return await db.transaction((txn) async {
      // Insert power source
      final sourceId = await txn.insert(
        tablePowerSources,
        {
          'id': source.id,
          'name': source.name,
          'description': source.description,
          'latitude': source.position.latitude,
          'longitude': source.position.longitude,
          'powerType': source.powerType,
          'isFree': source.isFree ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Insert chat messages
      for (var message in source.chatMessages) {
        await txn.insert(
          tableChatMessages,
          {
            'id': message.id,
            'powerSourceId': source.id,
            'message': message.message,
            'timestamp': message.timestamp.toIso8601String(),
            'senderName': message.senderName,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      return sourceId;
    });
  }

  Future<List<PowerSource>> getPowerSources() async {
    final Database db = await database;
    final List<Map<String, dynamic>> sourceMaps =
        await db.query(tablePowerSources);

    // Create a list to hold the power sources
    List<PowerSource> sources = [];

    // For each power source, get its chat messages
    for (var sourceMap in sourceMaps) {
      final String sourceId = sourceMap['id'];

      // Get chat messages for this power source
      final List<Map<String, dynamic>> messageMaps = await db.query(
        tableChatMessages,
        where: 'powerSourceId = ?',
        whereArgs: [sourceId],
      );

      // Convert message maps to ChatMessage objects
      final List<ChatMessage> messages = messageMaps
          .map((msgMap) => ChatMessage(
                id: msgMap['id'],
                message: msgMap['message'],
                timestamp: DateTime.parse(msgMap['timestamp']),
                senderName: msgMap['senderName'],
              ))
          .toList();

      // Create the PowerSource with its messages
      sources.add(PowerSource(
        id: sourceMap['id'],
        name: sourceMap['name'],
        description: sourceMap['description'],
        position: LatLng(
          sourceMap['latitude'],
          sourceMap['longitude'],
        ),
        powerType: sourceMap['powerType'],
        isFree: sourceMap['isFree'] == 1,
        chatMessages: messages,
      ));
    }

    return sources;
  }

  Future<int> deletePowerSource(String id) async {
    final Database db = await database;
    // The chat messages will be deleted automatically due to the CASCADE constraint
    return await db.delete(
      tablePowerSources,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Chat message operations
  Future<int> insertChatMessage(
      String powerSourceId, ChatMessage message) async {
    final Database db = await database;
    return await db.insert(
      tableChatMessages,
      {
        'id': message.id,
        'powerSourceId': powerSourceId,
        'message': message.message,
        'timestamp': message.timestamp.toIso8601String(),
        'senderName': message.senderName,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Migration from SharedPreferences
  Future<void> migrateFromSharedPreferences(List<User> users,
      List<PowerSource> powerSources, String? loggedInUsername) async {
    final Database db = await database;

    // Start a transaction for atomicity
    await db.transaction((txn) async {
      // Migrate users
      for (var user in users) {
        await txn.insert(
          tableUsers,
          {
            'username': user.username,
            'email': user.email,
            'password': user.password,
            'isLoggedIn': user.username == loggedInUsername ? 1 : 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // Migrate power sources and their chat messages
      for (var source in powerSources) {
        await txn.insert(
          tablePowerSources,
          {
            'id': source.id,
            'name': source.name,
            'description': source.description,
            'latitude': source.position.latitude,
            'longitude': source.position.longitude,
            'powerType': source.powerType,
            'isFree': source.isFree ? 1 : 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Insert chat messages for this power source
        for (var message in source.chatMessages) {
          await txn.insert(
            tableChatMessages,
            {
              'id': message.id,
              'powerSourceId': source.id,
              'message': message.message,
              'timestamp': message.timestamp.toIso8601String(),
              'senderName': message.senderName,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });
  }
}
