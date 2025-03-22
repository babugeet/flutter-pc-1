// ignore_for_file: prefer_const_constructors

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'global.dart';
import 'firestore_service.dart';


class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _bmiController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

final FirestoreService _firestoreService = FirestoreService();





  String? _errorMessage;
  bool _signupSuccessful = false;

  @override
  void initState() {
    super.initState();
    fetchIam();
    _heightController.addListener(_calculateBMI);
    _weightController.addListener(_calculateBMI);
  }
  void fetchIam() async {
    String? value = await _firestoreService.fetchAndSetIam();
    setState(() {
      ec2host = value;
    });
  }

  void _calculateBMI() {
    double height = double.tryParse(_heightController.text) ?? 0;
    double weight = double.tryParse(_weightController.text) ?? 0;

    if (height > 0 && weight > 0) {
      double bmi = weight / ((height / 100) * (height / 100));
      _bmiController.text = bmi.toStringAsFixed(2);
    } else {
      _bmiController.text = '';
    }
  }

  Future<void> _signup() async {
    final firstName = _firstNameController.text;
    final lastName = _lastNameController.text;
    final userName = _userNameController.text;
    final age = _ageController.text;
    final gender = _genderController.text;
    final height = _heightController.text;
    final weight = _weightController.text;
    final bmi = _bmiController.text;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password != confirmPassword) {
      setState(() {
        _errorMessage = "Passwords do not match!";
      });
      return;
    }

    if (int.tryParse(age) == null || int.tryParse(height) == null || int.tryParse(weight) == null) {
      setState(() {
        _errorMessage = "Age, height, and weight must be valid integers!";
      });
      return;
    }

    final Map<String, dynamic> user = {
      'username': userName,
      'firstname': firstName,
      'lastname': lastName,
      'password': password,
      'gender': gender,
      'age': int.parse(age),
      'height': int.parse(height),
      'weight': int.parse(weight),
      'bmi': double.parse(bmi).round(),
    };

    try {
      final response = await http.post(
        Uri.parse('$ec2host:8080/signup'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(user),
      );

      if (response.statusCode == 200) {
        setState(() {
          _errorMessage = "Signup successful! Please log in now.";
          _signupSuccessful = true; // Show only "Click here to login" on success
        });
      } else {
        setState(() {
          _errorMessage = "Signup failed. Please try again.";
          _signupSuccessful = false; // Reset to show "Already have an account? Login"
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = "An error occurred: $error";
        _signupSuccessful = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/signup1.jpeg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.6), Colors.black.withOpacity(0.2)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.directions_run,
                    color: Colors.white,
                    size: 100,
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Create Your Account",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 30),
                  _buildTextField(_firstNameController, 'First Name', Icons.person),
                  SizedBox(height: 20),
                  _buildTextField(_lastNameController, 'Last Name', Icons.person_outline),
                  SizedBox(height: 20),
                  _buildTextField(_userNameController, 'User Name', Icons.person_outline),
                  SizedBox(height: 20),
                  _buildTextField(_ageController, 'Age', Icons.calendar_today, isNumeric: true),
                  SizedBox(height: 20),
                  _buildTextField(_genderController, 'Gender', Icons.transgender),
                  SizedBox(height: 20),
                  _buildTextField(_heightController, 'Height (cm)', Icons.height, isNumeric: true),
                  SizedBox(height: 20),
                  _buildTextField(_weightController, 'Weight (kg)', Icons.line_weight, isNumeric: true),
                  SizedBox(height: 20),
                  _buildTextField(_bmiController, 'BMI', Icons.fitness_center, readOnly: true),
                  SizedBox(height: 20),
                  _buildTextField(_passwordController, 'Password', Icons.lock, obscureText: true),
                  SizedBox(height: 20),
                  _buildTextField(_confirmPasswordController, 'Confirm Password', Icons.lock_outline, obscureText: true),
                  SizedBox(height: 20),
                  if (_errorMessage != null)
                    Column(
                      children: [
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: _errorMessage!.contains("successful")
                                ? Colors.green
                                : Colors.red,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 10),
                        if (_errorMessage!.contains("successful"))
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/login');
                            },
                            child: Text(
                              'Click here to login',
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 16,
                                // decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          // GestureDetector(
                          //   onTap: () {
                          //     Navigator.pushNamed(context, '/login');
                          //   },
                          //   child: Text(
                          //     'Click here to login',
                          //     style: TextStyle(
                          //       color: Colors.blueAccent,
                          //       fontSize: 16,
                          //       decoration: TextDecoration.underline,
                          //     ),
                          //   ),
                          // ),
                      ],
                    ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: _signup,
                    child: Text(
                      'Sign Up',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                  SizedBox(height: 20),
                  if (!_signupSuccessful)
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      child: Text(
                        'Already have an account? Login',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hintText, IconData icon,
      {bool readOnly = false, bool obscureText = false, bool isNumeric = false}) {
    return TextField(
      controller: controller,
      style: TextStyle(color: Colors.white),
      readOnly: readOnly,
      obscureText: obscureText,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white24,
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _bmiController.dispose();
    super.dispose();
  }
}
