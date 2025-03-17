// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:myapp/authservice.dart';
import 'package:myapp/report.dart';
import 'package:myapp/stats.dart';
import 'package:myapp/googlemap.dart';
import 'global.dart';
import 'firestore_service.dart';

import 'package:myapp/workoutscreen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}
final AuthService _authService = AuthService();
class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  String _username = '';
  String _age = '';
  String _weight = '';
  String _trainingData='';
  String _height = '';
  String _gender= '';
  double _waterProgress = 0.0;
  double _stepProgress = 0.0;
  int _waterConsumed = 0;
     double waterIntake = 0;
   double stepTarget = 0;
   int _stepsWalked =0;
final FirestoreService _firestoreService = FirestoreService();

  // @override
  // void initState() {
  //   super.initState();
  //   fetchIam();
  // }


  List<Map<String, dynamic>> _workoutProgressData = [];
List<String> _messages = []; // Store chat messages
  TextEditingController _chatController = TextEditingController();
  bool _isLoading = true; // Flag to track loading state
  @override
  void initState() {
    super.initState();
        fetchIam();
    setState(() {
      _isLoading = false; // Data is now loaded
    });
    _fetchUserProfile();
    _fetchWaterIntakeData(); // Fetch water intake data on initialization
    _fetchStepstakeData();
    _fetchWorkoutProgressData();

  }
    void fetchIam() async {
      if (ec2host != null && ec2host!.isNotEmpty) return;
    String? value = await _firestoreService.fetchAndSetIam();
    if (value != null) {
    setState(() {
      ec2host = value;
    });
   WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DashboardPage()),
      );
    });
  }
  }
  final ScrollController _scrollController = ScrollController();
