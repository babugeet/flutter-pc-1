import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'global.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  _WorkoutsScreenState createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  Future<List<WorkoutDetail>>? cardioWorkoutsFuture;
  Future<List<WorkoutDetail>>? strengthWorkoutsFuture;
  Future<List<DietDetail>>? dietFuture;
   double waterIntake = 0;
   double stepTarget = 0;

  @override
  void initState() {
    super.initState();
    cardioWorkoutsFuture = fetchCardioWorkouts();
    strengthWorkoutsFuture = fetchStrengthWorkouts();
    dietFuture=fetchDiet();
    _getWaterIntake();
    _getStepTarget();
  }
      Future<void> _getStepTarget() async {
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
    setState(() {});
    print("CalculatedStep: $stepTarget Steps");
    
  }
    Future<void> _getWaterIntake() async {
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
    setState(() {});
    print("Calculated Water Intake: $waterIntake Liters");
    
  }

  Future<List<DietDetail>> fetchDiet() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token1');
      String? username = prefs.getString('userna1me');

      if (token == null || username == null) {
        print('Token or username is missing.');
        return [];
      }

      String authHeader = 'Bearer $token';
      final response = await http.post(
        Uri.parse('$ec2host:8080/getuser/$username/dietplan'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
            'Origin': 'http://localhost:8081',
          'Authorization': authHeader,
            'Accept': '*/*',
        },
        body: jsonEncode(<String, String>{
          'someKey': 'someValue', // If you need to send any data in the body
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return parseDietData(data);
      } else {
        print('Failed to load cardio workouts. Status code: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching cardio workouts: $e');
      return [];
    }
    
  }

List<DietDetail> parseDietData(Map<String, dynamic> data) {
      final Map<String, String> Diettime = {
      "breakfast": "BreakFast",
      "lunch": "Lunch",
      "dinner": "Dinner"
    };

  return data.entries.map((entry) {
    String readableName = Diettime[entry.key] ?? entry.key;
    // String name = entry.key; // Assuming entry.key is the diet name
    String duration = entry.value.toString(); // Assuming entry.value is the duration

    return DietDetail(
      name: readableName,
      duration: duration,
      weight: "N/A", // Replace with actual weight if available in the diet data
    );
  }).toList();
}
 

  Future<List<WorkoutDetail>> fetchCardioWorkouts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token1');
      String? username = prefs.getString('userna1me');

      if (token == null || username == null) {
        print('Token or username is missing.');
        return [];
      }

      String authHeader = 'Bearer $token';
      final response = await http.post(
        Uri.parse('$ec2host:8080/getuser/$username/cardioplan'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
            'Origin': 'http://localhost:8081',
          'Authorization': authHeader,
            'Accept': '*/*',
        },
        body: jsonEncode(<String, String>{
          'someKey': 'someValue', // If you need to send any data in the body
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return parseWorkoutData(data);
      } else {
        print('Failed to load cardio workouts. Status code: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching cardio workouts: $e');
      return [];
    }
  }

  Future<List<WorkoutDetail>> fetchStrengthWorkouts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token1');
      String? username = prefs.getString('userna1me');
      String? weight = prefs.getString('weight');

      if (token == null || username == null) {
        print('Token or username is missing.');
        return [];
      }

      String authHeader = 'Bearer $token';
      final response = await http.post(
        Uri.parse('$ec2host:8080/getuser/$username/workoutplan'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
            'Origin': 'http://localhost:8081',
          'Authorization': authHeader,
            'Accept': '*/*',
        },
        body: jsonEncode(<String, String>{
          'someKey': 'someValue', // If you need to send any data in the body
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return parseWorkoutData(data);
      } else {
        print('Failed to load strength workouts. Status code: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching strength workouts: $e');
      return [];
    }
  }


  List<WorkoutDetail> parseWorkoutData(Map<String, dynamic> data) {
    final Map<String, String> workoutLabels = {
      "legpress": "Leg Press",
      "squats": "Squats",
      "weightlift": "Weight Lift",
      "deadlift": "Dead Lift",
      "pushups": "Push Ups",
      "pullups": "Pull Ups",
      "jumpingjacks": "Jumping Jacks",
      "walking": "Walking",
      "swimming": "Swimming",
      "cycling": "Cycling",
      "running": "Running",
      "lunges": "Lunges",
      "benchpress": "Bench Press"
    };

    return data.entries.map((entry) {
      String readableName = workoutLabels[entry.key] ?? entry.key; // Use a fallback if the key isn't in the map

      // Assuming the entry value is the weight; adjust if your API structure is different
      // int weight = int.tryParse(entry.value.toString()) ?? 0; // Get the weight from the entry value

      return WorkoutDetail(
        name: readableName,
        duration: entry.value, // You can adjust this as needed
        weight: entry.value.toString(),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FutureBuilder<List<WorkoutDetail>>(
            future: cardioWorkoutsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Text('No strength workouts found.');
              } else {
                return _buildWorkoutCategory(
                  title: 'Strength Workouts',
                  icon: Icons.directions_run,
                  color: Colors.redAccent,
                  workouts: snapshot.data!,
                );
              }
            },
          ),
          SizedBox(height: 20),
          FutureBuilder<List<WorkoutDetail>>(
            future: strengthWorkoutsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Text('No Cardio found.');
              } else {
                return _buildWorkoutCategory(
                  title: 'Cardio Workouts',
                  icon: Icons.fitness_center,
                  color: const Color.fromARGB(255, 19, 6, 6),
                  workouts: snapshot.data!,
                );
              }
            },
          ),
          SizedBox(height: 20),
          FutureBuilder<List<DietDetail>>(
            future: dietFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Text('No strength workouts found.');
              } else {
                return _buildDietCategory(
                  title: 'Diet',
                  icon: Icons.food_bank,
                  color: const Color.fromARGB(157, 255, 4, 63),
                  workouts: snapshot.data!,
                );
              }
            },
          ),
                    SizedBox(height: 20),
                    _buildWaterStepRow()
          // _buildWaterIntakeSection(),
          // SizedBox(height: 20),
          // _buildStepCounterSection(),
        ],
      ),
    );
  }



  
  Widget _buildWaterStepRow(){
        return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Flexible(
          child:  _buildWaterIntakeSection(),
        ),
        SizedBox(width: 20), // Space between water intake and steps counter
        Flexible(
          child: _buildStepCounterSection(),
        ),
      ],
    );
  }
    Widget _buildWaterIntakeSection() {
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
              children: <Widget>[
                Icon(Icons.local_drink, color: Colors.blueAccent, size: 20),
                SizedBox(width: 10),
                Text(
                  'Water Target',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(
              '${waterIntake.toString()} Liters',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
   Widget _buildStepCounterSection() {
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
              children: <Widget>[
                Icon(Icons.directions_walk, color: Colors.green, size: 20),
                SizedBox(width: 10),
                Text(
                  'Steps Required',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(
              '${stepTarget.toString()} Steps',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

    Widget _buildDietCategory({
    required String title,
    required IconData icon,
    required Color color,
    required List<DietDetail> workouts,
  }) {
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
              children: <Widget>[
                Icon(icon, color: color, size: 20),
                SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            ...workouts.map((workout) => _buildDietDetail(workout)),
          ],
        ),
      ),
    );
  }
      String? selectedWorkout; // Store the clicked workout name
Widget _buildWorkoutCategory({
  required String title,
  required IconData icon,
  required Color color,
  required List<WorkoutDetail> workouts,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
      ),
      SizedBox(height: 10),
      Column(
        children: workouts.map((workout) {
          return GestureDetector(
            onTap: () {
              String selectedWorkout = workout.name.toLowerCase().replaceAll(" ", "");
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text(workout.name),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          "assets/$selectedWorkout.gif",
                          height: 200,
                          width: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print("GIF NOT FOUND for $selectedWorkout");
                            return Text("GIF not found for $selectedWorkout");
                          },
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context), // Close the dialog
                        child: Text("Close"),
                      ),
                    ],
                  );
                },
              );
            },
            child: Card(
              elevation: 3,
              margin: EdgeInsets.symmetric(vertical: 5),
              child: ListTile(
                title: Text(workout.name,style: TextStyle(color: Colors.black, // Change text color for workout name
                    fontWeight: FontWeight.bold, // Optional: make it bold
                    ),
                ),
                subtitle: Text("Duration: ${workout.duration}"),
                trailing: Icon(Icons.arrow_forward_ios),
              ),
            ),
          );
        }).toList(),
      ),
    ],
  );
}

  // Widget _buildWorkoutCategory({
  //   required String title,
  //   required IconData icon,
  //   required Color color,
  //   required List<WorkoutDetail> workouts,
  // }) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         title,
  //         style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
  //       ),
  //       SizedBox(height: 10),
  //       Column(
  //         children: workouts.map((workout) {
  //           return GestureDetector(
  //             onTap: () {
  //               setState(() {
  //                 selectedWorkout = workout.name.toLowerCase(); // Store the selected workout name
  //                 selectedWorkout = selectedWorkout?.replaceAll(" ", "").toLowerCase();
  //                 print("eddeded#####################################");
  //                 print(selectedWorkout);
  //               });
  //             },
  //             child: Card(
  //               elevation: 3,
  //               margin: EdgeInsets.symmetric(vertical: 5),
  //               child: ListTile(
  //                 title: Text(workout.name),
  //                 subtitle: Text("Duration: ${workout.duration}"),
  //                 trailing: Icon(Icons.arrow_forward_ios),
  //               ),
  //             ),
  //           );
  //         }).toList(),
  //       ),
  //       if (selectedWorkout != null) ...[
  //         SizedBox(height: 20),
  //         Text("Workout Preview:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
  //         SizedBox(height: 10),
  //         Image.asset(
  //           "assets/$selectedWorkout.gif",  // Display the GIF from assets
  //           height: 200,
  //           width: 200,
  //           fit: BoxFit.cover,
  //           errorBuilder: (context, error, stackTrace) {
  //             print("#################GIF NOT FOUND##############");
  //             return Text("GIF not found for $selectedWorkout");
  //           },
  //         ),
  //       ],
  //     ],
  //   );
  // }




  // Widget _buildWorkoutCategory({
  //   required String title,
  //   required IconData icon,
  //   required Color color,
  //   required List<WorkoutDetail> workouts,
  // }) {
  //   return Card(
  //     elevation: 6,
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(15),
  //     ),
  //     child: Padding(
  //       padding: const EdgeInsets.all(16.0),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: <Widget>[
  //           Row(
  //             children: <Widget>[
  //               Icon(icon, color: color, size: 20),
  //               SizedBox(width: 10),
  //               Text(
  //                 title,
  //                 style: TextStyle(
  //                   fontSize: 18,
  //                   fontWeight: FontWeight.bold,
  //                   color: Colors.black,
  //                 ),
  //               ),
  //             ],
  //           ),
  //           SizedBox(height: 10),
  //           ...workouts.map((workout) => _buildWorkoutDetail(workout)),
  //         ],
  //       ),
  //     ),
  //   );
  // }
    Widget _buildDietDetail(DietDetail diet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: <Widget>[
          Icon(Icons.adjust_sharp, color: Colors.grey.shade600),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  diet.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  '${diet.duration} ',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutDetail(WorkoutDetail workout) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: <Widget>[
          Icon(Icons.timer, color: Colors.grey.shade600),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  workout.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  '${workout.duration} | ${workout.caloriesBurned} cal burned',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class DietDetail {
  final String name;
  final String duration;
  // final int weight; // Weight property to hold the weight value
  // final int caloriesBurned;
  final String weight;

  DietDetail({
    required this.name,
    required this.duration,
    required this.weight,
  });


}
class WorkoutDetail {
  final String name;
  final String duration;
  // final int weight; // Weight property to hold the weight value
  final int caloriesBurned;
  final String weight;

  WorkoutDetail({
    required this.name,
    required this.duration,
    required this.weight,
  }) : caloriesBurned = calculateCalories(name, duration, weight);

  static int calculateCalories(String exerciseName, String duration, String weight) {
    int minutes = int.tryParse(duration.split(' ')[0]) ?? 0;
    int userWeight = int.tryParse(weight.split(' ')[0]) ?? 0;
    // A simple calorie calculation logic based on exercise type and weight
    switch (exerciseName.toLowerCase()) {
      case 'leg press':
        return ((minutes) * userWeight * 5).toInt(); // Example calculation
      case 'squats':
        return (minutes * userWeight * 5).toInt(); // Example calculation
      case 'weight lift':
        return (minutes * userWeight * 6).toInt(); // Example calculation
      case 'deadlift':
        return (minutes * userWeight * 6).toInt(); // Example calculation
      case 'push ups':
        return (minutes * userWeight *8).toInt(); // Example calculation
      case 'pull ups':
        return (minutes * userWeight *8).toInt(); // Example calculation
      case 'jumping jacks':
        return (minutes * userWeight *8).toInt(); // Example calculation
      case 'walking':
        return (minutes * userWeight*.0001 *3.8).toInt(); // Example calculation
      case 'swimming':
        return (minutes * userWeight*.001 *7).toInt(); // Example calculation
      case 'cycling':
        return (minutes * userWeight*.0001 *8).toInt(); // Example calculation
      case 'running':
        return (minutes * userWeight*.0001 *9.8).toInt(); // Example calculation
      case 'lunges':
        return (minutes * userWeight *5).toInt(); // Example calculation
      case 'bench press':
        return (minutes * userWeight *5.5).toInt(); // Example calculation
      // Add more cases as needed
      default:
      print(exerciseName.toLowerCase());
        return 0; // Default to 0 calories if no match
    }
  }
}

