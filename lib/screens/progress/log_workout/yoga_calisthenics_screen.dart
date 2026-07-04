import 'package:flutter/material.dart';

class YogaCalisthenicsScreen extends StatelessWidget {
  final String workoutType;

  const YogaCalisthenicsScreen({
    super.key,
    required this.workoutType,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(workoutType),
      ),
      body: Center(
        child: Text('$workoutType screen will be built next.'),
      ),
    );
  }
}