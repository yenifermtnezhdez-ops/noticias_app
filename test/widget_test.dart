
import 'package:flutter_test/flutter_test.dart';
import 'package:noticias_app/main.dart';

void main() {
  testWidgets('La aplicación de noticias inicia correctamente',
      (WidgetTester tester) async {
    await tester.pumpWidget(const NoticiasApp());

    expect(find.text('Noticias App'), findsOneWidget);
    expect(find.text('Conexión con WordPress'), findsOneWidget);
  });
}
