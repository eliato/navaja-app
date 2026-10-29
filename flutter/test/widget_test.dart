import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navaja/app.dart';
import 'package:navaja/data/demo_catalog.dart';
import 'package:navaja/design_system/components/navaja_components.dart';
import 'package:navaja/design_system/navaja_theme.dart';
import 'package:navaja/features/home/home_screen.dart';

void main() {
  testWidgets('renders the Navaja home screen', (tester) async {
    await tester.pumpWidget(const NavajaApp());
    await tester.pump();

    expect(find.text('Navaja'), findsOneWidget);
    expect(find.text('La carta'), findsOneWidget);
    expect(find.text('Reservar'), findsOneWidget);
    expect(find.byType(NavajaBarberPole), findsOneWidget);
  });

  testWidgets('home does not overflow on a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: NavajaTheme.dark,
        home: Scaffold(
          body: HomeScreen(catalog: const DemoCatalog(), onBook: () {}),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('Horario'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('selection surface keeps the exact brand tokens', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: NavajaTheme.dark,
        home: const NavajaSurface(isHighlighted: true, child: SizedBox()),
      ),
    );

    final container = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, NavajaColors.tintSoft);
    expect(decoration.border!.top.color, NavajaColors.tint);
    expect(decoration.border!.top.width, 2);
  });

  testWidgets('opens booking and advances after choosing a barber', (
    tester,
  ) async {
    await tester.pumpWidget(const NavajaApp());

    await tester.tap(find.text('Reservar cita'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('¿Con quién?'), findsOneWidget);

    await tester.tap(find.text('Dani'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('¿Qué te hacemos?'), findsOneWidget);
    expect(find.text('Dani'), findsOneWidget);

    await tester.tap(find.text('Corte'));
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('¿Cuándo te viene?'), findsOneWidget);
    expect(find.text('Mañana'), findsOneWidget);
  });

  testWidgets('switches to the dashboard tab', (tester) async {
    await tester.pumpWidget(const NavajaApp());

    await tester.tap(find.byIcon(Icons.bar_chart_rounded));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Facturado en 7 días'), findsOneWidget);
    expect(find.text('Todos'), findsOneWidget);
  });
}
