import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class WorkoutGallery extends StatefulWidget {
  const WorkoutGallery({super.key});

  @override
  _WorkoutGalleryState createState() => _WorkoutGalleryState();
}

class _WorkoutGalleryState extends State<WorkoutGallery> {
  Map<String, List<String>> workouts = {};

  @override
  void initState() {
    super.initState();
    loadWorkouts();
  }

  Future<void> loadWorkouts() async {
    try {
      final String response = await rootBundle.loadString('assets/workout_data.json');
      final Map<String, dynamic> data = json.decode(response);

      setState(() {
        workouts = data['workouts'].map<String, List<String>>(
          (key, value) => MapEntry(key as String, List<String>.from(value as List)),
        );
      });
    } catch (e) {
      print("Error loading workouts: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (workouts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 3 / 2,
          ),
          itemCount: workouts.keys.length,
          itemBuilder: (context, index) {
            String category = workouts.keys.elementAt(index);

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        WorkoutDetailPage(category: category, gifs: workouts[category]!),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color.fromARGB(255, 102, 153, 235), const Color.fromARGB(255, 54, 132, 234)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(2, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.fitness_center, size: 50, color: Colors.white),
                    const SizedBox(height: 8),
                    Text(
                      category.replaceAll('-', ' '),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class WorkoutDetailPage extends StatelessWidget {
  final String category;
  final List<String> gifs;

  const WorkoutDetailPage({super.key, required this.category, required this.gifs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: gifs.length,
          itemBuilder: (context, index) {
            String gif = gifs[index];

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        WorkoutGifViewer(category: category, gif: gif),
                  ),
                );
              },
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/workouts/$category/$gif',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image, size: 40),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    gif.replaceAll('.gif', '').replaceAll('-', ' '),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class WorkoutGifViewer extends StatelessWidget {
  final String category;
  final String gif;

  const WorkoutGifViewer({super.key, required this.category, required this.gif});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context), // Go back
        ),
        title: Text(
          gif.replaceAll('.gif', '').replaceAll('-', ' '), // Display workout name
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 3.0,
          child: Image.asset(
            'assets/workouts/$category/$gif',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Text("Error loading image", style: TextStyle(color: Colors.white));
            },
          ),
        ),
      ),
    );
  }
}
