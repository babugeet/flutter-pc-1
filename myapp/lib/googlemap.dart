import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class NearbyGymsScreen extends StatefulWidget {
  const NearbyGymsScreen({super.key});

  @override
  _NearbyGymsPageState createState() => _NearbyGymsPageState();
}

class _NearbyGymsPageState extends State<NearbyGymsScreen> {
  List gyms = [];
  bool isLoading = true;
  bool isError = false;

  @override
  void initState() {
    super.initState();
    fetchGyms();
  }

  Future<List> getNearbyGyms(double lat, double lng) async {
    String apiKey = "AIzaSyARxZKnVqifuZ5dfGdEhRv41OcWdKKZyNo"; // Replace with your Google API Key
    String url =
        "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lng&radius=5000&type=gym&key=$apiKey";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body);
      return jsonData['results'];
    } else {
      throw Exception("Failed to load nearby gyms");
    }
  }

  void fetchGyms() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => isError = true);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() => isError = true);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      List gymList = await getNearbyGyms(position.latitude, position.longitude);

      setState(() {
        gyms = gymList;
        isLoading = false;
      });
    } catch (e) {
      print("Error: $e");
      setState(() {
        isError = true;
        isLoading = false;
      });
    }
  }

  void openGoogleMaps(double lat, double lng) async {
    final Uri googleMapsUrl = Uri.parse("https://www.google.com/maps/dir/?api=1&destination=$lat,$lng");
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    } else {
      throw "Could not open Google Maps";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/background.jpg",
              fit: BoxFit.cover,
            ),
          ),
          Container(
            color: Colors.black.withOpacity(0.4),
          ),
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : isError
                  ? const Center(
                      child: Text("⚠️ Failed to fetch gyms. Check permissions.",
                          style: TextStyle(color: Colors.white)),
                    )
                  : gyms.isEmpty
                      ? const Center(
                          child: Text("No gyms found nearby. 🏋️‍♂️",
                              style: TextStyle(color: Colors.white)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(10),
                          itemCount: gyms.length,
                          itemBuilder: (context, index) {
                            var gym = gyms[index];
                            double? rating = gym['rating']?.toDouble();
                            String address =
                                gym['vicinity'] ?? "No address available";
                            double? lat = gym['geometry']['location']['lat'];
                            double? lng = gym['geometry']['location']['lng'];

                            return Card(
                              color: Colors.white.withOpacity(0.9),
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                leading: const Icon(Icons.fitness_center,
                                    size: 40, color: Colors.blue),
                                title: Text(
                                  gym['name'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(address),
                                    if (rating != null)
                                      Row(
                                        children: [
                                          const Icon(Icons.star,
                                              color: Colors.amber, size: 18),
                                          const SizedBox(width: 4),
                                          Text("$rating ⭐"),
                                        ],
                                      ),
                                  ],
                                ),
                                onTap: () {
                                  if (lat != null && lng != null) {
                                    openGoogleMaps(lat, lng);
                                  }
                                },
                              ),
                            );
                          },
                        ),
        ],
      ),
    );
  }
}



// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:geolocator/geolocator.dart';

// class NearbyGymsScreen extends StatefulWidget {
//   const NearbyGymsScreen({super.key});

//   @override
//   _NearbyGymsPageState createState() => _NearbyGymsPageState();
// }

// class _NearbyGymsPageState extends State<NearbyGymsScreen> {
//   List gyms = [];
//   bool isLoading = true;
//   bool isError = false;

//   @override
//   void initState() {
//     super.initState();
//     fetchGyms();
//   }

//   Future<List> getNearbyGyms(double lat, double lng) async {
//     String apiKey = "AIzaSyARxZKnVqifuZ5dfGdEhRv41OcWdKKZyNo"; // Replace with your Google API Key
//     String url =
//         "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lng&radius=5000&type=gym&key=$apiKey";

//     final response = await http.get(Uri.parse(url));

//     if (response.statusCode == 200) {
//       var jsonData = jsonDecode(response.body);
//       return jsonData['results'];
//     } else {
//       throw Exception("Failed to load nearby gyms");
//     }
//   }

//   void fetchGyms() async {
//     try {
//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//         if (permission == LocationPermission.denied) {
//           setState(() => isError = true);
//           return;
//         }
//       }
//       if (permission == LocationPermission.deniedForever) {
//         setState(() => isError = true);
//         return;
//       }

//       Position position = await Geolocator.getCurrentPosition(
//           desiredAccuracy: LocationAccuracy.high);

//       List gymList = await getNearbyGyms(position.latitude, position.longitude);

//       setState(() {
//         gyms = gymList;
//         isLoading = false;
//       });
//     } catch (e) {
//       print("Error: $e");
//       setState(() {
//         isError = true;
//         isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // appBar: AppBar(title: const Text("Nearby Gyms")),
//       body: Stack(
//         children: [
//           Positioned.fill(
//             child: Image.asset(
//               "/background.jpg", // Replace with your background image path
//               fit: BoxFit.cover,
//             ),
//           ),
//           Container(
//             color: Colors.black.withOpacity(0.4), // Dark overlay for better readability
//           ),
//           isLoading
//               ? const Center(child: CircularProgressIndicator())
//               : isError
//                   ? const Center(
//                       child: Text("⚠️ Failed to fetch gyms. Check permissions.",
//                           style: TextStyle(color: Colors.white)),
//                     )
//                   : gyms.isEmpty
//                       ? const Center(
//                           child: Text("No gyms found nearby. 🏋️‍♂️",
//                               style: TextStyle(color: Colors.white)),
//                         )
//                       : ListView.builder(
//                           padding: const EdgeInsets.all(10),
//                           itemCount: gyms.length,
//                           itemBuilder: (context, index) {
//                             var gym = gyms[index];
//                             double? rating = gym['rating']?.toDouble();
//                             String address =
//                                 gym['vicinity'] ?? "No address available";

