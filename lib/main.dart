import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // <— TAMBAH
import 'package:provider/provider.dart';
import 'core/routes/routes.dart';
import 'core/navigation/viewmodel/navigation_viewmodel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    // Riverpod root
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationViewModel()),
      ],
      child: MaterialApp.router(
        title: 'Cue Mind',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        routerConfig: router,
      ),
    );
  }
}
