import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:myapp/authservice.dart';
import 'package:myapp/dashboard.dart';
import 'package:myapp/loginpage.dart';
import 'package:myapp/report.dart';
import 'package:myapp/googlemap.dart';
import 'package:get/get.dart';
import 'package:myapp/stats.dart';
import 'firebase_options.dart';
import 'package:myapp/signinpage.dart';
import 'package:myapp/workoutscreen.dart';
import 'firestore_service.dart';


// void main() {
//   runApp(MyApp());
// }
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
 await Firebase.initializeApp(options: firebaseConfig);  
  await FirestoreService().fetchAndSetIam();
  runApp(MyApp());
}
class MyApp extends StatelessWidget {
  final AuthService _authService = AuthService();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fitness Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => FutureBuilder<bool>(
          future: _authService.isUserSignedIn(), // Check if user is signed in
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasData && snapshot.data == true) {
              // If user is signed in, navigate to the dashboard
              return DashboardPage();
            } else {
              // If not signed in, navigate to the signup page
              return LoginPage();
            }
          },
        ),
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignupPage(),
        '/dashboard': (context) => ProtectedRoute(child: DashboardPage()),
        '/profile': (context) => ProtectedRoute(child: StatsScreen()),
         '/gymmap': (context) => ProtectedRoute(child: NearbyGymsScreen()),
        '/workout': (context) => ProtectedRoute(child: WorkoutsScreen()),
        '/reports': (context) => ProtectedRoute(child: ReportPage()),
      },
    );
  }
}


class ProtectedRoute extends StatelessWidget {
  
  final Widget child;

  const ProtectedRoute({required this.child, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AuthService _authService = AuthService();

    return FutureBuilder<bool>(
      future: _authService.isUserSignedIn(), // Check cookie status
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData && snapshot.data == true) {
          return child; // User is signed in, show the protected page
        } else {
          // User is not signed in, redirect to the login page
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/login');
          });
          return Container(); // Return an empty container while redirecting
        }
      },
    );
  }
}
