import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:myapp/stats.dart';
import 'package:myapp/workoutscreen.dart';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart'; // Import the calendar package
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'global.dart';


DateTime ?_selectedDay ;
String  _dateSelected = ' ';
DateTime _focusedDay = DateTime.now(); // For managing the focused day
bool _isWorkoutDataAvailable = true;
bool _isWaterDataAvailable = true;
bool _isStepsDataAvailable = true;


class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  
  int _selectedIndex = 0;
  String _username = '';
  String _age = '';
  String _weight = '';
  double _waterProgress = 0.0;
  double _stepProgress = 0.0;
  int _waterConsumed = 0;
  double waterIntake = 0;
  double stepTarget = 0;
  int _stepsWalked = 0;



  List<Map<String, dynamic>> _workoutProgressData = [];

  @override
  void initState() {
    super.initState();
    _fetchWaterIntakeData( _dateSelected); // Fetch water intake data on initialization
    _fetchStepstakeData(_dateSelected);
    _fetchWorkoutProgressData(_dateSelected);
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
        return const Color.fromARGB(255, 108, 227, 162);
      case 'Jumping Jacks Progress (reps)':
        return const Color.fromARGB(217, 103, 220, 218);
      case 'Dead Lift Progress (kg)':
        return const Color.fromARGB(255, 217, 239, 75);
      case 'Weight Lift Progress (kg)':
        return const Color.fromARGB(255, 155, 119, 65);
      case 'Leg Press Progress (kg)':
        return const Color.fromARGB(255, 10, 86, 227);
      default:
        return Colors.grey;
    }
  }

  Future<void> _fetchWorkoutProgressData(String _dateSelected) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token1');
    String? username = prefs.getString('userna1me');
    String authHeader = 'Bearer $token'; 
    try {
      final response = await http.post(
        Uri.parse('$ec2host:8080/userdailydatatarget/$username/$_dateSelected'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': authHeader,
        },
        body: jsonEncode(<String, String>{
          "dummy": "2", // Send the entered value in the body
        }),
      );

if (response.statusCode == 200) {
    final data = json.decode(response.body);
    List workoutData = data['Workout'];
    setState(() {
       _isWorkoutDataAvailable = true;
      _workoutProgressData = workoutData.isNotEmpty
          ? workoutData.map<Map<String, dynamic>>((workout) {
              String newKey = keyMapping[workout['Name']] ?? workout['Name'];
              final String name = newKey;
              final int done = workout['Done'];
              final target = _parseTarget(workout['Target']);

              return {
                'name': name,
                'progress': done,
                'target': target,
                'color': _getColorForWorkout(name),
              };
            }).toList()
          : []; // Clear the workout data if there's no data for the selected date
    });
} else {
    setState(() {
      _isWorkoutDataAvailable = false;
      _workoutProgressData = []; // Clear data on error
    });
    print('Failed to load workout data: ${response.statusCode}');
}

    } catch (error) {
      print('Error fetching workout progress data: $error');
    }
  }

  Future<void> _fetchStepstakeData(String _dateSelected) async {
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
        Uri.parse('$ec2host:8080/userdailydata/$username/$_dateSelected'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': authHeader,
        },
        body: jsonEncode(<String, String>{
          "dummy": "2", // Send the entered value in the body
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
      _isStepsDataAvailable = true;
      _stepsWalked = data['steps'] ?? 0;
      _stepProgress = (_stepsWalked / stepTarget).clamp(0.0, 1.0);
    });
} else {
    setState(() {
      _isStepsDataAvailable = false;
      _stepsWalked = 0; // Reset steps walked if no data is available
      _stepProgress = 0.0; // Reset step progress if no data is available
    });
    print('Failed to load data for steps: ${response.statusCode}');
}

    } catch (error) {
      print('Error fetching data: $error');
    }
  }

  Future<void> _fetchWaterIntakeData(String _dateSelected ) async {
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
        Uri.parse('$ec2host:8080/userdailydata/$username/$_dateSelected'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': authHeader,
        },
        body: jsonEncode(<String, String>{
          "dummy": "2", // Send the entered value in the body
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
       _isWaterDataAvailable = true;
      _waterConsumed = data['water'] ?? 0;
      _waterProgress = (_waterConsumed / waterIntake).clamp(0.0, 1.0);
    });
} else {
    setState(() {
       _isWaterDataAvailable = false;
      _waterConsumed = 0; // Reset water consumed if no data is available
      _waterProgress = 0.0; // Reset water progress if no data is available
    });
    print('Failed to load data for water: ${response.statusCode}');
}

    } catch (error) {
      print('Error fetching data: $error');
    }
  }
  
    Widget _buildWorkoutProgressCharts(BuildContext context) {
        if (!_isWorkoutDataAvailable) {
  return Center(
  child: Container(
    padding: EdgeInsets.all(16.0),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12.0),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.5),
          spreadRadius: 2,
          blurRadius: 5,
          offset: Offset(0, 3), // changes position of shadow
        ),
      ],
      border: Border.all(color: Colors.red, width: 1.5),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.error_outline,
          color: Colors.red,
          size: 24,
        ),
        SizedBox(width: 8), // Space between the icon and text
        Text(
          'No details available for Workout done',
          style: TextStyle(fontSize: 12, color: Colors.red),
        ),
      ],
    ),
  ),
);

  }
      double value1;