// Method to show the floating chat window
 void _showChatWindow(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Important to make space for the keyboard
    builder: (BuildContext context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.6, // Adjust the initial size
        minChildSize: 0.3, // Minimum size when dragged down
        maxChildSize: 0.9, // Maximum size (almost full screen)
        expand: false,
        builder: (context, scrollController) {
          return StatefulBuilder(
            builder: (BuildContext context, setState) {
              return Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom, // Adjust for keyboard
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController, // Link scroll controller
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          return _buildMessageBubble(_messages[index], index % 2 == 0);
                        },
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _chatController,
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.send),
                          onPressed: () {
                            final userMessage = _chatController.text.trim();
                            if (userMessage.isNotEmpty) {
                              setState(() {
                                _messages.add('You: $userMessage');
                                _chatController.clear();
                                _messages.add('Assistant: '); // Placeholder for loading animation
                              });
                              _startLoadingAnimation(setState);
                              _sendChatMessage(userMessage, setState);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}

// // Method to send the chat message to the backend
// void _showChatWindow(BuildContext context) {
//   showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     builder: (BuildContext context) {
//       return StatefulBuilder(
//         builder: (BuildContext context, setState) {
//           return Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 // Chat messages list
//                 Expanded(
//                   child: ListView.builder(
//                     itemCount: _messages.length,
//                     itemBuilder: (context, index) {
//                       return _buildMessageBubble(_messages[index], index % 2 == 0);
//                     },
//                   ),
//                 ),
//                 // Text input field
//                 Row(
//                   children: [
//                     Expanded(
//                       child: TextField(
//                         controller: _chatController,
//                         decoration: InputDecoration(
//                           hintText: 'Type a message...',
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                         ),
//                       ),
//                     ),
//                     IconButton(
//                       icon: Icon(Icons.send),
//                       onPressed: () {
//                         final userMessage = _chatController.text.trim();
//                         if (userMessage.isNotEmpty) {
//                           setState(() {
//                             // Add user message
//                             _messages.add('You: $userMessage');
//                             _chatController.clear();
//                             _messages.add('Assistant: '); // Placeholder for loading animation
//                           });
//                           _startLoadingAnimation(setState);
//                           _sendChatMessage(userMessage, setState);
//                         }
//                       },
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           );
//         },
//       );
//     },
//   );
// }

// Start a continuous "Loading..." animation
Timer? _loadingTimer;
void _startLoadingAnimation(Function setState) {
  const loadingText = "Loading...";
  int currentIndex = 0;

  _loadingTimer?.cancel(); // Cancel any previous timer
  _loadingTimer = Timer.periodic(Duration(milliseconds: 200), (timer) {
    setState(() {
      if (_messages.isNotEmpty && _messages.last.startsWith("Assistant")) {
        // Update the "Assistant: Loading..." animation
        _messages[_messages.length - 1] = "Assistant: ${loadingText.substring(0, currentIndex + 1)}";
        currentIndex = (currentIndex + 1) % loadingText.length; // Cycle through the letters
      }
    });
  });
}

// Stop the loading animation when the response is ready
void _stopLoadingAnimation(Function setState) {
  _loadingTimer?.cancel();
  _loadingTimer = null;
}

// Send chat message and handle response
Future<void> _sendChatMessage(String message, Function setState) async {
  final url = 'http://localhost:11434/api/generate';
  final geminiurl='https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent'; // Your backend URL
  final headers = {
    'Content-Type': 'application/json',
    'User-Agent': 'insomnia/10.3.0',
  };
  final geminiheaders={
     'Content-Type': 'application/json', 
    'x-goog-api-key': 'AIzaSyDddz2AYvl3cI-QI6I9ngka4ZR2hNaDIlQ', //API key for gemini
  };
   _trainingData="Name is "+_username+" of gender " +_gender+" having  " +_weight+"kg weight and "+_height+"cm height and my age is "+_age+" so when ever you are doing something keep this in mind. Your name is FitAI and you mother tongue is english. You are a fitness coach, medical professional, registered nutritionist, and a registered dietician, specializing in workouts, daily intake calculations, nutrition, and diet plans. You can only respond to questions related to fitness, workouts, diets, or nutritional requirements, including how much protein or food items like chicken a person can consume based on their weight, height, age, and fitness goals. For queries outside of fitness or diet, don't give the answer. Politely inform the user that you specialize in fitness and ask if you can help with fitness-related questions. ";
  //  print(_trainingData);
   String geminiData='';
   geminiData="if you are asked to tell my  name, bmi, age, height, gender, weight you can respond with the correct value.  My Name is "+_username+" of gender " +_gender+" having  " +_weight+"kg weight and "+_height+"cm height and my age is "+_age+" so when ever you are doing something keep this in mind. Your name is FitAI and you mother tongue is english. You are a fitness coach, medical professional, registered nutritionist, and a registered dietician, specializing in workouts, daily intake calculations, nutrition, and diet plans. You can only respond to questions related to fitness, workouts, diets, or nutritional requirements, including how much protein or food items like chicken a person can consume based on their weight, height, age, and fitness goals. For queries outside of fitness or diet, don't give the answer. Politely inform the user that you specialize in fitness and ask if you can help with fitness-related questions. But if you are asked to tell the name, bmi, age, height, gender, weight you can respond with the correct value";
  print(geminiData);
  final body = jsonEncode({
    'model': 'gemma2:2b',
    'prompt': message,
    'stream': false,
    'system':_trainingData,
    'options': {'temperature': 0},
  });
final geminibody= jsonEncode({"system_instruction": {
    "parts":
      { "text": geminiData}},
      "contents": [{
        "parts":[{"text": message}]
        }]
       });
  try {
    // final response = await http.post(Uri.parse(url), headers: headers, body: body);
 final response = await http.post(Uri.parse(geminiurl), headers: geminiheaders, body: geminibody);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // final assistantResponse = data['response'] ?? 'Sorry, I am unable to provide an answer at the moment.';
      final assistantResponse = data['candidates'][0]['content']['parts'][0]['text'] ?? 'Sorry, I am unable to provide an answer at the moment.';

      _stopLoadingAnimation(setState); // Stop the loading animation
      setState(() {
        _messages.removeLast(); // Remove the loading animation
        _messages.add('Assistant: '); // Add the actual response
        
      });
      for (int i = 0; i < assistantResponse.length; i++) {
        await Future.delayed(Duration(milliseconds: 1)); // Delay between each character
        setState(() {
          _messages[_messages.length - 1] =
              'Assistant: ${assistantResponse.substring(0, i + 1)}';
        });
      }
    } else {
      _stopLoadingAnimation(setState); // Stop the loading animation
      setState(() {
        _messages.removeLast();
        _messages.add('Assistant: Sorry, something went wrong. Please try again.');
      });
    }
  } catch (error) {
    _stopLoadingAnimation(setState); // Stop the loading animation
    setState(() {
      _messages.removeLast();
      _messages.add('Assistant: Unable to connect to the server. Please try again later.');
    });
    print('Error sending message: $error');
  }
}


  // Build a message bubble with different styles for sender and assistant
  Widget _buildMessageBubble(String message, bool isUserMessage) {
    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isUserMessage ? Colors.blue[200] : Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  int _parseTarget(String target) {
    // Convert target string like '10 reps' or '3000 m' into an integer value
    return int.tryParse(target.split(' ')[0]) ?? 0;
  }
    Map<String, String> keyMapping = {
    "legpress": "Leg Press Progress (kg)",
    "squats": "Squats Progress (reps)",
    "weightlift": "Weight Lift Progress (kg)",
    "deadlift": "Dead Lift Progress (kg)",
    "pushups": "Push Ups Progress (reps)",
    "pullups": "Pull Ups Progress (reps)",
    "jumpingjacks": "Jumping Jacks Progress (reps)",
    "walking": "Walking Progress (metres)",
    "swimming": "Swimming Progress (metres)",
    "cycling": "Cycling Progress (metres)",
    "running": "Running Progress (metres)",
    "lunges": "Lunges Progress (reps)",
    "benchpress": "Bench Press Progress (reps)"
  };
  Color _getColorForWorkout(String workoutName) {
    // Assign colors to each workout type for better visualization
    switch (workoutName) {
      case 'Pull Ups Progress (reps)':
        return Colors.blue;
      case 'Push Ups Progress (reps)':
        return Colors.red;
      case 'Squats Progress (reps)':
        return Colors.green;
      case 'Cycling Progress (metres)':
        return Colors.orange;
      case 'Running Progress (metres)':
        return const Color.fromARGB(255, 147, 81, 159);
      case 'Bench Press Progress (reps)':
        return const Color.fromARGB(255, 140, 99, 187);
      case 'Lunges Progress (reps)':
        return const Color.fromARGB(255, 116, 213, 156);
      case 'Swimming Progress (metres)':
        return const Color.fromARGB(255, 189, 226, 129);
      case 'Walking Progress (metres)':
        return  const Color.fromARGB(255, 108, 227, 162);
      case 'Jumping Jacks Progress (reps)':
        return  const Color.fromARGB(217, 103, 220, 218);
      case 'Dead Lift Progress (kg)':
        return const Color.fromARGB(255, 217, 239, 75);
      case 'Weight Lift Progress (kg)':
        return  const Color.fromARGB(255, 155, 119, 65);
      case 'Leg Press Progress (kg)':
        return const Color.fromARGB(255, 10, 86, 227);
      default:
        return Colors.grey;
    }
  }
  Future<void> _fetchWorkoutProgressData() async {
      final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token1');
    String? username = prefs.getString('userna1me');
      String authHeader = 'Bearer $token'; 
    try {

            final response = await http.post(
        Uri.parse('$ec2host:8080/userdailydatatarget/$username'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': authHeader,
      },
      body: jsonEncode(<String, String>{
        "dummy" : "2", // Send the entered value in the body
      }),
    );


      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List workoutData = data['Workout'];
        setState(() {
          _workoutProgressData = workoutData.map<Map<String, dynamic>>((workout) {
            String newKey = keyMapping[workout['Name']] ?? workout['Name'];
            final String name = newKey;
            final int done = workout['Done'];
            final target = _parseTarget(workout['Target']);
            // final progress = workout[]
            // final double progress = target > 0 ? (done / target) * 100 : 0;

            return {
              'name': name,
              'progress': done,
              'target' : target,
              'color': _getColorForWorkout(name),
            };
          }).toList();
        });
      } else {
        print('Failed to load workout data: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching workout progress data: $error');
    }
  }
  Future<void> _fetchStepstakeData() async {
        final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token1');
    String? username = prefs.getString('userna1me');
      String authHeader = 'Bearer $token'; 

    if (token == null || username == null) {
      print('Token or username is missing.');
      return;
    }
    try {
      final response = await http.post(
        Uri.parse('$ec2host:8080/userdailydata/$username'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': authHeader,
      },
      body: jsonEncode(<String, String>{
        "dummy" : "2", // Send the entered value in the body
      }),
    );
    final prefs = await SharedPreferences.getInstance();
    String? bmiString = prefs.getString('bmi');
    if (bmiString != null) {
      double bmi = double.tryParse(bmiString) ?? 0;
      print(bmi);
      // Calculate water intake based on BMI
      if (bmi < 18) {
        stepTarget = 10000;
      } else if (bmi >= 18 && bmi <= 25) {
        stepTarget = 12000;
      } else {
        stepTarget = 8000;
      }
    }
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(data);
        setState(() {
          _stepsWalked = data['steps'];
          _stepProgress = (_stepsWalked / stepTarget).clamp(0.0, 1.0); // Ensure the value is between 0 and 1
          print("steps walked progress ");
          print(_stepProgress);
        });
      } else {
        print('Failed to load data: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching data: $error');
    }
  }


  Future<void> _fetchWaterIntakeData() async {
        final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token1');
    String? username = prefs.getString('userna1me');
      String authHeader = 'Bearer $token'; 

    if (token == null || username == null) {
      print('Token or username is missing.');
      return;
    }
    try {
      final response = await http.post(
        Uri.parse('$ec2host:8080/userdailydata/$username'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': authHeader,
      },
      body: jsonEncode(<String, String>{
        "dummy" : "2", // Send the entered value in the body
      }),
    );
    final prefs = await SharedPreferences.getInstance();
    String? bmiString = prefs.getString('bmi');
    if (bmiString != null) {
      double bmi = double.tryParse(bmiString) ?? 0;
      print(bmi);
      // Calculate water intake based on BMI
      if (bmi < 18) {
        waterIntake = 3.0;
      } else if (bmi >= 18 && bmi <= 25) {
        waterIntake = 3.5;
      } else {
        waterIntake = 4.0;
      }
    }
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(data);
        setState(() {
          _waterConsumed = data['water'];
          _waterProgress = (_waterConsumed / waterIntake).clamp(0.0, 1.0); // Ensure the value is between 0 and 1
        });
      } else {
        print('Failed to load data: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching data: $error');
    }
  }

  Future<void> _fetchUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token1');
    String? username = prefs.getString('userna1me');

    if (token != null && username != null) {
      String authHeader = 'Bearer $token';
      try {
        final response = await http.post(
          Uri.parse('$ec2host:8080/getuser/$username'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': authHeader,
            'Accept': '*/*',
          },
          body: jsonEncode(<String, String>{
            'someKey': 'someValue', // If you need to send any data in the body
          }),
        );

        if (response.statusCode == 200) {
          String rawData = response.body;
          if (rawData.startsWith('w')) {
            rawData = rawData.substring(1); // Remove leading character
          }
          var userData = jsonDecode(rawData);
          await prefs.setString('weight', userData['weight'].toString());
          await prefs.setString('bmi', userData['bmi'].toString());
          await prefs.setString('height', userData['height'].toString());
          setState(() {
            _username = userData['firstname'] ?? '';
            _gender=userData['gender']?? '';
            _age = (userData['age'] != null && userData['age'] >= 0)
                ? userData['age'].toString()
                : 'N/A';
            _weight = (userData['weight'] != null && userData['weight'] >= 0)
                ? userData['weight'].toString()
                : 'N/A';
            _height = (userData['height'] != null && userData['height'] >= 0)
          ? userData['height'].toString()
          : 'N/A';
          });
        } else {
          print('Error fetching user profile: ${response.statusCode}');
        }
      } catch (e) {
        print('Error: $e');
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
       if (_selectedIndex == 0) {
         _fetchUserProfile();
    _fetchWaterIntakeData(); // Fetch water intake data on initialization
    _fetchStepstakeData();
    _fetchWorkoutProgressData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
     if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()), // Show loading spinner
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Fitness Tracker',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
           IconButton(
            icon: Icon(Icons.chat),
              onPressed: () {
              _showChatWindow(context); // Navigate to ChatScreen
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await _authService.logout(); // Call the logout method
              Navigator.of(context).pushReplacementNamed('/login'); // Navigate to login page
            },
          ),
        ],
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        centerTitle: true,
      ),
      body:Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/background.jpg', // Set the path to your background image
              fit: BoxFit.cover,
            ),
          ),
           _selectedIndex == 0 
          ? DashboardScreen(username: _username, age: _age, weight: _weight, waterProgress: _waterProgress, waterConsumed: _waterConsumed, stepProgress: _stepProgress,stepConsumed: _stepsWalked,workoutProgressData: _workoutProgressData,) 
         : _selectedIndex == 1 
            ? WorkoutsScreen() 
          : _selectedIndex == 2
            ? NearbyGymsScreen() 
            : _selectedIndex == 3
            ? StatsScreen()
            : ReportPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Workouts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_pin),
            label: 'Gyms',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.summarize_sharp),
            label: 'Reports',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Color.fromARGB(255, 206, 224, 228),
        onTap: _onItemTapped,
      ),
    );
  }
}

