// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:http/http.dart' as http;
// import 'package:permission_handler/permission_handler.dart';

// class NearbyGymsScreen extends StatefulWidget {
//   const NearbyGymsScreen({super.key});

//   @override
//   _NearbyGymsScreenState createState() => _NearbyGymsScreenState();
// }

// class _NearbyGymsScreenState extends State<NearbyGymsScreen> {
//   GoogleMapController? _mapController;
//   Position? _currentPosition;
//   List<Marker> _markers = [];
//   final String _googleApiKey = "AIzaSyC_eBpw_knStd2kTHAmueEALpWOoI5BaAo";  // Replace with your actual API key

//   @override
//   void initState() {
//     super.initState();
//     _requestLocationPermission();
//   }

//   Future<void> _requestLocationPermission() async {
//     PermissionStatus status = await Permission.location.request();
//     if (status.isGranted) {
//       _getCurrentLocation();
//     } else {
//       setState(() {
//         _currentPosition = null;
//       });
//     }
//   }

//   Future<void> _getCurrentLocation() async {
//     try {
//       Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );
//       setState(() {
//         _currentPosition = position;
//       });

//       _fetchNearbyGyms(position.latitude, position.longitude);
//     } catch (e) {
//       print("Error getting location: $e");
//     }
//   }

//   Future<void> _fetchNearbyGyms(double lat, double lon) async {
//     final String url = 'https://places.googleapis.com/v1/places:searchNearby';
//     final Map<String, dynamic> requestData = {
//       "location": {
//         "latitude": lat,
//         "longitude": lon
//       },
//       "radius": 5000,
//       "type": "gym",
//       "key": _googleApiKey,
//     };

//     try {
//       final response = await http.post(
//         Uri.parse(url),
//         headers: {
//           'Content-Type': 'application/json',
//         },
//         body: json.encode(requestData),
//       );

//       if (response.statusCode == 200) {
      
//         if (response.body.isNotEmpty) {
//           final data = json.decode(response.body);

//           if (data != null && data['results'] != null) {
//             List results = data['results'];
//             print(results);

//             setState(() {
//               _markers = results.map((gym) {
//                 final String gymName = gym['name'] ?? 'Unnamed Gym';
//                 final double latitude = gym['geometry']['location']['lat'];
//                 final double longitude = gym['geometry']['location']['lng'];
//                 final String photoUrl = gym['photos'] != null && gym['photos'].isNotEmpty
//                     ? 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=${gym['photos'][0]['photo_reference']}&key=$_googleApiKey'
//                     : '';

//                 return Marker(
//                   markerId: MarkerId(gym['place_id']),
//                   position: LatLng(latitude, longitude),
//                   infoWindow: InfoWindow(
//                     title: gymName,
//                     snippet: gym['vicinity'],
//                   ),
//                   icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
//                 );
//               }).toList();
//             });
//           } else {
//             print("No places found in the response.");
//           }
//         } else {
//           print("Empty response body.");
//         }
//       } else {
//         print("Failed to fetch gyms: ${response.statusCode}, ${response.body}");
//       }
//     } catch (e) {
//       print("Error fetching gyms: $e");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Nearby Gyms (Google Places API)")),
//       body: _currentPosition == null
//           ? const Center(child: CircularProgressIndicator())
//           : GoogleMap(
//               initialCameraPosition: CameraPosition(
//                 target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
//                 zoom: 14,
//               ),
//               onMapCreated: (GoogleMapController controller) {
//                 _mapController = controller;
//               },
//               markers: {
//                 if (_currentPosition != null)
//                   Marker(
//                     markerId: const MarkerId("current_location"),
//                     position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
//                     infoWindow: const InfoWindow(title: "You are here"),
//                     icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
//                   ),
//                 ..._markers,
//               },
//             ),
//     );
//   }
// }



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

//   @override
//   void initState() {
//     super.initState();
//     fetchNearbyGyms();
//   }

//   Future<void> fetchNearbyGyms() async {
//     Position position = await _determinePosition();
//     String golangApiUrl =
//         "http://localhost:8080/getNearbyGyms?lat=${position.latitude}&lng=${position.longitude}";

//     final response = await http.get(Uri.parse(golangApiUrl));

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       setState(() {
//         gyms = data["results"].take(10).toList(); // Limit to 10 gyms
//       });
//     } else {
//       throw Exception("Failed to load gyms");
//     }
//   }

//   Future<Position> _determinePosition() async {
//     bool serviceEnabled;
//     LocationPermission permission;

//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       return Future.error('Location services are disabled.');
//     }

//     permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         return Future.error('Location permissions are denied');
//       }
//     }

//     if (permission == LocationPermission.deniedForever) {
//       return Future.error(
//           'Location permissions are permanently denied, we cannot request permissions.');
//     }

//     return await Geolocator.getCurrentPosition();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Nearby Gyms")),
//       body: gyms.isEmpty
//           ? const Center(child: CircularProgressIndicator())
//           : ListView.builder(
//               itemCount: gyms.length,
//               itemBuilder: (context, index) {
//                 var gym = gyms[index];
//                 String phone = gym["formatted_phone_number"] ?? "No phone available";
//                 double? rating = gym["rating"]?.toDouble();
//                 return Card(
//                   margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//                   elevation: 3,
//                   child: ListTile(
//                     title: Text(
//                       gym["name"],
//                       style: const TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     subtitle: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(gym["vicinity"]),
//                         if (rating != null) Text("⭐ Rating: $rating"),
//                         // Text("📞 $phone"),
//                       ],
//                     ),
//                     leading: const Icon(Icons.fitness_center, size: 40, color: Colors.blue),
//                   ),
//                 );
//               },
//             ),
//     );
//   }
// }

