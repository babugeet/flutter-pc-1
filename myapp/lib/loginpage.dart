import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dio/dio.dart';
import 'global.dart';
import 'authservice.dart';
import 'firestore_service.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:shared_preferences/shared_preferences.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final CookieJar cookieJar = PersistCookieJar(); // Create a persistent cookie jar

final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    fetchIam();
  }

  void fetchIam() async {
    String? value = await _firestoreService.fetchAndSetIam();
    setState(() {
      ec2host = value;
    });
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      // Show error message if username or password is empty
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter both username and password.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
  // var dio = Dio();
  // dio.options.baseUrl = 'http://localhost:8080';
//  var appDocDir = await getTemporaryDirectory();
  // var cookieJar = PersistCookieJar(storage: FileStorage(appDocDir.path));
    // dio.options.headers['Content-Type'] = 'application/json';
//  dio.interceptors.add(CookieManager(cookieJar));  

    try {
      final response = await http.post(
        Uri.parse('$ec2host:8080/login'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
        body: jsonEncode(<String, String>{
          'username': username,
          'password': password,
        }),
      );


    //       Response response = await dio.post(
    //   '/login',
    //   data: {
    //     'username': 'your_username',
    //     'password': 'your_password',
    //   },
    //   options: Options(
    //     followRedirects: false,
    //     validateStatus: (status) {
    //       return status! < 500; // Allow status code < 500
    //     },
    //         headers: {
    //     'Content-Type': 'application/json',
    //     'Accept': 'application/json',
    //   },
    //   ),
    // );
  //    var cookies = await cookieJar.loadForRequest(Uri.parse('http://localhost:8080/login'));
  // print(cookies); // This will show the Set-Cookie header
       // Print response details for debugging
    print('Response status: ${response.statusCode}');
    print('Response headers: ${response.headers}');
    // print('Response body: ${response.body}');
    print('test:${response.body}');
      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = jsonDecode(response.body);
        String token = responseData['token'];
        final AuthService _authService = AuthService();
        _authService.saveToken(responseData['token']);
        // String username1 = '$username'; 
        // Successful login
        // Save the cookies returned in the response
        //  String? setCookieHeader = response.headers['set-cookie'];

        // Define a manual cookie value if needed


        // String manualCookie = 'token1=${response.body},userna1me=$username';


        // Store the cookie in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        // var setCookieHeader;
        await prefs.setString('token1', token);
  await prefs.setString('userna1me', username);
        // await prefs.setString('token1', setCookieHeader ?? manualCookie);
        // print('Cookie stored: ${setCookieHeader ?? manualCookie}');

        // Navigate to the dashboard
        Navigator.pushReplacementNamed(context, '/dashboard');
        
      } else {
        // Show error if the login fails
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed. Please check your credentials.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Handle error during the request
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred. Please try again later.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // body: Container(
      //   decoration: BoxDecoration(
      //     gradient: LinearGradient(
      //       colors: [Colors.blueGrey, Colors.grey],
      //       begin: Alignment.topCenter,
      //       end: Alignment.bottomCenter,
      //     ),
      //   ),
      //   child: Center(
      //     child: Padding(
      //       padding: const EdgeInsets.all(16.0),
      //       child: Column(
      //         mainAxisAlignment: MainAxisAlignment.center,
      //         children: <Widget>[
      //           Icon(Icons.fitness_center, color: Colors.white, size: 100),
      //           SizedBox(height: 30),
      //           TextField(
      //             controller: _usernameController,
      //             style: TextStyle(color: Colors.white),
      //             decoration: InputDecoration(
      //               filled: true,
      //               fillColor: Colors.white24,
      //               hintText: 'Username',
      //               hintStyle: TextStyle(color: Colors.white70),
      //               prefixIcon: Icon(Icons.person, color: Colors.white70),
      //               border: OutlineInputBorder(
      //                 borderRadius: BorderRadius.circular(30),
      //                 borderSide: BorderSide.none,
      //               ),
      //             ),
      //           ),
      //           SizedBox(height: 20),
      //           TextField(
      //             controller: _passwordController,
      //             obscureText: true,
      //             style: TextStyle(color: Colors.white),
      //             decoration: InputDecoration(
      //               filled: true,
      //               fillColor: Colors.white24,
      //               hintText: 'Password',
      //               hintStyle: TextStyle(color: Colors.white70),
      //               prefixIcon: Icon(Icons.lock, color: Colors.white70),
      //               border: OutlineInputBorder(
      //                 borderRadius: BorderRadius.circular(30),
      //                 borderSide: BorderSide.none,
      //               ),
      //             ),
      //           ),
      //           SizedBox(height: 30),
      //           ElevatedButton(
      //             style: ElevatedButton.styleFrom(
      //               backgroundColor: Colors.white24,
      //               padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
      //               shape: RoundedRectangleBorder(
      //                 borderRadius: BorderRadius.circular(30),
      //               ),
      //             ),
      //             onPressed: _login,
      //             child: Text('Login', style: TextStyle(color: Colors.white, fontSize: 18)),
      //           ),
      //           SizedBox(height: 20),
      //           TextButton(
      //             onPressed: () {
      //               Navigator.pushNamed(context, '/signup');
      //             },
      //             child: Text('Don\'t have an account? Sign up', style: TextStyle(color: Colors.white70, fontSize: 16)),
      //           ),
      //         ],
      //       ),
      //     ),
      //   ),
      // ),
      body: Container(
  decoration: BoxDecoration(
    image: DecorationImage(
      image: AssetImage('assets/login1.jpeg'),
      fit: BoxFit.cover, // Adjust the image to cover the entire background
    ),
  ),
  child: Center(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.fitness_center, color: Colors.white, size: 100),
          SizedBox(height: 30),
          TextField(
            controller: _usernameController,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              // fillColor: Colors.white24,
              fillColor: Colors.black87,
              hintText: 'Username',
              hintStyle: TextStyle(color: Colors.white70),
              prefixIcon: Icon(Icons.person, color: Colors.white70),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          SizedBox(height: 20),
          TextField(
            controller: _passwordController,
            obscureText: true,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.black87,
              hintText: 'Password',
              hintStyle: TextStyle(color: Colors.white70),
              prefixIcon: Icon(Icons.lock, color: Colors.white70),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        SizedBox(height: 30),
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Color.fromARGB(255, 247, 128, 0), // Fully opaque orange
    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
    ),
  ),
  onPressed: _login,
  child: Text('Login', style: TextStyle(color: Colors.white, fontSize: 18)),
),
SizedBox(height: 20),

          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/signup');
            },
            child: Text('Don\'t have an account? Sign up', style: TextStyle(color: Colors.white70, fontSize: 16)),
          ),
        ],
      ),
    ),
  ),
      ),
);
    
    
  }
}
