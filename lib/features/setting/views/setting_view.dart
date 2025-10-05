import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

class SettingView extends StatelessWidget {
  const SettingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setting View'),
      ),
      body: const Center(
        child: Text('Welcome to the Setting View!'),
      ),
    );
  }
}