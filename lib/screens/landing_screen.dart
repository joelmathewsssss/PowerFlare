import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'package:logging/logging.dart';

/// Landing screen for user login and registration
class LandingScreen extends StatefulWidget {
  final Function(User) onLogin;

  const LandingScreen({
    Key? key,
    required this.onLogin,
  }) : super(key: key);

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  // Form controllers
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();

  // Form state
  bool _isRegistering = false;
  String? _errorMessage;
  bool _isLoading = false;
  List<User> _registeredUsers = [];
  bool _showPassword = false;
  final _logger = Logger('LandingScreen');

  @override
  void initState() {
    super.initState();
    _loadRegisteredUsers();
  }

  Future<void> _loadRegisteredUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getStringList('registeredUsers') ?? [];

      setState(() {
        _registeredUsers = usersJson
            .map((userStr) => User.fromJson(json.decode(userStr)))
            .toList();
      });
    } catch (e) {
      _logger.severe('Error loading registered users: $e');
    }
  }

  Future<void> _saveRegisteredUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson =
          _registeredUsers.map((user) => json.encode(user.toJson())).toList();
      await prefs.setStringList('registeredUsers', usersJson);
    } catch (e) {
      _logger.severe('Error saving registered users: $e');
    }
  }

  @override
  void dispose() {
    // Clean up controllers
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  /// Handle login button press
  void _handleLoginButton() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both username and password';
      });
      return;
    }

    try {
      // Get registered users from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getStringList('registeredUsers') ?? [];

      // Find user with matching credentials
      final users = usersJson
          .map((userStr) => User.fromJson(jsonDecode(userStr)))
          .toList();

      final user = users.firstWhere(
        (user) => user.username == username && user.password == password,
        orElse: () => User(
          id: '',
          username: '',
          password: '',
          email: '',
          createdAt: DateTime.now(),
        ),
      );

      if (user.id.isEmpty) {
        // User not found or password incorrect
        setState(() {
          _errorMessage = 'Invalid username or password';
        });
      } else {
        // Login successful
        widget.onLogin(user);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error during login: $e';
      });
    }
  }

  /// Handle register button press
  void _handleRegisterButton() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final email = _emailController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both username and password';
      });
      return;
    }

    try {
      // Get registered users from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getStringList('registeredUsers') ?? [];

      // Parse existing users
      final users = usersJson
          .map((userStr) => User.fromJson(jsonDecode(userStr)))
          .toList();

      // Check if username already exists
      final userExists = users.any((user) => user.username == username);

      if (userExists) {
        setState(() {
          _errorMessage = 'Username already exists';
        });
        return;
      }

      // Create new user
      final newUser = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        username: username,
        password: password,
        email: email,
        createdAt: DateTime.now(),
      );

      // Add to registered users
      users.add(newUser);

      // Save updated user list
      await prefs.setStringList(
        'registeredUsers',
        users.map((user) => jsonEncode(user.toJson())).toList(),
      );

      // Login with new user
      widget.onLogin(newUser);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error during registration: $e';
      });
    }
  }

  /// Toggle between login and registration forms
  void _toggleForm() {
    setState(() {
      _isRegistering = !_isRegistering;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.orange.shade800, Colors.orange.shade200],
          ),
        ),
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(20.0),
            elevation: 8.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: Container(
              padding: const EdgeInsets.all(20.0),
              width: 400.0,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10.0),
                    Image.asset(
                      'assets/images/logo.png',
                      height: 100.0,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.power,
                          size: 80.0,
                          color: Colors.orange,
                        );
                      },
                    ),
                    const SizedBox(height: 20.0),
                    Text(
                      'PowerFlare',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.orange.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 10.0),
                    Text(
                      'Find and share power sources around you',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30.0),
                    Text(
                      _isRegistering ? 'Create Account' : 'Login',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24.0),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15.0),
                    if (_isRegistering) ...[
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 15.0),
                    ],
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _showPassword = !_showPassword;
                            });
                          },
                          tooltip:
                              _showPassword ? 'Hide password' : 'Show password',
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      obscureText: !_showPassword,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 10.0),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 20.0),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : (_isRegistering
                                ? _handleRegisterButton
                                : _handleLoginButton),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20.0,
                                width: 20.0,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(_isRegistering ? 'Register' : 'Login'),
                      ),
                    ),
                    const SizedBox(height: 15.0),
                    TextButton(
                      onPressed: _isLoading ? null : _toggleForm,
                      child: Text(_isRegistering
                          ? 'Already have an account? Login'
                          : 'Need an account? Register'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
