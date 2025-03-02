import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:logging/logging.dart';

// Import the web-specific package
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Utility class to initialize the database based on the platform
class DatabaseInitializer {
  static final _logger = Logger('DatabaseInitializer');
  static bool _initialized = false;

  /// Initialize the database factory based on the platform
  static void initialize() {
    if (_initialized) {
      _logger.info('Database already initialized');
      return;
    }

    try {
      if (kIsWeb) {
        _logger.info('Initializing database for web platform');
        // Web platform - use the web-specific implementation
        databaseFactory = databaseFactoryFfiWeb;
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        _logger.info(
            'Initializing database for desktop platform: ${Platform.operatingSystem}');
        // Desktop platforms
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      } else {
        _logger.info(
            'Using default database factory for mobile platform: ${Platform.operatingSystem}');
        // Mobile platforms use the default databaseFactory
      }
      _initialized = true;
    } catch (e) {
      _logger.severe('Error initializing database: $e');
      rethrow;
    }
  }
}
