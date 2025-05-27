import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';
// Import Activite class if needed for the list, but it might be stored as a map
// import 'package:diazen/classes/activite.dart';

// Define a GlobalKey for the ActivityHistoryScreenState
// We might not need this key anymore with the new approach, but let's keep it for now.
// final GlobalKey<_ActivityHistoryScreenState> activityHistoryScreenKey = GlobalKey<_ActivityHistoryScreenState>(); // This key is no longer needed

class ActivityHistoryScreen extends StatefulWidget {
  // Remove selectedIndex parameter as we will listen to auth state changes
  // final int selectedIndex;
  const ActivityHistoryScreen({super.key});

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> with AutomaticKeepAliveClientMixin<ActivityHistoryScreen> { // Use AutomaticKeepAliveClientMixin
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  String _errorMessage = '';
  List<Map<String, dynamic>> _activityHistory = []; // Use _activityHistory like in ActivityScreen
  DateTime? _selectedDate; // Add state variable for selected date

  StreamSubscription? _authStateSubscription;
  StreamSubscription? _activityStreamSubscription; // Stream subscription for activities

  @override
  bool get wantKeepAlive => true; // Keep state when switching tabs

  @override
  void initState() {
    super.initState();
    // Listen to auth state changes to load data when user is available
    _authStateSubscription = _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        print('ActivityHistoryScreen: Auth state changed - User is logged in. Starting activity stream...'); // Debug print
        _subscribeToActivityStream(); // Start stream instead of one-time load
      } else {
         print('ActivityHistoryScreen: Auth state changed - User is logged out. Clearing activities.'); // Debug print
         _activityStreamSubscription?.cancel(); // Cancel stream if user logs out
         setState(() {
           _activityHistory = []; // Clear activities if user logs out
           _isLoading = false;
           _errorMessage = 'Please log in to view activity history.';
         });
      }
    });
     // Initial load in case user is already logged in when the screen is created
    if (_auth.currentUser != null) {
       print('ActivityHistoryScreen: User already logged in, attempting to start stream.');
       _subscribeToActivityStream();
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel(); // Cancel auth stream
    _activityStreamSubscription?.cancel(); // Cancel activity stream
    super.dispose();
  }

  void _subscribeToActivityStream() { // New function to subscribe to the stream
     final User? currentUser = _auth.currentUser;

    if (currentUser == null || currentUser.uid.isEmpty) {
       print('ActivityHistoryScreen _subscribeToActivityStream: currentUser or uid is null/empty. Cannot start stream.');
       setState(() {
         _errorMessage = 'User not logged in or user ID is not available.';
         _isLoading = false;
       });
       return;
    }

    setState(() { _isLoading = true; _errorMessage = ''; });

    print('ActivityHistoryScreen _subscribeToActivityStream: Attempting to subscribe to Firestore stream for user ${currentUser.uid}...'); // Debug print

    // Cancel previous subscription if any
    _activityStreamSubscription?.cancel();

    // Subscribe to the stream of activity data
    _activityStreamSubscription = _firestore
        .collection('activities')
        .where('userId', isEqualTo: currentUser.uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            print('ActivityHistoryScreen stream listener: Received ${snapshot.docs.length} documents.'); // Debug print
            final List<Map<String, dynamic>> loadedActivities = [];

            for (var doc in snapshot.docs) {
               try {
                 final data = doc.data() as Map<String, dynamic>;
                  // print('ActivityHistoryScreen stream listener: Processing activity doc: ${doc.id} - ${data['nom']}'); // Debug print per doc

                 final String? name = data['nom'] as String?;
                 final dynamic durationRaw = data['duration'];
                 final dynamic caloriesRaw = data['cal30mn'];
                 final dynamic timestampRaw = data['timestamp'];

                 double duration = 0.0;
                 if (durationRaw != null) {
                    if (durationRaw is num) duration = durationRaw.toDouble();
                    else if (durationRaw is String) duration = double.tryParse(durationRaw) ?? 0.0;
                 }

                  double calories = 0.0;
                 if (caloriesRaw != null) {
                    if (caloriesRaw is num) calories = caloriesRaw.toDouble();
                    else if (caloriesRaw is String) calories = double.tryParse(caloriesRaw) ?? 0.0;
                 }

                  DateTime? timestamp;
                  if (timestampRaw is String) {
                    try { timestamp = DateTime.parse(timestampRaw); } catch (e) { print('ActivityHistoryScreen stream listener: Error parsing timestamp string ${timestampRaw}: $e'); }
                  } else if (timestampRaw is Timestamp) {
                    timestamp = timestampRaw.toDate();
                  }

                 if (name != null && duration >= 0 && calories >= 0 && timestamp != null) {
                    loadedActivities.add({
                      'id': doc.id,
                      'name': name,
                      'duration': duration,
                      'calories': calories,
                      'timestamp': timestamp,
                    });
                 } else {
                    print('ActivityHistoryScreen stream listener: Skipping activity doc ${doc.id} due to missing or invalid fields: $data');
                 }
               } catch (e) {
                 print('ActivityHistoryScreen stream listener: Error parsing activity doc ${doc.id}: $e');
               }
            }

            print('ActivityHistoryScreen stream listener: Loaded ${loadedActivities.length} activity logs from stream.'); // Debug print
            setState(() {
              _activityHistory = loadedActivities;
              _isLoading = false;
              _errorMessage = ''; // Clear error on successful load
            });
          },
          onError: (error) {
            print('ActivityHistoryScreen stream listener: Error receiving activity data: $error'); // Debug print
            setState(() {
              _errorMessage = 'Error loading activity history: $error';
              _isLoading = false;
            });
          },
           cancelOnError: true, // Cancel subscription on error
        );
  }

   Future<void> _refreshActivityHistory() async { // Function for the refresh button
     print('ActivityHistoryScreen _refreshActivityHistory: Manual refresh triggered.');
     // The stream listener will automatically pick up changes, but we can re-subscribe or just ensure the stream is active
     // A simple way is to just re-run the subscription logic
     _subscribeToActivityStream();
   }


  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Activity History',
          style: TextStyle(
            color: Color(0xFF4A7BF7),
            fontFamily: 'SfProDisplay',
            fontWeight: FontWeight.bold,
          ),
        ),
         // Remove leading back button as it's in the bottom nav
         // leading: IconButton(
         //   icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF4A7BF7)),
         //   onPressed: () => Navigator.pop(context),
         // ),
         actions: [ // Add refresh button
           IconButton(
             icon: const Icon(Icons.refresh, color: Color(0xFF4A7BF7)),
             onPressed: _refreshActivityHistory,
           ),
           // Add date picker button
           IconButton(
             icon: const Icon(Icons.calendar_today, color: Color(0xFF4A7BF7)),
             onPressed: () async {
               final DateTime? picked = await showDatePicker(
                 context: context,
                 initialDate: _selectedDate ?? DateTime.now(),
                 firstDate: DateTime(2020),
                 lastDate: DateTime.now(),
                 builder: (context, child) {
                   return Theme(
                     data: Theme.of(context).copyWith(
                       colorScheme: const ColorScheme.light(
                         primary: Color(0xFF4A7BF7),
                         onPrimary: Colors.white,
                         surface: Colors.white,
                         onSurface: Colors.black,
                       ),
                     ),
                     child: child!,
                   );
                 },
               );
               if (picked != null) {
                 setState(() {
                   _selectedDate = picked;
                 });
               }
             },
           ),
         ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A7BF7)),
              ),
            )
          : _activityHistory.isEmpty
              ? Center( // Display message when no activities are found
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.directions_run,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No activity logged yet',
                        style: TextStyle(
                          fontFamily: 'SfProDisplay',
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _activityHistory.length,
                  itemBuilder: (context, index) {
                    final activity = _activityHistory[index];
                    // print('Rendering activity: ${activity['name']}'); // Debug print

                    // Format date and time from DateTime object
                    final DateTime? timestamp = activity['timestamp'] as DateTime?;
                    
                    // Filter by selected date if one is selected
                    if (_selectedDate != null) {
                      if (timestamp == null ||
                          timestamp.year != _selectedDate!.year ||
                          timestamp.month != _selectedDate!.month ||
                          timestamp.day != _selectedDate!.day) {
                        return const SizedBox.shrink(); // Hide if not the selected date
                      }
                    }

                    final String formattedDate = timestamp != null ? DateFormat('MMM dd, yyyy').format(timestamp) : 'N/A';
                    final String formattedTime = timestamp != null ? DateFormat('h:mm a').format(timestamp) : 'N/A';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      elevation: 2.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      color: const Color(0xFF4A7BF7), // Set card color to blue
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity['name'] ?? 'Unnamed Activity',
                              style: const TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'SfProDisplay',
                                color: Colors.white, // Set text color to white
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              'Duration: ${activity['duration'] ?? 'N/A'}',
                              style: const TextStyle(
                                fontSize: 16.0,
                                fontFamily: 'SfProDisplay',
                                color: Colors.white70, // Slightly less opaque white for details
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              'Calories: ${activity['calories'] != null ? activity['calories'].round() : 'N/A'}',
                              style: const TextStyle(
                                fontSize: 16.0,
                                fontFamily: 'SfProDisplay',
                                color: Colors.white70, // Slightly less opaque white for details
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              '$formattedDate at $formattedTime',
                              style: const TextStyle(
                                fontSize: 14.0,
                                fontFamily: 'SfProDisplay',
                                color: Colors.white60, // Even less opaque white for date/time
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
} 