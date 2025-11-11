import "package:flutter/material.dart";

/// Loading screen shown during app initialization.
class BootstrapLoadingScreen extends StatelessWidget {
  const BootstrapLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading cue Mind ...', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
