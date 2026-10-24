import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('L\'environnement de test est prêt', (WidgetTester tester) async {
    // On teste un widget simple pour vérifier que l'environnement fonctionne
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Test OK'),
          ),
        ),
      ),
    );

    // On vérifie que le texte est bien affiché
    expect(find.text('Test OK'), findsOneWidget);
  });
}