// Main Dashboard Screen
class DashboardScreen extends StatelessWidget {
  final String username;
  final String age;
  final String weight;
  final double waterProgress;
  final int waterConsumed;
    final double stepProgress;
  final int stepConsumed;
  // final List<PieChartSectionData> workoutProgressData;
final List<Map<String, dynamic>> workoutProgressData;
  const DashboardScreen({
    Key? key,
    required this.username,
    required this.age,
    required this.weight,
    required this.waterProgress,
    required this.waterConsumed,
    required this.stepConsumed,
    required this.stepProgress,
     required this.workoutProgressData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildUserProfile(),
          SizedBox(height: 20),
          // _buildWorkoutsCompleted(),
          SizedBox(height: 20),
          _buildWorkoutProgressCharts(context),
          SizedBox(height: 20),
          _buildWaterIntakeProgress(),
          SizedBox(height: 20),
          _buildStepsCounter(),
          SizedBox(height: 20),
        ],
      ),
    );
  }
Widget _buildWorkoutProgressCharts(BuildContext context) {
  return Wrap(
    spacing: 16.0, // Horizontal spacing between charts
    runSpacing: 16.0, // Vertical spacing between rows of charts
    children: workoutProgressData.map((workout) {
      double progress = double.tryParse(workout['progress'].toString()) ?? 0.0;
      double target = double.tryParse(workout['target'].toString()) ?? 0.0;
      double value1 = (progress >= target) ? progress : progress;
      double value2 = (progress >= target) ? 0.0 : (target - progress);

      return SizedBox(
        width: MediaQuery.of(context).size.width / 2 - 24, // Fit two charts in a row
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: SizedBox( // Ensure equal height for all items
            height: 250, // Adjust this height as needed
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: [
                      Icon(Icons.pie_chart, color: workout['color']),
                      SizedBox(width: 10),
                      Expanded( 
                        child: Text(
                          '${workout['name']}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          softWrap: true, 
                          maxLines: 3, // Keep text limited to 2 lines for uniform height
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Expanded( // This makes sure the pie chart expands properly without breaking layout
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: value1,
                            color: workout['color'],
                            radius: 35,
                            titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          PieChartSectionData(
                            value: value2,
                            color: Colors.grey.shade300,
                            radius: 33,
                          ),
                        ],
                        centerSpaceRadius: 38,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList(),
  );
}


  Widget _buildUserProfile() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 40,
              backgroundImage: AssetImage('assets/user_profile.jpg'), // Change the path as necessary
            ),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  username.isNotEmpty ? username : 'Loading...',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'Age: ${age.isNotEmpty ? age : 'Loading...'}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                Text(
                  'Weight: ${weight.isNotEmpty ? weight : 'Loading...'} kg',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildWorkoutsCompleted() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: [
                Icon(Icons.fitness_center, color: Colors.blueAccent),
                SizedBox(width: 10),
                Text(
                  'Workouts Completed',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Text('1. Running - 30 mins', style: TextStyle(color: Colors.grey.shade600)),
            Text('2. Cycling - 45 mins', style: TextStyle(color: Colors.grey.shade600)),
            Text('3. Swimming - 25 mins', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }









  Widget _buildWaterIntakeProgress() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: [
                Icon(Icons.local_drink, color: Colors.blue),
                SizedBox(width: 10),
                Text(
                  'Water Intake',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            LinearProgressIndicator(
              value: waterProgress, // Use the dynamic value calculated from API response
              minHeight: 10,
              backgroundColor: Colors.grey.shade300,
              color: Colors.blueAccent,
            ),
            SizedBox(height: 10),
            Text(
              'You have consumed ${waterConsumed} liters today.', // Display water consumed in liters
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsCounter() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: [
                Icon(Icons.directions_walk, color: const Color.fromARGB(255, 20, 160, 39)),
                SizedBox(width: 10),
                Text(
                  'Step Counter',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            LinearProgressIndicator(
              value: stepProgress, // Use the dynamic value calculated from API response
              minHeight: 10,
              backgroundColor: Colors.grey.shade300,
              color: Colors.blueAccent,
            ),
            SizedBox(height: 10),
            Text(
              'You have walked  ${stepConsumed} steps today.', // Display water consumed in liters
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
