// import 'dart:html';

// class AuthService {
//   Future<bool> isUserSignedIn() async {
//     // Check if the session token exists in Local Storage
//     String? token = window.localStorage['flutter.token1']; // Retrieve the token from Local Storage
//     return token != null; // Return true if the token exists, false otherwise

//     // #TODO, to check time and mark expiry
//   }

//   Future<void> logout() async {
//     // Clear the token from Local Storage on logout
//     window.localStorage.remove('flutter.token1'); // Clear stored session token
//   }

//   Future<bool> isKeyExists(String key) async {
//     // Check if a specific key exists in Local Storage
//     String? value = window.localStorage[key];
//     return value != null; // Return true if key exists, false otherwise
//   }
// }


import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class AuthService {
  final String _tokenKey = 'flutter.token1';

  Future<bool> isUserSignedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString(_tokenKey);
    return token != null;
  }

  Future<void> logout( context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
        if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/splash', (route) => false);
    }
    // Navigator.pushReplacementNamed(context, '/splash'); 
  }

  Future<bool> isKeyExists(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(key);
  }

  Future<void> saveToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
}