double value2;
  return Wrap(
    spacing: 16.0, // Horizontal spacing between charts
    runSpacing: 16.0, // Vertical spacing between rows of charts
    children: _workoutProgressData.map((workout) {
            if (workout['progress'] >= workout['target']) {
  value1 = workout['progress'].toDouble(); // Completed progress
  value2 = 0; // No remaining progress
} else {
  value1 = workout['progress'].toDouble(); // Completed progress
  value2 = (workout['target'] - workout['progress']).toDouble(); // Remaining progress
}
      return SizedBox(
        width: MediaQuery.of(context).size.width / 2 - 24, // Width to fit two charts in a row
        child: Card(
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
                  // children: [
                  //   Icon(Icons.pie_chart, color: workout['color']),
                  //   SizedBox(width: 10),
                  //   Text(
                  //     '${workout['name']} ',
                  //     style: TextStyle(
                  //       fontSize: 12,
                  //       fontWeight: FontWeight.bold,
                  //       color: Colors.black,
                  //     ),
                  //     //  overflow: TextOverflow.ellipsis,
                  //     //   maxLines: 1,
                  //      softWrap: true,
                  //       maxLines: 4, // Keep text limited to 2 lines for uniform height
                  //       overflow: TextOverflow.ellipsis,
                  //   ),
                  // ],
                    children: [
    Icon(Icons.pie_chart, color: workout['color']),
    SizedBox(width: 10),
    Expanded( // Allow text to wrap within available space
      child: Text(
        '${workout['name']} ',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        softWrap: true,
        maxLines: 3, // Limit text to 2 lines for uniform height
        overflow: TextOverflow.ellipsis, // Add ellipsis if text overflows
      ),
    ),
  ],
                ),
                SizedBox(height: 10),
                SizedBox(
                  height: 150,
                  child: PieChart(
                    
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: value1,
                          // title: '${workout['progress'].toStringAsFixed(1)}%',
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
      );
    }).toList(),
  );
}
String formatSelectedDay(DateTime date) {
  return DateFormat('yyyy-MM-dd').format(date);
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Fitness Tracker'),
      // ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.jpg'), // Replace with your image asset
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
        children: [
          Container(
            height: 400, // Fixed height for calendar
            width: 300,
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              // lastDay: DateTime.utc(2030, 12, 31),
              lastDay: DateTime.now(),
              focusedDay: _focusedDay,
               selectedDayPredicate: (day) => _selectedDay != null && isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  print(selectedDay);
                 _selectedDay = selectedDay; // Update _selectedDay first
        _dateSelected = formatSelectedDay(_selectedDay!); // Then set _dateSelected
        _focusedDay = focusedDay; // Update focused day
        _fetchWaterIntakeData(_dateSelected);
        _fetchStepstakeData(_dateSelected);
        _fetchWorkoutProgressData(_dateSelected);
                });
              },
              calendarStyle: CalendarStyle(
                // todayDecoration: BoxDecoration(
                //   color: Colors.blue[400],
                //   shape: BoxShape.circle,
                // ),
                selectedDecoration: BoxDecoration(
                  color: Colors.blue[800],
                  shape: BoxShape.circle,
                ),
              ),
               headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true, // Center the title
    leftChevronVisible: true, // Show left chevron (back)
    rightChevronVisible: true, // Show right chevron (forward)
               ),
            ),
          ),
             SizedBox(height: 20),
          _buildWorkoutProgressCharts(context),
                    SizedBox(height: 20),
          _buildWaterIntakeProgress(_waterConsumed,_waterProgress),
          SizedBox(height: 20),
          _buildStepsCounter(_stepsWalked,_stepProgress),
          SizedBox(height: 20),
         
        ],
          )
      ),
    ),
    );
  }
}

  Widget _buildWaterIntakeProgress(int _waterConsumed, double _waterProgress) {
      if (!_isWaterDataAvailable) {
     return Center(
  child: Container(
    padding: EdgeInsets.all(16.0),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12.0),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.5),
          spreadRadius: 2,
          blurRadius: 5,
          offset: Offset(0, 3), // changes position of shadow
        ),
      ],
      border: Border.all(color: Colors.red, width: 1.5),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.error_outline,
          color: Colors.red,
          size: 20,
        ),
        SizedBox(width: 8), // Space between the icon and text
        Text(
          'No details available for Water Intake',
          style: TextStyle(fontSize: 12, color: Colors.red),
        ),
      ],
    ),
  ),
);
  }
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
              value: _waterProgress, // Use the dynamic value calculated from API response
              minHeight: 10,
              backgroundColor: Colors.grey.shade300,
              color: Colors.blueAccent,
            ),
            SizedBox(height: 10),
            Text(
              'You have consumed ${_waterConsumed} liters.', // Display water consumed in liters
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsCounter(int _stepsWalked,double _stepProgress ) {
      if (!_isStepsDataAvailable) {
     return Center(
  child: Container(
    padding: EdgeInsets.all(16.0),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12.0),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.5),
          spreadRadius: 2,
          blurRadius: 5,
          offset: Offset(0, 3), // changes position of shadow
        ),
      ],
      border: Border.all(color: Colors.red, width: 1.5),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.error_outline,
          color: Colors.red,
          size: 20,
        ),
        SizedBox(width: 8), // Space between the icon and text
        Text(
          'No details available for Steps Walked',
          style: TextStyle(fontSize: 12, color: Colors.red),
        ),
      ],
    ),
  ),
);
  }
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
              value: _stepProgress, // Use the dynamic value calculated from API response
              minHeight: 10,
              backgroundColor: Colors.grey.shade300,
              color: Colors.blueAccent,
            ),
            SizedBox(height: 10),
            Text(
              'You have walked  ${_stepsWalked} steps', // Display water consumed in liters
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
