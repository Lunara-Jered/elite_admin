import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/admin/screens/admin_dashboard_screen.dart';

// SOLUTION 1 : Les clés sont mises directement en dur (en tant que constantes simples)
const _supabaseUrl = 'https://yhxdvbguztnirevcwnlz.supabase.co';
const _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InloeGR2Ymd1enRuaXJldmN3bmx6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI3NTcwOTAsImV4cCI6MjEwODMzMjA5MH0.sYhIWKv-sA9emehx7ADh72auKV5nGsFrgEJBxkFbAfQ';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Vérification de sécurité (bien que les clés soient maintenant remplies)
  final configured = _supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty;
  
  if (configured) {
    await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
  }
  
  runApp(ProviderScope(child: MyApp(configured: configured)));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.configured});

  final bool configured;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Élite Prestations',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black).copyWith(
          primary: Colors.black,
          onPrimary: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: configured
          ? const AdminDashboardScreen()
          : const Scaffold(
              body: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'La configuration Supabase est requise pour continuer.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
    );
  }
}

// J'ai laissé le widget MyHomePage par défaut à la fin, 
// vous pourrez le supprimer plus tard car il ne sert plus à rien.
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