//                             return Card(
//                               color: Colors.white.withOpacity(0.9), // Slight transparency
//                               margin: const EdgeInsets.symmetric(vertical: 8),
//                               elevation: 3,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               child: ListTile(
//                                 contentPadding: const EdgeInsets.all(12),
//                                 leading: const Icon(Icons.fitness_center,
//                                     size: 40, color: Colors.blue),
//                                 title: Text(
//                                   gym['name'],
//                                   style: const TextStyle(
//                                       fontWeight: FontWeight.bold,
//                                       fontSize: 16),
//                                 ),
//                                 subtitle: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(address),
//                                     if (rating != null)
//                                       Row(
//                                         children: [
//                                           const Icon(Icons.star,
//                                               color: Colors.amber, size: 18),
//                                           const SizedBox(width: 4),
//                                           Text("$rating ⭐"),
//                                         ],
//                                       ),
//                                   ],
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//         ],
//       ),
//     );
//   }
// }


// // import 'dart:convert';
// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:geolocator/geolocator.dart';

// // class NearbyGymsScreen extends StatefulWidget {
// //   const NearbyGymsScreen({super.key});

// //   @override
// //   _NearbyGymsPageState createState() => _NearbyGymsPageState();
// // }

// // class _NearbyGymsPageState extends State<NearbyGymsScreen> {
// //   List gyms = [];
// //   bool isLoading = true;
// //   bool isError = false;

// //   @override
// //   void initState() {
// //     super.initState();
// //     fetchGyms();
// //   }

// //   Future<List> getNearbyGyms(double lat, double lng) async {
// //     String apiKey = "AIzaSyARxZKnVqifuZ5dfGdEhRv41OcWdKKZyNo";  // 🔴 Replace with your Google API Key
// //     String url =
// //         "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lng&radius=5000&type=gym&key=$apiKey";

// //     final response = await http.get(Uri.parse(url));

// //     if (response.statusCode == 200) {
// //       var jsonData = jsonDecode(response.body);
// //       return jsonData['results'];
// //     } else {
// //       throw Exception("Failed to load nearby gyms");
// //     }
// //   }

// //   void fetchGyms() async {
// //     try {
// //       LocationPermission permission = await Geolocator.checkPermission();
// //       if (permission == LocationPermission.denied) {
// //         permission = await Geolocator.requestPermission();
// //         if (permission == LocationPermission.denied) {
// //           setState(() => isError = true);
// //           return;
// //         }
// //       }
// //       if (permission == LocationPermission.deniedForever) {
// //         setState(() => isError = true);
// //         return;
// //       }

// //       Position position = await Geolocator.getCurrentPosition(
// //           desiredAccuracy: LocationAccuracy.high);

// //       List gymList = await getNearbyGyms(position.latitude, position.longitude);

// //       setState(() {
// //         gyms = gymList;
// //         isLoading = false;
// //       });
// //     } catch (e) {
// //       print("Error: $e");
// //       setState(() {
// //         isError = true;
// //         isLoading = false;
// //       });
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(title: const Text("Nearby Gyms")),
// //       body: isLoading
// //           ? const Center(child: CircularProgressIndicator())
// //           : isError
// //               ? const Center(
// //                   child: Text("⚠️ Failed to fetch gyms. Check permissions."),
// //                 )
// //               : gyms.isEmpty
// //                   ? const Center(child: Text("No gyms found nearby. 🏋️‍♂️"))
// //                   : ListView.builder(
// //                       padding: const EdgeInsets.all(10),
// //                       itemCount: gyms.length,
// //                       itemBuilder: (context, index) {
// //                         var gym = gyms[index];
// //                         double? rating = gym['rating']?.toDouble();
// //                         String address = gym['vicinity'] ?? "No address available";

// //                         return Card(
// //                           margin: const EdgeInsets.symmetric(vertical: 8),
// //                           elevation: 3,
// //                           shape: RoundedRectangleBorder(
// //                             borderRadius: BorderRadius.circular(12),
// //                           ),
// //                           child: ListTile(
// //                             contentPadding: const EdgeInsets.all(12),
// //                             leading: const Icon(Icons.fitness_center, size: 40, color: Colors.blue),
// //                             title: Text(
// //                               gym['name'],
// //                               style: const TextStyle(
// //                                   fontWeight: FontWeight.bold, fontSize: 16),
// //                             ),
// //                             subtitle: Column(
// //                               crossAxisAlignment: CrossAxisAlignment.start,
// //                               children: [
// //                                 Text(address),
// //                                 if (rating != null)
// //                                   Row(
// //                                     children: [
// //                                       const Icon(Icons.star, color: Colors.amber, size: 18),
// //                                       const SizedBox(width: 4),
// //                                       Text("$rating ⭐"),
// //                                     ],
// //                                   ),
// //                               ],
// //                             ),
// //                           ),
// //                         );
// //                       },
// //                     ),
// //     );
// //   }
// // }

