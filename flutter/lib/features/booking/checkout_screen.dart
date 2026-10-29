import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design_system/components/navaja_components.dart';
import '../../design_system/navaja_theme.dart';
import '../../domain/formatting.dart';
import 'booking_controller.dart';
import 'confirmation_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    required this.controller,
    required this.onDone,
    super.key,
  });

  final BookingController controller;
  final VoidCallback onDone;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final FocusNode _nameFocus;
  late final FocusNode _phoneFocus;
  late final AnimationController _shake;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.controller.clientName);
    _phoneController = TextEditingController(
      text: widget.controller.clientPhone,
    );
    _nameFocus = FocusNode()..addListener(_refresh);
    _phoneFocus = FocusNode()..addListener(_refresh);
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    _nameController.dispose();
    _phoneController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _shake.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _startPayment() async {
    if (_nameController.text.trim().isEmpty) {
      _nameFocus.requestFocus();
      HapticFeedback.heavyImpact();
      await _shake.forward(from: 0);
      return;
    }
    FocusScope.of(context).unfocus();
    widget.controller.clearFailure();
    await widget.controller.pay(
      name: _nameController.text,
      phone: _phoneController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final appointment = controller.confirmedAppointment;
    return PopScope(
      canPop: controller.phase != BookingPhase.paying,
      child: Material(
        color: NavajaColors.ground,
        child: AnimatedSwitcher(
          duration: NavajaMotion.gentle,
          child:
              appointment != null && controller.phase == BookingPhase.confirmed
              ? ConfirmationScreen(
                  key: const ValueKey('confirmation'),
                  controller: controller,
                  appointment: appointment,
                  onDone: widget.onDone,
                )
              : _paymentForm(context),
        ),
      ),
    );
  }

  Widget _paymentForm(BuildContext context) {
    final controller = widget.controller;
    final barber = controller.selectedBarber!;
    final service = controller.selectedService!;
    final slot = controller.selectedSlot!;
    final barberIndex = controller.catalog.barbers.indexWhere(
      (candidate) => candidate.id == barber.id,
    );
    return ListView(
      key: const ValueKey('payment-form'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: NavajaPressable(
            semanticLabel: 'Cerrar',
            onPressed: controller.phase == BookingPhase.paying
                ? null
                : () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: NavajaColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded),
            ),
          ),
        ),
        const SizedBox(height: 22),
        Column(
          children: [
            const Text(
              'Paga ahora la señal',
              style: TextStyle(
                color: NavajaColors.inkSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              euros(controller.catalog.shop.depositCents),
              style: NavajaText.display(84).copyWith(letterSpacing: -3),
            ),
            Text(
              'y ${euros(controller.remainingCents)} en la barbería',
              style: const TextStyle(color: NavajaColors.inkSecondary),
            ),
          ],
        ),
        const SizedBox(height: 24),
        NavajaTicket(
          notchY: 82,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    NavajaMonogram(
                      initial: barber.initial,
                      size: 46,
                      tone: NavajaColors.barberTone(
                        barberIndex < 0 ? 0 : barberIndex,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(service.name, style: NavajaText.numeral(20)),
                          Text(
                            'con ${barber.name}',
                            style: const TextStyle(
                              color: NavajaColors.inkSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      euros(service.priceCents),
                      style: NavajaText.numeral(20),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, indent: 18, endIndent: 18),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, size: 18),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        longDate(slot.start),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    const Icon(Icons.schedule_rounded, size: 18),
                    const SizedBox(width: 7),
                    Text(
                      clockTime(slot.start),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AnimatedBuilder(
          animation: _shake,
          builder: (context, child) => Transform.translate(
            offset: Offset(math.sin(_shake.value * math.pi * 4) * 8, 0),
            child: child,
          ),
          child: Column(
            children: [
              _BrandTextField(
                controller: _nameController,
                focusNode: _nameFocus,
                label: 'Tu nombre',
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _phoneFocus.requestFocus(),
              ),
              const SizedBox(height: 10),
              _BrandTextField(
                controller: _phoneController,
                focusNode: _phoneFocus,
                label: 'Teléfono (opcional)',
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        if (controller.paymentError case final error?) ...[
          const SizedBox(height: 18),
          Row(
            children: [
              const Icon(Icons.warning_rounded, color: NavajaColors.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  error,
                  style: const TextStyle(color: NavajaColors.warning),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        if (controller.phase == BookingPhase.paying)
          Container(
            height: 58,
            decoration: BoxDecoration(
              color: NavajaColors.tint,
              borderRadius: BorderRadius.circular(29),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Procesando el pago…',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          )
        else ...[
          NavajaPressable(
            semanticLabel: 'Pagar con Apple Pay',
            onPressed: _startPayment,
            child: Container(
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(29),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.apple, color: Colors.black, size: 25),
                  SizedBox(width: 7),
                  Text(
                    'Pay',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: TextButton(
              onPressed: _startPayment,
              child: const Text(
                'Pagar con tarjeta',
                style: TextStyle(
                  color: NavajaColors.tintText,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_rounded,
              size: 16,
              color: NavajaColors.inkSecondary,
            ),
            SizedBox(width: 7),
            Text(
              'Pago seguro con Stripe',
              style: TextStyle(color: NavajaColors.inkSecondary, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }
}

class _BrandTextField extends StatelessWidget {
  const _BrandTextField({
    required this.controller,
    required this.focusNode,
    required this.label,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: const TextStyle(color: NavajaColors.inkTertiary),
        filled: true,
        fillColor: NavajaColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18),
        constraints: const BoxConstraints.tightFor(height: 56),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: NavajaColors.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: NavajaColors.tint, width: 2),
        ),
      ),
    );
  }
}
