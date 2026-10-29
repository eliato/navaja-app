import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design_system/components/navaja_components.dart';
import '../../design_system/navaja_theme.dart';
import '../../domain/formatting.dart';
import '../../domain/models.dart';
import 'booking_controller.dart';
import 'checkout_screen.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({required this.controller, super.key});

  final BookingController controller;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  Timer? _advanceTimer;
  Timer? _toastTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    _toastTimer?.cancel();
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  void _chooseBarber(Barber barber) {
    HapticFeedback.selectionClick();
    widget.controller.chooseBarber(barber);
    _advanceTo(BookingStep.service);
  }

  void _chooseService(ShopService service) {
    HapticFeedback.selectionClick();
    widget.controller.chooseService(service);
    _advanceTo(BookingStep.time);
  }

  void _advanceTo(BookingStep step) {
    _advanceTimer?.cancel();
    _advanceTimer = Timer(const Duration(milliseconds: 280), () {
      if (mounted) widget.controller.goTo(step);
    });
  }

  void _backOrClose() {
    switch (widget.controller.step) {
      case BookingStep.barber:
        Navigator.of(context).pop();
      case BookingStep.service:
        widget.controller.goTo(BookingStep.barber);
      case BookingStep.time:
        widget.controller.goTo(BookingStep.service);
    }
  }

  Future<void> _showWaitlistDialog(TimeSlot slot) async {
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NavajaColors.surfaceRaised,
        title: const Text('¿Te avisamos si se libera?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Las ${clockTime(slot.start)} están cogidas. Si alguien cancela, te mandamos un aviso.',
              style: const TextStyle(color: NavajaColors.inkSecondary),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Tu nombre',
                filled: true,
                fillColor: NavajaColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(18)),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Ahora no'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(nameController.text),
            child: const Text('Apuntarme'),
          ),
        ],
      ),
    );
    nameController.dispose();
    if (name == null || !mounted) return;
    widget.controller.joinWaitlist(slot, name);
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          padding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          elevation: 0,
          content: NavajaToast(
            icon: Icons.notifications_rounded,
            title: 'Te hemos apuntado',
            message: 'Si se liberan las ${clockTime(slot.start)}, te avisamos',
          ),
        ),
      );
    _toastTimer?.cancel();
    _toastTimer = Timer(
      const Duration(seconds: 3),
      widget.controller.dismissWaitlistConfirmation,
    );
  }

  Future<void> _showCheckout() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: NavajaColors.ground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.98,
        child: CheckoutScreen(
          controller: widget.controller,
          onDone: () => Navigator.of(sheetContext).pop(),
        ),
      ),
    );
    if (mounted && widget.controller.phase == BookingPhase.confirmed) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TopBar(step: controller.step, onBack: _backOrClose),
            _ChoiceChips(controller: controller),
            Expanded(
              child: AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : NavajaMotion.page,
                switchInCurve: NavajaMotion.pageCurve,
                switchOutCurve: NavajaMotion.pageCurve,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0.08, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: _StepContent(
                  key: ValueKey(controller.step),
                  controller: controller,
                  onChooseBarber: _chooseBarber,
                  onChooseService: _chooseService,
                  onTakenSlot: _showWaitlistDialog,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          controller.step == BookingStep.time && controller.isReadyForCheckout
          ? SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: 4),
              child: _CheckoutBar(
                controller: controller,
                onContinue: _showCheckout,
              ),
            )
          : null,
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.step, required this.onBack});

  final BookingStep step;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          NavajaPressable(
            semanticLabel: step == BookingStep.barber ? 'Cerrar' : 'Atrás',
            onPressed: onBack,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: NavajaColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: NavajaColors.hairline),
              ),
              child: Icon(
                step == BookingStep.barber
                    ? Icons.close_rounded
                    : Icons.chevron_left_rounded,
              ),
            ),
          ),
          const SizedBox(width: 16),
          for (final candidate in BookingStep.values) ...[
            Expanded(
              child: AnimatedContainer(
                height: 5,
                duration: NavajaMotion.gentle,
                decoration: BoxDecoration(
                  color: candidate.index <= step.index
                      ? NavajaColors.tint
                      : NavajaColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            if (candidate != BookingStep.time) const SizedBox(width: 6),
          ],
          const SizedBox(width: 16),
          Text(
            '${step.index + 1} de 3',
            style: NavajaText.numeral(15, color: NavajaColors.inkSecondary),
          ),
        ],
      ),
    );
  }
}

class _ChoiceChips extends StatelessWidget {
  const _ChoiceChips({required this.controller});

