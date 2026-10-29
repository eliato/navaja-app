import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navaja/design_system/components/navaja_components.dart';
import 'package:navaja/design_system/navaja_theme.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader('BricolageGrotesque')
      ..addFont(rootBundle.load('assets/fonts/BricolageGrotesque-Bold.ttf'))
      ..addFont(
        rootBundle.load('assets/fonts/BricolageGrotesque-ExtraBold.ttf'),
      );
    await loader.load();
  });

  testWidgets('core card matches the visual baseline', (tester) async {
    tester.view.physicalSize = const Size(390, 220);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: NavajaTheme.dark,
        home: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(20),
              child: RepaintBoundary(
                child: NavajaSurface(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      NavajaMonogram(
                        initial: 'D',
                        size: 58,
                        tone: Color(0xFF6B261C),
                      ),
                      SizedBox(width: 16),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dani',
                            style: TextStyle(
                              fontFamily: 'BricolageGrotesque',
                              fontWeight: FontWeight.w700,
                              fontSize: 24,
                            ),
                          ),
                          Text(
                            'Degradados',
                            style: TextStyle(
                              fontFamily: 'BricolageGrotesque',
                              color: NavajaColors.inkSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byType(RepaintBoundary).last,
      matchesGoldenFile('goldens/core_card.png'),
    );
  });
}
