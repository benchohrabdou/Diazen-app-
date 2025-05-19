import 'package:flutter/material.dart';
import 'package:diazen/classes/activite.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({Key? key}) : super(key: key);

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isBottomSheetOpen = false;

  // 🔹 Liste des activités ajoutées dynamiquement
  final List<Activite> _activityHistory = [];

  // 🔹 Activité exemple
  final Activite selectedActivity = Activite(
    nom: 'Cleaning',
    cal30mn: 107.0,
    typeAct: 'house',
  );

  void _showAddActivitySheet(Activite activity) async {
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
          child: _AddActivitySheet(activity: activity),
        );
      },
    );
    setState(() => _isBottomSheetOpen = false);

    if (result != null) {
      // Ajouter l'activité avec la durée et les kcal calculés
      final updatedActivity = Activite(
        nom: activity.nom,
        cal30mn: result['calories'], // kcal réel selon durée
        typeAct: activity.typeAct,
      );
      _activityHistory.add(updatedActivity);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Opacity(
          opacity: _isBottomSheetOpen ? 0.3 : 1.0,
          child: AbsorbPointer(
            absorbing: _isBottomSheetOpen,
            child: Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                title: const Text(
                  'Activity',
                  style: TextStyle(
                    fontFamily: 'SfProDisplay',
                    color: Color(0xFF4A7BF7),
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ),
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Barre de recherche
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
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Titre "History"
                    const Text(
                      'History',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: 'SfProDisplay',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Liste dynamique
                    Expanded(
                      child: ListView.builder(
                        itemCount: _activityHistory.length,
                        itemBuilder: (context, index) {
                          final act = _activityHistory[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF4A7BF7),
                                borderRadius: BorderRadius.circular(16),
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
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            fontFamily: 'SfProDisplay',
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.local_fire_department,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${act.cal30mn.toInt()} Kcal',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontFamily: 'SfProDisplay'),
                                            ),
                                            const SizedBox(width: 10),
                                            const Text('.',
                                                style: TextStyle(
                                                    color: Colors.white)),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${(act.cal30mn / (selectedActivity.cal30mn / 30)).toInt()} min',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontFamily: 'SfProDisplay'),
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

                    // Bouton "Ajouter une activité"
                    GestureDetector(
                      onTap: () => _showAddActivitySheet(selectedActivity),
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
                            Text('Add Activity',
                                style: TextStyle(
                                    fontFamily: 'SfProDisplay',
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Bottom Sheet dynamique
class _AddActivitySheet extends StatefulWidget {
  final Activite activity;

  const _AddActivitySheet({required this.activity});

  @override
  State<_AddActivitySheet> createState() => _AddActivitySheetState();
}

class _AddActivitySheetState extends State<_AddActivitySheet> {
  late TextEditingController _minutesController;

  @override
  void initState() {
    super.initState();
    _minutesController = TextEditingController(text: '30');
  }

  @override
  void dispose() {
    _minutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double caloriesPerMinute = widget.activity.cal30mn / 30;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(widget.activity.nom,
                  style: const TextStyle(
                      fontFamily: 'SfProDisplay',
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
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
                        borderRadius: BorderRadius.circular(12)),
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
                  double totalCalories = caloriesPerMinute * minutes;
                  return '${totalCalories.toStringAsFixed(0)} Kcal';
                }(),
                style: const TextStyle(
                    fontFamily: 'SfProDisplay',
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[700],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                int minutes = int.tryParse(_minutesController.text) ?? 30;
                double totalCalories = caloriesPerMinute * minutes;
                Navigator.pop(context, {
                  'minutes': minutes,
                  'calories': totalCalories
                });
              },
              child: const Text('Add activity',
                  style: TextStyle(
                      fontFamily: 'SfProDisplay',
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