  final BookingController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            if (controller.selectedBarber != null &&
                controller.step.index > BookingStep.barber.index)
              _ChoiceChip(
                icon: Icons.person,
                text: controller.selectedBarber!.name,
                onPressed: () => controller.goTo(BookingStep.barber),
              ),
            if (controller.selectedService != null &&
                controller.step.index > BookingStep.service.index) ...[
              const SizedBox(width: 8),
              _ChoiceChip(
                icon: Icons.content_cut_rounded,
                text: controller.selectedService!.name,
                onPressed: () => controller.goTo(BookingStep.service),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.icon,
    required this.text,
    required this.onPressed,
  });

  final IconData icon;
  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return NavajaPressable(
      semanticLabel: 'Cambiar $text',
      onPressed: onPressed,
      child: NavajaSurface(
        radius: 17,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: NavajaColors.tintText),
            const SizedBox(width: 6),
            Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _StepContent extends StatelessWidget {
  const _StepContent({
    required this.controller,
    required this.onChooseBarber,
    required this.onChooseService,
    required this.onTakenSlot,
    super.key,
  });

  final BookingController controller;
  final ValueChanged<Barber> onChooseBarber;
  final ValueChanged<ShopService> onChooseService;
  final ValueChanged<TimeSlot> onTakenSlot;

  @override
  Widget build(BuildContext context) {
    final title = switch (controller.step) {
      BookingStep.barber => '¿Con quién?',
      BookingStep.service => '¿Qué te hacemos?',
      BookingStep.time => '¿Cuándo te viene?',
    };
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        Text(title, style: NavajaText.display(40).copyWith(letterSpacing: -1)),
        const SizedBox(height: 22),
        switch (controller.step) {
          BookingStep.barber => _BarberChoices(
            controller: controller,
            onChoose: onChooseBarber,
          ),
          BookingStep.service => _ServiceChoices(
            controller: controller,
            onChoose: onChooseService,
          ),
          BookingStep.time => _TimeChooser(
            controller: controller,
            onTakenSlot: onTakenSlot,
          ),
        },
      ],
    );
  }
}

class _BarberChoices extends StatelessWidget {
  const _BarberChoices({required this.controller, required this.onChoose});

