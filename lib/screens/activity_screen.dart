import 'package:flutter/material.dart';
import 'package:diazen/classes/activite.dart';
import 'package:diazen/classes/firestore_ops.dart';
import 'package:diazen/screens/activity_api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({Key? key}) : super(key: key);

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
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
  List<Activite> _activityHistory = [];
  DocumentSnapshot? _lastDocument;
  bool _hasMoreActivities = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadUserWeight();
    _loadActivityHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
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

  Future<void> _loadActivityHistory({bool loadMore = false}) async {
    if (loadMore && (!_hasMoreActivities || _isLoadingMore)) return;

    setState(() {
      if (!loadMore) _isLoading = true;
      if (loadMore) _isLoadingMore = true;
    });

    try {
      final User? currentUser = _auth.currentUser;

      if (currentUser != null) {
        Query query = FirebaseFirestore.instance
            .collection('activities')
            .where('userId', isEqualTo: currentUser.uid)
            .orderBy('timestamp', descending: true)
            .limit(10);

        if (loadMore && _lastDocument != null) {
          query = query.startAfterDocument(_lastDocument!);
        }

        final activitiesSnapshot = await query.get();

        if (activitiesSnapshot.docs.isEmpty) {
          setState(() {
            _hasMoreActivities = false;
          });
          return;
        }

        _lastDocument = activitiesSnapshot.docs.last;

        final activities = activitiesSnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Activite(
            nom: data['nom'],
            cal30mn: data['cal30mn'],
            typeAct: data['typeAct'],
          );
        }).toList();

        setState(() {
          if (loadMore) {
            _activityHistory.addAll(activities);
          } else {
            _activityHistory = activities;
          }
        });
      }
    } catch (e) {
      print('Error loading activity history: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
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

      // Add to local list
      setState(() {
        _activityHistory.add(activity);
      });

      // Save to Firestore
      try {
        final User? currentUser = _auth.currentUser;
        if (currentUser != null) {
          final uuid = Uuid();
          final activityId = uuid.v4();

          // Create timestamp for the selected time today
          final now = DateTime.now();
          TimeOfDay activityTime = result['time'] ?? TimeOfDay.now();
          final timestamp = DateTime(
            now.year,
            now.month,
            now.day,
            activityTime.hour,
            activityTime.minute,
          );

          await _firestoreService.addDocument('activities', {
            'id': activityId,
            'userId': currentUser.uid,
            'nom': activity.nom,
            'cal30mn': activity.cal30mn,
            'typeAct': activity.typeAct,
            'duration': result['minutes'],
            'time': '${activityTime.hour}:${activityTime.minute}',
            'timestamp': timestamp.toIso8601String(),
            'createdAt': DateTime.now().toIso8601String(),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Activity saved successfully')),
          );

          // Refresh activity history
          _loadActivityHistory();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving activity: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // IMPORTANT: We're not creating a new Scaffold here
    // This preserves the parent Scaffold that contains the bottom navigation bar
    return Stack(
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                      hintStyle:
                                          TextStyle(fontFamily: 'SfProDisplay'),
                                      border: InputBorder.none,
                                      contentPadding:
                                          EdgeInsets.symmetric(horizontal: 12),
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
                                                overflow: TextOverflow.ellipsis,
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
                                                      color: Color(0xFF4A7BF7)),
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
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),

                          const SizedBox(height: 16),

                          // Title "History"
                          const Text(
                            'History',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              fontFamily: 'SfProDisplay',
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Activity history list
                          Expanded(
                            child: _activityHistory.isEmpty
                                ? Center(
                                    child: Text(
                                      'No activities yet',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontFamily: 'SfProDisplay',
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _activityHistory.length +
                                        (_hasMoreActivities ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      if (index == _activityHistory.length) {
                                        if (!_isLoadingMore) {
                                          _loadActivityHistory(loadMore: true);
                                        }
                                        return const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      }

                                      final act = _activityHistory[index];
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 12.0),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF4A7BF7),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      act.nom,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                        fontFamily:
                                                            'SfProDisplay',
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        const Icon(
                                                          Icons
                                                              .local_fire_department,
                                                          color: Colors.white,
                                                          size: 16,
                                                        ),
                                                        const SizedBox(
                                                            width: 4),
                                                        Text(
                                                          '${act.cal30mn.toInt()} Kcal',
                                                          style:
                                                              const TextStyle(
                                                            color: Colors.white,
                                                            fontFamily:
                                                                'SfProDisplay',
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 10),
                                                        const Text('.',
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white)),
                                                        const SizedBox(
                                                            width: 6),
                                                        Text(
                                                          '30 min',
                                                          style:
                                                              const TextStyle(
                                                            color: Colors.white,
                                                            fontFamily:
                                                                'SfProDisplay',
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                decoration: const BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.check,
                                                    color: Color(0xFF4A7BF7)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),

                          // "Add Activity" button - only show if no search results
                          if (_searchResults.isEmpty)
                            Container(
                              width: double.infinity,
                              constraints: const BoxConstraints(minHeight: 50),
                              child: GestureDetector(
                                onTap: () async {
                                  final commonActivities =
                                      await _activityApiService
                                          .getCommonActivities();
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Common Activities'),
                                      content: SizedBox(
                                        width: double.maxFinite,
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: commonActivities.length,
                                          itemBuilder: (context, index) {
                                            return ListTile(
                                              title:
                                                  Text(commonActivities[index]),
                                              onTap: () {
                                                _searchController.text =
                                                    commonActivities[index];
                                                _searchActivities(
                                                    commonActivities[index]);
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
                                          child: const Text('Cancel'),
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
                                    mainAxisAlignment: MainAxisAlignment.center,
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
  TimeOfDay? selectedTime;

  @override
  void initState() {
    super.initState();
    _minutesController = TextEditingController(text: '30');
    selectedTime = TimeOfDay.now(); // Default to current time
  }

  @override
  void dispose() {
    _minutesController.dispose();
    super.dispose();
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
            onTap: () async {
              final TimeOfDay? picked = await showTimePicker(
                context: context,
                initialTime: selectedTime ?? TimeOfDay.now(),
                builder: (BuildContext context, Widget? child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Color(0xFF4A7BF7),
                        onPrimary: Colors.white,
                        onSurface: Colors.black,
                      ),
                      timePickerTheme: TimePickerThemeData(
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
                });
              }
            },
            child: AbsorbPointer(
              child: TextField(
                readOnly: true,
                decoration: InputDecoration(
                  hintText: selectedTime != null
                      ? selectedTime!.format(context)
                      : 'Select time',
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
