class PaymentReceipt {
  const PaymentReceipt({required this.reference, required this.amountCents});

  final String reference;
  final int amountCents;
}

abstract interface class PaymentGateway {
  Future<PaymentReceipt> chargeDeposit({
    required int amountCents,
    required String description,
  });
}

class SimulatedPaymentGateway implements PaymentGateway {
  const SimulatedPaymentGateway({
    this.latency = const Duration(milliseconds: 1400),
  });

  final Duration latency;

  @override
  Future<PaymentReceipt> chargeDeposit({
    required int amountCents,
    required String description,
  }) async {
    await Future<void>.delayed(latency);
    return PaymentReceipt(
      reference: 'pi_${DateTime.now().microsecondsSinceEpoch}',
      amountCents: amountCents,
    );
  }
}
