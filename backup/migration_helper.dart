import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/power_source.dart';
import 'database_helper.dart';
import 'package:logging/logging.dart';

class MigrationHelper {
  static final MigrationHelper _instance = MigrationHelper._internal();
  static MigrationHelper get instance => _instance;
  final _logger = Logger('MigrationHelper');

  MigrationHelper._internal();

  /// Checks if migration is needed
  Future<bool> isMigrationNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final migrationCompleted =
        prefs.getBool('sqlite_migration_completed') ?? false;
    return !migrationCompleted;
  }

  /// Migrates data from SharedPreferences to SQLite
  Future<bool> migrateToSQLite() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load registered users
      final usersJson = prefs.getString('registered_users');
      List<User> users = [];
      if (usersJson != null) {
        _logger.info('Found registered users in SharedPreferences');
        final List<dynamic> usersList = json.decode(usersJson);
        users = usersList.map((userData) => User.fromJson(userData)).toList();
        _logger.info('Loaded ${users.length} users from SharedPreferences');
      }

      // Load power sources
      final sourcesJson = prefs.getString('power_sources');
      List<PowerSource> powerSources = [];
      if (sourcesJson != null) {
        _logger.info('Found power sources in SharedPreferences');
        final List<dynamic> sourcesList = json.decode(sourcesJson);
        powerSources = sourcesList
            .map((sourceData) => PowerSource.fromJson(sourceData))
            .toList();
        _logger.info(
            'Loaded ${powerSources.length} power sources from SharedPreferences');
      }

      // Get currently logged in user
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      String? loggedInUsername;
      if (isLoggedIn) {
        final userJson = prefs.getString('user');
        if (userJson != null) {
          final userData = json.decode(userJson);
          loggedInUsername = userData['username'];
          _logger.info('Found logged in user: $loggedInUsername');
        }
      }

      // Migrate data to SQLite
      _logger.info('Starting migration to SQLite');
      await DatabaseHelper.instance
          .migrateFromSharedPreferences(users, powerSources, loggedInUsername);

      // Mark migration as completed
      await prefs.setBool('sqlite_migration_completed', true);
      _logger.info('Migration completed successfully');

      return true;
    } catch (e) {
      _logger.severe('Migration error: $e');
      return false;
    }
  }

  /// Clears SharedPreferences data after successful migration
  Future<void> clearSharedPreferencesData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Keep the migration flag
      final migrationCompleted =
          prefs.getBool('sqlite_migration_completed') ?? false;

      // Clear all data
      await prefs.clear();

      // Restore the migration flag
      await prefs.setBool('sqlite_migration_completed', migrationCompleted);
      _logger.info('SharedPreferences data cleared (except migration flag)');
    } catch (e) {
      _logger.severe('Error clearing SharedPreferences data: $e');
    }
  }
}
