import 'package:flutter/material.dart';

import 'exercise_detail_screen.dart';

class ExerciseHistoryScreen extends StatefulWidget {
  const ExerciseHistoryScreen({super.key});

  @override
  State<ExerciseHistoryScreen> createState() => _ExerciseHistoryScreenState();
}

class _ExerciseHistoryScreenState extends State<ExerciseHistoryScreen> {
  static const Color primaryBlue = Color(0xFF1555C0);
  static const Color darkText = Color(0xFF0B1B4D);
  static const Color greyText = Color(0xFF667085);

  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'Gym';

  final List<Map<String, String>> _allExercises = [
    {
      'name': 'Bench Press',
      'category': 'Gym',
      'lastLogged': 'Last logged 2 days ago',
      'details': '30 kg × 10 reps × 3 sets',
    },
    {
      'name': 'Squats',
      'category': 'Gym',
      'lastLogged': 'Last logged 3 days ago',
      'details': '40 kg × 8 reps × 3 sets',
    },
    {
      'name': 'Push-ups',
      'category': 'Calisthenics',
      'lastLogged': 'Last logged 5 days ago',
      'details': '15 reps × 3 sets',
    },
    {
      'name': 'Yoga Flow',
      'category': 'Yoga',
      'lastLogged': 'Last logged 1 week ago',
      'details': '30 min session',
    },
    {
      'name': 'Running',
      'category': 'Cardio',
      'lastLogged': 'Last logged 2 weeks ago',
      'details': '4.5 km in 30 min',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, String>> get _filteredExercises {
    final searchText = _searchController.text.trim().toLowerCase();

    return _allExercises.where((exercise) {
      final matchesCategory = exercise['category'] == _selectedCategory;
      final matchesSearch =
          exercise['name']!.toLowerCase().contains(searchText);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Yoga':
        return Icons.self_improvement_outlined;
      case 'Calisthenics':
        return Icons.accessibility_new_rounded;
      case 'Cardio':
        return Icons.monitor_heart_outlined;
      default:
        return Icons.fitness_center_outlined;
    }
  }

  void _openExerciseDetail(Map<String, String> exercise) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExerciseDetailScreen(
          exerciseName: exercise['name']!,
          workoutType: exercise['category']!,
          latestDetails: exercise['details']!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercises = _filteredExercises;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: primaryBlue,
                      size: 30,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Exercise History',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: darkText,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search exercises',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: greyText,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: Color(0xFFD4DDEA),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: primaryBlue,
                            width: 2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _categoryChip(
                            label: 'Gym',
                            icon: Icons.fitness_center_outlined,
                          ),
                          const SizedBox(width: 10),
                          _categoryChip(
                            label: 'Yoga',
                            icon: Icons.self_improvement_outlined,
                          ),
                          const SizedBox(width: 10),
                          _categoryChip(
                            label: 'Calisthenics',
                            icon: Icons.accessibility_new_rounded,
                          ),
                          const SizedBox(width: 10),
                          _categoryChip(
                            label: 'Cardio',
                            icon: Icons.monitor_heart_outlined,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 34),

                    const Text(
                      'Recent Exercises',
                      style: TextStyle(
                        color: darkText,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 18),

                    if (exercises.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.search_off_outlined,
                              color: greyText,
                              size: 42,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No exercises found',
                              style: TextStyle(
                                color: darkText,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...exercises.map(_exerciseCard),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryChip({
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedCategory == label;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        setState(() {
          _selectedCategory = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: isSelected ? primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryBlue : const Color(0xFFB9C9E6),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : primaryBlue,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : darkText,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _exerciseCard(Map<String, String> exercise) {
    final category = exercise['category']!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _openExerciseDetail(exercise),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFC8D9F6),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                height: 72,
                width: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3FF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  _categoryIcon(category),
                  color: primaryBlue,
                  size: 38,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise['name']!,
                      style: const TextStyle(
                        color: darkText,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: greyText,
                          fontSize: 16,
                        ),
                        children: [
                          TextSpan(
                            text: category,
                            style: const TextStyle(
                              color: primaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: '  •  ${exercise['lastLogged']}',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      exercise['details']!,
                      style: const TextStyle(
                        color: darkText,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: primaryBlue,
                size: 34,
              ),
            ],
          ),
        ),
      ),
    );
  }
}