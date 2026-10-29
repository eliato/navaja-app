import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navaja/data/demo_catalog.dart';
import 'package:navaja/design_system/navaja_theme.dart';
import 'package:navaja/features/booking/booking_controller.dart';
import 'package:navaja/features/booking/checkout_screen.dart';
import 'package:navaja/services/payment_gateway.dart';

void main() {
  testWidgets('checkout validates, pays and shows confirmation', (
    tester,
  ) async {
    const catalog = DemoCatalog();
    final controller =
        BookingController(
            catalog,
            clock: () => DateTime(2026, 10, 21, 9),
            paymentGateway: const _ImmediatePaymentGateway(),
          )
          ..chooseBarber(catalog.barbers.first)
          ..chooseService(catalog.services.first);
    controller.chooseSlot(
      controller.slots.firstWhere((slot) => slot.isAvailable),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: NavajaTheme.dark,
        home: CheckoutScreen(controller: controller, onDone: () {}),
      ),
    );

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump();
    await tester.tap(find.text('Pagar con tarjeta'));
    await tester.pump(const Duration(milliseconds: 450));
    expect(controller.phase, BookingPhase.choosing);

    await tester.enterText(
      find.widgetWithText(TextField, 'Tu nombre'),
      'Carlos',
    );
    await tester.tap(find.text('Pagar con tarjeta'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1300));

    expect(find.text('¡Hecho, Carlos!'), findsOneWidget);
    expect(find.text('Hecho'), findsOneWidget);
    expect(controller.phase, BookingPhase.confirmed);
  });
}

class _ImmediatePaymentGateway implements PaymentGateway {
  const _ImmediatePaymentGateway();

  @override
  Future<PaymentReceipt> chargeDeposit({
    required int amountCents,
    required String description,
  }) async => PaymentReceipt(reference: 'pi_test', amountCents: amountCents);
}
