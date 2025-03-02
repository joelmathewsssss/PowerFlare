import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

import 'models/user.dart';
import 'screens/home_screen.dart';
import 'screens/landing_screen.dart';

/// Main entry point for the PowerFlare application
void main() async {
  // Initialize logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    print("Environment variables loaded successfully");
  } catch (e) {
    print("Error loading environment variables: $e");
    // Create a default .env file with a placeholder API key
    await _createDefaultEnvFile();
  }

  // Run the app
  runApp(const PowerFlareApp());
}

/// Create a default .env file if one doesn't exist
Future<void> _createDefaultEnvFile() async {
  const defaultApiKey = "YOUR_OPENWEATHER_API_KEY";

  try {
    // Create a default .env file with instructions
    const envContent = '''
# PowerFlare Environment Variables
# Replace the placeholder below with your actual OpenWeather API key
# Get your API key from: https://openweathermap.org/api

OPENWEATHER_API_KEY=$defaultApiKey
''';

    // Write to the .env file
    final file = await File('.env').writeAsString(envContent);
    print("Created default .env file at ${file.path}");
    print(
        "Please replace the placeholder API key in the .env file with your actual OpenWeather API key");
  } catch (e) {
    print("Error creating default .env file: $e");
  }
}

/// Root widget for the PowerFlare application
class PowerFlareApp extends StatefulWidget {
  const PowerFlareApp({Key? key}) : super(key: key);

  @override
  State<PowerFlareApp> createState() => _PowerFlareAppState();
}

class _PowerFlareAppState extends State<PowerFlareApp> {
  // User state
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Load user data when app starts
    _loadUserData();
  }

  /// Load user data from SharedPreferences
  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user');

      setState(() {
        if (userData != null) {
          _user = User.fromJson(jsonDecode(userData));
        }
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Save user data to SharedPreferences
  Future<void> _saveUserData(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(user.toJson()));

      setState(() {
        _user = user;
      });
    } catch (e) {
      print('Error saving user data: $e');
    }
  }

  /// Handle user login
  void _handleLogin(User user) {
    _saveUserData(user);
  }

  /// Handle user logout
  void _handleLogout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user');

      setState(() {
        _user = null;
      });
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PowerFlare',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user != null
              ? HomeScreen(
                  user: _user!,
                  onLogout: _handleLogout,
                )
              : LandingScreen(
                  onLogin: _handleLogin,
                ),
    );
  }
}
