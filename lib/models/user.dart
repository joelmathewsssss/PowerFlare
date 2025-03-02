import 'package:flutter/material.dart';

/// User model representing a registered user in the app
class User {
  final String id;
  final String username;
  final String password;
  final String email;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.password,
    this.email = '',
    required this.createdAt,
  });

  /// Create a User from JSON data
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      password: json['password'] as String,
      email: json['email'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Convert User to JSON data
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