  final BookingController controller;
  final ValueChanged<Barber> onChoose;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (
          var index = 0;
          index < controller.catalog.barbers.length;
          index++
        ) ...[
          _BarberChoice(
            barber: controller.catalog.barbers[index],
            tone: NavajaColors.barberTone(index),
            selected:
                controller.selectedBarber == controller.catalog.barbers[index],
            onPressed: () => onChoose(controller.catalog.barbers[index]),
          ),
          if (index != controller.catalog.barbers.length - 1)
            const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _BarberChoice extends StatelessWidget {
  const _BarberChoice({
    required this.barber,
    required this.tone,
    required this.selected,
    required this.onPressed,
  });

  final Barber barber;
  final Color tone;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return NavajaPressable(
      semanticLabel: barber.name,
      onPressed: onPressed,
      child: NavajaSurface(
        isHighlighted: selected,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            NavajaMonogram(initial: barber.initial, size: 62, tone: tone),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(barber.name, style: NavajaText.numeral(24)),
                  const SizedBox(height: 3),
                  Text(
                    barber.specialty,
                    style: const TextStyle(color: NavajaColors.inkSecondary),
                  ),
                  const SizedBox(height: 5),
                  const Row(
                    children: [
                      Icon(Icons.schedule, size: 15, color: NavajaColors.open),
                      SizedBox(width: 6),
                      Text(
                        'Libre mañana a las 10:00',
                        style: TextStyle(
                          color: NavajaColors.open,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _SelectionMark(selected: selected),
          ],
        ),
      ),
    );
  }
}

class _ServiceChoices extends StatelessWidget {
  const _ServiceChoices({required this.controller, required this.onChoose});

  final BookingController controller;
  final ValueChanged<ShopService> onChoose;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (
          var index = 0;
          index < controller.catalog.services.length;
          index++
        ) ...[
          Builder(
            builder: (context) {
              final service = controller.catalog.services[index];
              final selected = controller.selectedService == service;
              return NavajaPressable(
                semanticLabel: service.name,
                onPressed: () => onChoose(service),
                child: NavajaSurface(
                  isHighlighted: selected,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${service.durationMinutes} min',
                              style: const TextStyle(
                                color: NavajaColors.inkSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        euros(service.priceCents),
                        style: NavajaText.display(
                          30,
                          color: selected
                              ? NavajaColors.tintText
                              : NavajaColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (index != controller.catalog.services.length - 1)
            const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _SelectionMark extends StatelessWidget {
  const _SelectionMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: NavajaMotion.snappy,
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: selected ? NavajaColors.tint : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? NavajaColors.tint : NavajaColors.inkTertiary,
          width: 1.5,
        ),
      ),
      child: selected ? const Icon(Icons.check, size: 17) : null,
    );
  }
}

class _TimeChooser extends StatelessWidget {
  const _TimeChooser({required this.controller, required this.onTakenSlot});

  final BookingController controller;
  final ValueChanged<TimeSlot> onTakenSlot;

  @override
  Widget build(BuildContext context) {
    final slots = controller.slots;
    final morning = slots.where((slot) => slot.start.hour < 15).toList();
    final afternoon = slots.where((slot) => slot.start.hour >= 15).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 78,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: controller.bookableDays.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final day = controller.bookableDays[index];
              final selected = _sameDay(day, controller.selectedDay);
              return NavajaPressable(
                semanticLabel: longDate(day),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  controller.chooseDay(day);
                },
                child: AnimatedContainer(
                  width: 60,
                  height: 78,
                  duration: NavajaMotion.snappy,
                  decoration: BoxDecoration(
                    color: selected ? NavajaColors.tint : NavajaColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? NavajaColors.tint
                          : NavajaColors.hairline,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        weekdayShort(day).toUpperCase(),
                        style: TextStyle(
                          color: selected
                              ? Colors.white.withValues(alpha: 0.85)
                              : NavajaColors.inkSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('${day.day}', style: NavajaText.display(26)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 26),
        if (slots.isEmpty)
          const NavajaSurface(
            padding: EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            child: Center(
              child: Text(
                'Este día ya no quedan horas. Prueba con otro.',
                textAlign: TextAlign.center,
                style: TextStyle(color: NavajaColors.inkSecondary),
              ),
            ),
          )
        else ...[
          if (morning.isNotEmpty)
            _SlotPeriod(
              title: 'Mañana',
              icon: Icons.wb_sunny_rounded,
              slots: morning,
              selectedSlot: controller.selectedSlot,
              onAvailable: controller.chooseSlot,
              onTaken: onTakenSlot,
            ),
          if (morning.isNotEmpty && afternoon.isNotEmpty)
            const SizedBox(height: 22),
          if (afternoon.isNotEmpty)
            _SlotPeriod(
              title: 'Tarde',
              icon: Icons.wb_twilight_rounded,
              slots: afternoon,
              selectedSlot: controller.selectedSlot,
              onAvailable: controller.chooseSlot,
              onTaken: onTakenSlot,
            ),
          const SizedBox(height: 18),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.notifications_none_rounded,
                size: 17,
                color: NavajaColors.inkSecondary,
              ),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  '¿Tu hora está cogida? Tócala y te avisamos si se libera.',
                  style: TextStyle(
                    color: NavajaColors.inkSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  bool _sameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

class _SlotPeriod extends StatelessWidget {
  const _SlotPeriod({
    required this.title,
    required this.icon,
    required this.slots,
    required this.selectedSlot,
    required this.onAvailable,
    required this.onTaken,
  });

  final String title;
  final IconData icon;
  final List<TimeSlot> slots;
  final TimeSlot? selectedSlot;
  final ValueChanged<TimeSlot> onAvailable;
  final ValueChanged<TimeSlot> onTaken;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 17, color: NavajaColors.inkSecondary),
            const SizedBox(width: 7),
            Text(
              title,
              style: const TextStyle(
                color: NavajaColors.inkSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: slots.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.65,
          ),
          itemBuilder: (context, index) {
            final slot = slots[index];
            final selected = selectedSlot?.start == slot.start;
            return NavajaPressable(
              key: ValueKey('slot-${slot.start.toIso8601String()}'),
              semanticLabel: slot.isAvailable
                  ? clockTime(slot.start)
                  : '${clockTime(slot.start)}, cogida',
              onPressed: () {
                HapticFeedback.selectionClick();
                slot.isAvailable ? onAvailable(slot) : onTaken(slot);
              },
              child: AnimatedContainer(
                duration: NavajaMotion.snappy,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? NavajaColors.tint
                      : slot.isAvailable
                      ? NavajaColors.surface
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                  border: slot.isAvailable && !selected
                      ? Border.all(color: NavajaColors.hairline)
                      : null,
                ),
                child: Text(
                  clockTime(slot.start),
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : slot.isAvailable
                        ? NavajaColors.ink
                        : NavajaColors.inkTertiary,
                    fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                    decoration: slot.isAvailable
                        ? null
                        : TextDecoration.lineThrough,
                    decorationColor: NavajaColors.inkTertiary,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({required this.controller, required this.onContinue});

  final BookingController controller;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final slot = controller.selectedSlot!;
    final service = controller.selectedService!;
    final barber = controller.selectedBarber!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: NavajaSurface(
        radius: 32,
        isRaised: true,
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${shortDate(slot.start)} · ${clockTime(slot.start)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${service.name} con ${barber.name}',
                        style: const TextStyle(
                          color: NavajaColors.inkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(euros(service.priceCents), style: NavajaText.numeral(26)),
              ],
            ),
            const SizedBox(height: 14),
            NavajaPrimaryButton(
              label:
                  'Reservar · señal de ${euros(controller.catalog.shop.depositCents)}',
              onPressed: onContinue,
            ),
          ],
        ),
      ),
    );
  }
}
