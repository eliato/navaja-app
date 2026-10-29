import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design_system/components/navaja_components.dart';
import '../../design_system/navaja_theme.dart';
import '../../domain/formatting.dart';
import '../../domain/models.dart';
import 'booking_controller.dart';

class ConfirmationScreen extends StatefulWidget {
  const ConfirmationScreen({
    required this.controller,
    required this.appointment,
    required this.onDone,
    super.key,
  });

  final BookingController controller;
  final Appointment appointment;
  final VoidCallback onDone;

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _celebration;
  bool _remindsDayBefore = true;
  bool _isInCalendar = false;
  bool _isUpdatingReminder = true;
  bool _isAddingToCalendar = false;

  @override
  void initState() {
    super.initState();
    _celebration = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      if (mounted) HapticFeedback.heavyImpact();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _setReminder(true));
  }

  @override
  void dispose() {
    _celebration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appointment = widget.appointment;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final barberIndex = widget.controller.catalog.barbers.indexWhere(
      (barber) => barber.id == appointment.barber.id,
    );
    return AnimatedBuilder(
      animation: _celebration,
      builder: (context, child) {
        final value = reduceMotion ? 1.0 : _celebration.value;
        final checkValue = Curves.elasticOut.transform(
          ((value - 0.18) / 0.48).clamp(0.0, 1.0),
        );
        final detailsValue = Curves.easeOutCubic.transform(
          ((value - 0.42) / 0.45).clamp(0.0, 1.0),
        );
        return Stack(
          children: [
            ListView(
              padding: const EdgeInsets.only(bottom: 110),
              children: [
                Container(
                  color: NavajaColors.tint,
                  padding: const EdgeInsets.fromLTRB(20, 70, 20, 72),
                  child: Column(
                    children: [
                      Transform.scale(
                        scale: checkValue,
                        child: Container(
                          width: 92,
                          height: 92,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 48,
                            color: NavajaColors.tint,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Opacity(
                        opacity: checkValue.clamp(0, 1),
                        child: Column(
                          children: [
                            Text(
                              '¡Hecho, ${_firstName(appointment.clientName)}!',
                              textAlign: TextAlign.center,
                              style: NavajaText.display(
                                44,
                                color: Colors.white,
                              ).copyWith(letterSpacing: -1.2),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Nos vemos ${relativeTimePhrase(appointment.start, DateTime.now())}.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Transform.translate(
                  offset: Offset(0, 40 * (1 - detailsValue) - 36),
                  child: Opacity(
                    opacity: detailsValue,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
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
                                        initial: appointment.barber.initial,
                                        size: 46,
                                        tone: NavajaColors.barberTone(
                                          barberIndex < 0 ? 0 : barberIndex,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            appointment.service.name,
                                            style: NavajaText.numeral(20),
                                          ),
                                          Text(
                                            'con ${appointment.barber.name}',
                                            style: const TextStyle(
                                              color: NavajaColors.inkSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(
                                  height: 1,
                                  indent: 18,
                                  endIndent: 18,
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _Detail(
                                              'Día',
                                              shortDate(appointment.start),
                                            ),
                                          ),
                                          Expanded(
                                            child: _Detail(
                                              'Hora',
                                              clockTime(appointment.start),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _Detail(
                                              'Señal pagada',
                                              euros(appointment.depositCents),
                                            ),
                                          ),
                                          Expanded(
                                            child: _Detail(
                                              'En la barbería',
                                              euros(
                                                appointment.service.priceCents -
                                                    appointment.depositCents,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          NavajaSurface(
                            child: Material(
                              color: Colors.transparent,
                              child: Column(
                                children: [
                                  SwitchListTile.adaptive(
                                    value: _remindsDayBefore,
                                    activeTrackColor: NavajaColors.tint,
                                    title: const _OptionLabel(
                                      icon: Icons.notifications_rounded,
                                      title: 'Avisarme antes de la cita',
                                    ),
                                    subtitle: _isUpdatingReminder
                                        ? const Padding(
                                            padding: EdgeInsets.only(left: 46),
                                            child: Text(
                                              'Activando recordatorio…',
                                              style: TextStyle(
                                                color:
                                                    NavajaColors.inkSecondary,
                                                fontSize: 12,
                                              ),
                                            ),
                                          )
                                        : null,
                                    onChanged: _isUpdatingReminder
                                        ? null
                                        : _setReminder,
                                  ),
                                  const Divider(height: 1, indent: 62),
                                  ListTile(
                                    leading: const _OptionIcon(
                                      icon: Icons.calendar_month_rounded,
                                    ),
                                    title: Text(
                                      _isInCalendar
                                          ? 'Añadida a tu calendario'
                                          : 'Añadir al calendario',
                                    ),
                                    trailing: _isAddingToCalendar
                                        ? const SizedBox.square(
                                            dimension: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Icon(
                                            _isInCalendar
                                                ? Icons.check_circle
                                                : Icons.chevron_right,
                                            color: _isInCalendar
                                                ? NavajaColors.open
                                                : NavajaColors.inkTertiary,
                                          ),
                                    onTap: _isInCalendar || _isAddingToCalendar
                                        ? null
                                        : _addToCalendar,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (!reduceMotion && value > 0.25)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _ConfettiPainter(
                      ((value - 0.25) / 0.75).clamp(0, 1),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 8,
              child: SafeArea(
                top: false,
                child: Opacity(
                  opacity: detailsValue,
                  child: NavajaPrimaryButton(
                    label: 'Hecho',
                    onPressed: widget.onDone,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _firstName(String name) => name.split(' ').first;

  Future<void> _setReminder(bool enabled) async {
    if (mounted) {
      setState(() {
        _remindsDayBefore = enabled;
        _isUpdatingReminder = true;
      });
    }
    final scheduled = await widget.controller.setReminder(
      widget.appointment,
      enabled: enabled,
    );
    if (!mounted) return;
    setState(() {
      _remindsDayBefore = enabled && scheduled;
      _isUpdatingReminder = false;
    });
    if (enabled && !scheduled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo activar el aviso. Revisa los permisos o la fecha.',
          ),
        ),
      );
    }
  }

  Future<void> _addToCalendar() async {
    HapticFeedback.selectionClick();
    setState(() => _isAddingToCalendar = true);
    final added = await widget.controller.addToCalendar(widget.appointment);
    if (!mounted) return;
    setState(() {
      _isAddingToCalendar = false;
      _isInCalendar = added;
    });
    if (!added) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el calendario.')),
      );
    }
  }
}

class _Detail extends StatelessWidget {
  const _Detail(this.title, this.value);

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: NavajaColors.inkSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(value, style: NavajaText.numeral(18)),
      ],
    );
  }
}

class _OptionLabel extends StatelessWidget {
  const _OptionLabel({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _OptionIcon(icon: icon),
        const SizedBox(width: 14),
        Flexible(child: Text(title)),
      ],
    );
  }
}

class _OptionIcon extends StatelessWidget {
  const _OptionIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: NavajaColors.tintSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: NavajaColors.tintText),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const colors = [
      NavajaColors.tint,
      NavajaColors.ink,
      Color(0xFF737373),
      NavajaColors.tintText,
    ];
    for (var index = 0; index < 55; index++) {
      final xBase = ((index * 47) % 101) / 100;
      final delay = (index % 8) / 20;
      final t = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;
      final sway = math.sin(t * 8 + index) * (10 + index % 20);
      final x = xBase * size.width + sway;
      final y = -20 + t * size.height * 1.05;
      final paint = Paint()
        ..color = colors[index % colors.length].withValues(alpha: 1 - t * 0.35);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * (2 + index % 6));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: 6 + (index % 4).toDouble(),
            height: 12 + (index % 7).toDouble(),
          ),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
