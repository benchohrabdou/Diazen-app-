import 'package:flutter/material.dart';
import 'package:diazen/classes/activite.dart';
import 'package:diazen/classes/firestore_ops.dart';
import 'package:diazen/screens/activity_api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({Key? key}) : super(key: key);

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  final ActivityApiService _activityApiService = ActivityApiService();
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Timer? _debounce;

  bool _isBottomSheetOpen = false;
  bool _isLoading = false;
  String _errorMessage = '';
  double _userWeight = 70.0; // Default weight in kg

  // Activity search results
  List<Map<String, dynamic>> _searchResults = [];

  // Activity history
  List<Map<String, dynamic>> _activityHistory = [];

  // Date filter
  DateTime? _selectedDate;
  final TextEditingController _dateFilterController = TextEditingController();

  @override
  bool get wantKeepAlive => true; // Keep state when switching tabs

  @override
  void initState() {
    super.initState();
    _loadUserWeight();
    _loadActivityHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _dateFilterController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadUserWeight() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final User? currentUser = _auth.currentUser;

      if (currentUser != null) {
        final userDoc =
            await _firestoreService.getDocument('users', currentUser.uid);

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _userWeight = userData['poids'] ?? 70.0;
          });
        }
      }
    } catch (e) {
      print('Error loading user weight: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadActivityHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final User? currentUser = _auth.currentUser;

      if (currentUser != null) {
        print('Loading activities for user: ${currentUser.uid}');

        // Basic query - just get all activities for this user
        Query query = FirebaseFirestore.instance
            .collection('activities')
            .where('userId', isEqualTo: currentUser.uid);

        // Apply date filter if selected
        if (_selectedDate != null) {
          query = query.where('date',
              isEqualTo: DateFormat('yyyy-MM-dd').format(_selectedDate!));
        }

        // No sorting, just get all activities
        final QuerySnapshot activitiesSnapshot = await query.get();

        print('Found ${activitiesSnapshot.docs.length} activities');

        // Debug: Print all activities found
        for (var doc in activitiesSnapshot.docs) {
          print('Activity ID: ${doc.id}');
          print('Activity data: ${doc.data()}');
        }

        final List<Map<String, dynamic>> activities = [];

        for (var doc in activitiesSnapshot.docs) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            print('Processing activity: ${data['nom']}');

            // Handle different data types for cal30mn
            double calories = 0.0;
            if (data['cal30mn'] != null) {
              if (data['cal30mn'] is int) {
                calories = (data['cal30mn'] as int).toDouble();
              } else if (data['cal30mn'] is double) {
                calories = data['cal30mn'] as double;
              } else if (data['cal30mn'] is String) {
                calories = double.tryParse(data['cal30mn'] as String) ?? 0.0;
              }
            }

            // Store activity with date
            activities.add({
              'activity': Activite(
                nom: data['nom'] ?? 'Unknown Activity',
                cal30mn: calories,
                typeAct: data['typeAct'] ?? 'exercise',
              ),
              'date': data['date'] ?? 'Unknown Date',
              'time': data['time'] ?? 'Unknown Time',
              'duration': data['duration'] ?? 30,
              'docId': doc.id, // Store document ID for potential future use
            });
          } catch (e) {
            print('Error parsing activity: $e');
          }
        }

        print('Parsed ${activities.length} activities');

        setState(() {
          _activityHistory = activities;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading activity history: $e');
      print('Stack trace: ${StackTrace.current}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _searchActivities(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      // Only search if query has at least 2 characters
      if (query.length >= 2) {
        setState(() {
          _isLoading = true;
          _errorMessage = '';
        });

        _activityApiService
            .getCaloriesBurned(query, _userWeight)
            .then((results) {
          setState(() {
            _searchResults = results;
            _isLoading = false;
          });
        }).catchError((e) {
          setState(() {
            _errorMessage = 'Error searching for activities: $e';
            _searchResults = [];
            _isLoading = false;
          });
        });
      } else {
        setState(() {
          _searchResults = [];
        });
      }
    });
  }

  Future<void> _selectDateFilter(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4A7BF7),
              onPrimary: Colors.white,
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
        _dateFilterController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
      _loadActivityHistory();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDate = null;
      _dateFilterController.text = '';
    });
    _loadActivityHistory();
  }

  // Handle selection of existing activity from history
  void _selectExistingActivity(Map<String, dynamic> activityData) {
    final activity = activityData['activity'] as Activite;

    // Create a format that matches what the search results would return
    final formattedActivity = {
      'name': activity.nom,
      'caloriesPerHour': activity.cal30mn * 2, // Convert from 30min to hourly
      'caloriesPerMinute': activity.cal30mn / 30, // Convert to per minute
      'caloriesPer30Min': activity.cal30mn,
    };

    // Show confirmation dialog first
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF4A7BF7),
          title: const Text(
            'Reuse Activity',
            style: TextStyle(
              fontFamily: 'SfProDisplay',
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Do you want to add "${activity.nom}" again?',
            style: const TextStyle(
              fontFamily: 'SfProDisplay',
              color: Colors.white,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style:
                    TextStyle(fontFamily: 'SfProDisplay', color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showAddActivitySheet(formattedActivity);
              },
              child: const Text(
                "Add Activity",
                style:
                    TextStyle(fontFamily: 'SfProDisplay', color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddActivitySheet(Map<String, dynamic> activityData) async {
    setState(() => _isBottomSheetOpen = true);

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[200],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: _AddActivitySheet(
            activityName: activityData['name'],
            caloriesPerMinute: activityData['caloriesPerHour'] / 60,
          ),
        );
      },
    );

    setState(() => _isBottomSheetOpen = false);

    if (result != null) {
      // Create activity with the calculated calories
      final activity = Activite(
        nom: activityData['name'],
        cal30mn: result['calories'],
        typeAct: 'exercise', // Default type
      );

      // Save to Firestore
      try {
        final User? currentUser = _auth.currentUser;
        if (currentUser != null) {
          final uuid = Uuid();
          final activityId = uuid.v4();

          // Create timestamp from selected date and time
          final timestamp = DateTime(
            result['date'].year,
            result['date'].month,
            result['date'].day,
            result['time'].hour,
            result['time'].minute,
          );

          // Print debug information
          print('Saving activity: ${activity.nom}, ID: $activityId');
          print('User ID: ${currentUser.uid}');
          print('Timestamp: $timestamp');

          // Create activity data
          final activityData = {
            'id': activityId,
            'userId': currentUser.uid,
            'nom': activity.nom,
            'cal30mn': activity.cal30mn,
            'typeAct': activity.typeAct,
            'duration': result['minutes'],
            'date': DateFormat('yyyy-MM-dd').format(result['date']),
            'time': '${result['time'].hour}:${result['time'].minute}',
            'timestamp': Timestamp.fromDate(timestamp),
            'createdAt': FieldValue.serverTimestamp(), // Use server timestamp
          };

          print('Activity data to save: $activityData');

          // Save directly to Firestore
          await FirebaseFirestore.instance
              .collection('activities')
              .add(activityData);

          print('Activity saved successfully to Firestore');

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Activity saved successfully',
                style: TextStyle(fontFamily: 'SfProDisplay'),
              ),
              backgroundColor: Colors.green,
            ),
          );

          // Clear search results after adding activity
          setState(() {
            _searchResults = [];
            _searchController.clear();
          });

          // Add a small delay before refreshing
          await Future.delayed(const Duration(milliseconds: 1500));
          if (mounted) {
            print('Reloading activity history after save');
            _loadActivityHistory();
          }
        }
      } catch (e) {
        print('Error saving activity: $e');
        print('Stack trace: ${StackTrace.current}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving activity: $e',
              style: const TextStyle(fontFamily: 'SfProDisplay'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Activities'),
      ),
      body: Stack(
        children: [
          Opacity(
            opacity: _isBottomSheetOpen ? 0.3 : 1.0,
            child: AbsorbPointer(
              absorbing: _isBottomSheetOpen,
              child: SafeArea(
                child: Column(
                  children: [
                    // App Bar
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      color: Colors.white,
                      child: Row(
                        children: [
                          const Text(
                            'Activity',
                            style: TextStyle(
                              fontFamily: 'SfProDisplay',
                              color: Color(0xFF4A7BF7),
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                          const Spacer(),
                          if (_isLoading)
                            const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF4A7BF7),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Main Content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Search bar
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      decoration: const InputDecoration(
                                        hintText: 'Search for activity',
                                        hintStyle: TextStyle(
                                            fontFamily: 'SfProDisplay'),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12),
                                      ),
                                      onChanged: (value) {
                                        if (value.length > 2) {
                                          _searchActivities(value);
                                        } else if (value.isEmpty) {
                                          setState(() {
                                            _searchResults = [];
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  _isLoading
                                      ? const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        )
                                      : IconButton(
                                          icon: const Icon(Icons.search),
                                          onPressed: () => _searchActivities(
                                              _searchController.text),
                                        ),
                                ],
                              ),
                            ),

                            // Search results
                            if (_searchResults.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Search Results',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        fontFamily: 'SfProDisplay',
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxHeight:
                                            MediaQuery.of(context).size.height *
                                                0.3,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: ListView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const AlwaysScrollableScrollPhysics(),
                                            itemCount: _searchResults.length,
                                            itemBuilder: (context, index) {
                                              final activity =
                                                  _searchResults[index];
                                              return ListTile(
                                                title: Text(
                                                  activity['name'],
                                                  style: const TextStyle(
                                                    fontFamily: 'SfProDisplay',
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                subtitle: Text(
                                                  '${activity['caloriesPer30Min'].toStringAsFixed(0)} kcal / 30 min',
                                                  style: const TextStyle(
                                                    fontFamily: 'SfProDisplay',
                                                  ),
                                                ),
                                                trailing: SizedBox(
                                                  width: 40,
                                                  child: IconButton(
                                                    icon: const Icon(
                                                        Icons.add_circle,
                                                        color:
                                                            Color(0xFF4A7BF7)),
                                                    onPressed: () =>
                                                        _showAddActivitySheet(
                                                            activity),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            if (_errorMessage.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  _errorMessage,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontFamily: 'SfProDisplay',
                                  ),
                                ),
                              ),

                            const SizedBox(height: 16),

                            // Date filter
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'History',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    fontFamily: 'SfProDisplay',
                                  ),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      width: 130,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: GestureDetector(
                                        onTap: () => _selectDateFilter(context),
                                        child: AbsorbPointer(
                                          child: TextField(
                                            controller: _dateFilterController,
                                            decoration: const InputDecoration(
                                              hintText: 'Filter by date',
                                              hintStyle:
                                                  TextStyle(fontSize: 12),
                                              border: InputBorder.none,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      vertical: 10),
                                              suffixIcon: Icon(
                                                  Icons.calendar_today,
                                                  size: 16),
                                            ),
                                            style:
                                                const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (_selectedDate != null)
                                      IconButton(
                                        icon: const Icon(Icons.clear, size: 16),
                                        onPressed: _clearDateFilter,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Activity history list
                            Expanded(
                              child: _activityHistory.isEmpty && !_isLoading
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.directions_run,
                                            size: 48,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            _selectedDate != null
                                                ? 'No activities found for ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}'
                                                : 'No activities found',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontFamily: 'SfProDisplay',
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Try a different date or add a new activity',
                                            style: TextStyle(
                                              color: Colors.grey[500],
                                              fontFamily: 'SfProDisplay',
                                              fontSize: 12,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    )
                                  : RefreshIndicator(
                                      onRefresh: _loadActivityHistory,
                                      child: ListView.builder(
                                        itemCount: _activityHistory.length,
                                        itemBuilder: (context, index) {
                                          final activityData =
                                              _activityHistory[index];
                                          final act = activityData['activity']
                                              as Activite;
                                          final date =
                                              activityData['date'] as String;
                                          final time =
                                              activityData['time'] as String;

                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 12.0),
                                            child: GestureDetector(
                                              onTap: () =>
                                                  _selectExistingActivity(
                                                      activityData),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFF4A7BF7),
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.1),
                                                      blurRadius: 4,
                                                      offset:
                                                          const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                padding:
                                                    const EdgeInsets.all(16),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child: Text(
                                                                  act.nom,
                                                                  style:
                                                                      const TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontFamily:
                                                                        'SfProDisplay',
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        16,
                                                                  ),
                                                                ),
                                                              ),
                                                              IconButton(
                                                                icon:
                                                                    const Icon(
                                                                  Icons
                                                                      .delete_outline,
                                                                  color: Colors
                                                                      .white70,
                                                                ),
                                                                onPressed:
                                                                    () async {
                                                                  // Show confirmation dialog
                                                                  final shouldDelete =
                                                                      await showDialog<
                                                                          bool>(
                                                                    context:
                                                                        context,
                                                                    builder:
                                                                        (context) =>
                                                                            AlertDialog(
                                                                      title:
                                                                          const Text(
                                                                        'Delete Activity',
                                                                        style:
                                                                            TextStyle(
                                                                          fontFamily:
                                                                              'SfProDisplay',
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                        ),
                                                                      ),
                                                                      content:
                                                                          Text(
                                                                        'Are you sure you want to delete "${act.nom}"?',
                                                                        style:
                                                                            const TextStyle(
                                                                          fontFamily:
                                                                              'SfProDisplay',
                                                                        ),
                                                                      ),
                                                                      actions: [
                                                                        TextButton(
                                                                          onPressed: () => Navigator.pop(
                                                                              context,
                                                                              false),
                                                                          child:
                                                                              const Text('Cancel'),
                                                                        ),
                                                                        TextButton(
                                                                          onPressed: () => Navigator.pop(
                                                                              context,
                                                                              true),
                                                                          child:
                                                                              const Text(
                                                                            'Delete',
                                                                            style:
                                                                                TextStyle(color: Colors.red),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  );

                                                                  if (shouldDelete ==
                                                                      true) {
                                                                    try {
                                                                      await FirebaseFirestore
                                                                          .instance
                                                                          .collection(
                                                                              'activities')
                                                                          .doc(activityData[
                                                                              'docId'])
                                                                          .delete();
                                                                      // Refresh the activity history
                                                                      _loadActivityHistory();
                                                                      if (mounted) {
                                                                        ScaffoldMessenger.of(context)
                                                                            .showSnackBar(
                                                                          const SnackBar(
                                                                            content:
                                                                                Text(
                                                                              'Activity deleted successfully',
                                                                              style: TextStyle(fontFamily: 'SfProDisplay'),
                                                                            ),
                                                                            backgroundColor:
                                                                                Colors.green,
                                                                          ),
                                                                        );
                                                                      }
                                                                    } catch (e) {
                                                                      if (mounted) {
                                                                        ScaffoldMessenger.of(context)
                                                                            .showSnackBar(
                                                                          SnackBar(
                                                                            content:
                                                                                Text(
                                                                              'Error deleting activity: $e',
                                                                              style: const TextStyle(fontFamily: 'SfProDisplay'),
                                                                            ),
                                                                            backgroundColor:
                                                                                Colors.red,
                                                                          ),
                                                                        );
                                                                      }
                                                                    }
                                                                  }
                                                                },
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                              height: 4),
                                                          // Add date and time
                                                          Row(
                                                            children: [
                                                              const Icon(
                                                                Icons
                                                                    .calendar_today,
                                                                color: Colors
                                                                    .white,
                                                                size: 14,
                                                              ),
                                                              const SizedBox(
                                                                  width: 4),
                                                              Text(
                                                                '$date - $time',
                                                                style:
                                                                    const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontFamily:
                                                                      'SfProDisplay',
                                                                  fontSize: 12,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Column(
                                                      children: [
                                                        Container(
                                                          decoration:
                                                              const BoxDecoration(
                                                            color: Colors.white,
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                          child: const Icon(
                                                              Icons.check,
                                                              color: Color(
                                                                  0xFF4A7BF7)),
                                                        ),
                                                        const SizedBox(
                                                            height: 8),
                                                        const Icon(
                                                          Icons.touch_app,
                                                          color: Colors.white70,
                                                          size: 16,
                                                        ),
                                                        const Text(
                                                          'Tap to reuse',
                                                          style: TextStyle(
                                                            color:
                                                                Colors.white70,
                                                            fontSize: 10,
                                                            fontFamily:
                                                                'SfProDisplay',
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                            ),

                            // "Add Activity" button - only show if no search results
                            if (_searchResults.isEmpty)
                              // Add padding to fix overflow
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Container(
                                  width: double.infinity,
                                  constraints:
                                      const BoxConstraints(minHeight: 50),
                                  child: GestureDetector(
                                    onTap: () async {
                                      final commonActivities =
                                          await _activityApiService
                                              .getCommonActivities();
                                      if (!mounted) return;
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text(
                                            'Common Activities',
                                            style: TextStyle(
                                              fontFamily: 'SfProDisplay',
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          content: SizedBox(
                                            width: double.maxFinite,
                                            child: ListView.builder(
                                              shrinkWrap: true,
                                              itemCount:
                                                  commonActivities.length,
                                              itemBuilder: (context, index) {
                                                return ListTile(
                                                  title: Text(
                                                    commonActivities[index],
                                                    style: const TextStyle(
                                                      fontFamily:
                                                          'SfProDisplay',
                                                    ),
                                                  ),
                                                  onTap: () {
                                                    _searchController.text =
                                                        commonActivities[index];
                                                    _searchActivities(
                                                        commonActivities[
                                                            index]);
                                                    Navigator.pop(context);
                                                  },
                                                );
                                              },
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text(
                                                'Cancel',
                                                style: TextStyle(
                                                  fontFamily: 'SfProDisplay',
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16, horizontal: 24),
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add, color: Colors.black),
                                          SizedBox(width: 8),
                                          Text(
                                            'Add Activity',
                                            style: TextStyle(
                                              fontFamily: 'SfProDisplay',
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Bottom Sheet for adding activity
class _AddActivitySheet extends StatefulWidget {
  final String activityName;
  final double caloriesPerMinute;

  const _AddActivitySheet({
    required this.activityName,
    required this.caloriesPerMinute,
  });

  @override
  State<_AddActivitySheet> createState() => _AddActivitySheetState();
}

class _AddActivitySheetState extends State<_AddActivitySheet> {
  late TextEditingController _minutesController;
  late TextEditingController _dateController;
  late TextEditingController _timeController;

  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _minutesController = TextEditingController(text: '30');
    _dateController = TextEditingController(
        text: DateFormat('yyyy-MM-dd').format(selectedDate));
    // Initialize without context
    _timeController = TextEditingController();

    // Set the time text after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _timeController.text = selectedTime.format(context);
        });
      }
    });
  }

  @override
  void dispose() {
    _minutesController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4A7BF7),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(selectedDate);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4A7BF7),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            timePickerTheme: const TimePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedTime = picked;
        _timeController.text = selectedTime.format(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                widget.activityName,
                style: const TextStyle(
                  fontFamily: 'SfProDisplay',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minutesController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '30',
                    hintStyle: const TextStyle(fontFamily: 'SfProDisplay'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              const Text('Minutes',
                  style: TextStyle(fontFamily: 'SfProDisplay', fontSize: 16)),
              const Spacer(),
              const Icon(Icons.local_fire_department, color: Colors.black),
              const SizedBox(width: 4),
              Text(
                () {
                  int minutes = int.tryParse(_minutesController.text) ?? 30;
                  double totalCalories = widget.caloriesPerMinute * minutes;
                  return '${totalCalories.toStringAsFixed(0)} Kcal';
                }(),
                style: const TextStyle(
                  fontFamily: 'SfProDisplay',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Date selection
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Date',
                style: TextStyle(
                  fontFamily: 'SfProDisplay',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _selectDate(context),
            child: AbsorbPointer(
              child: TextField(
                controller: _dateController,
                readOnly: true,
                decoration: InputDecoration(
                  hintText: 'Select date',
                  hintStyle: const TextStyle(
                    fontFamily: 'SfProDisplay',
                    color: Colors.black54,
                  ),
                  filled: true,
                  fillColor: Colors.grey[300],
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Time selection
          Row(
            children: [
              const Icon(Icons.access_time, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Time',
                style: TextStyle(
                  fontFamily: 'SfProDisplay',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _selectTime(context),
            child: AbsorbPointer(
              child: TextField(
                controller: _timeController,
                readOnly: true,
                decoration: InputDecoration(
                  hintText: 'Select time',
                  hintStyle: const TextStyle(
                    fontFamily: 'SfProDisplay',
                    color: Colors.black54,
                  ),
                  filled: true,
                  fillColor: Colors.grey[300],
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A7BF7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                int minutes = int.tryParse(_minutesController.text) ?? 30;
                double totalCalories = widget.caloriesPerMinute * minutes;
                Navigator.pop(context, {
                  'minutes': minutes,
                  'calories': totalCalories,
                  'date': selectedDate,
                  'time': selectedTime,
                });
              },
              child: const Text(
                'Add activity',
                style: TextStyle(
                  fontFamily: 'SfProDisplay',
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
