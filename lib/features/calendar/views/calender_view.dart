import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

class CalendarView extends StatelessWidget {
  const CalendarView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calender View'),
      ),
      body: const Center(
        child: Text('Welcome to the Calender View!'),
      ),
    );
  }
}