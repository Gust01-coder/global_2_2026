import 'package:flutter_test/flutter_test.dart';
import 'package:plantao_clima_mobile/main.dart';

void main() {
  testWidgets('PlantaoClimaApp renderiza barra superior e abas principais', (tester) async {
    await tester.pumpWidget(const PlantaoClimaApp());
    expect(find.text('Plantão Clima'), findsOneWidget);
    expect(find.text('Rodada'), findsOneWidget);
    expect(find.text('Idosos'), findsOneWidget);
    expect(find.text('Sensor'), findsOneWidget);
    expect(find.text('Relatórios'), findsOneWidget);
  });
}
