import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design_system/components/navaja_components.dart';
import '../../design_system/navaja_theme.dart';
import '../../domain/formatting.dart';
import '../../domain/models.dart';
import 'dashboard_controller.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({required this.controller, super.key});

  final DashboardController controller;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _chart;

  @override
  void initState() {
    super.initState();
    _chart = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    _chart.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _selectBarber(String? id) {
    HapticFeedback.selectionClick();
    widget.controller.selectBarber(id);
    _chart.forward(from: 0);
  }

  Future<void> _confirmCancellation(Appointment appointment) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NavajaColors.surfaceRaised,
        title: Text('¿Cancelar la cita de ${appointment.clientName}?'),
        content: Text(
          '${appointment.service.name} a las ${clockTime(appointment.start)} con ${appointment.barber.name}. Si hay alguien en lista de espera, le avisamos.',
          style: const TextStyle(color: NavajaColors.inkSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Mantener'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Cancelar cita',
              style: TextStyle(color: NavajaColors.warning),
            ),
          ),
        ],
      ),
    );
    if (shouldCancel != true || !mounted) return;
    final notice = widget.controller.cancel(appointment);
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 84),
          content: NavajaToast(
            icon: Icons.notifications_rounded,
            title: notice.title,
            message: notice.message,
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      children: [
        Text(
          longDate(controller.today),
          style: const TextStyle(
            color: NavajaColors.inkSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Hoy',
          style: NavajaText.display(56).copyWith(letterSpacing: -1.4),
        ),
        const SizedBox(height: 22),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _FilterChip(
                title: 'Todos',
                selected: controller.barberFilterId == null,
                onPressed: () => _selectBarber(null),
              ),
              for (final barber in controller.catalog.barbers) ...[
                const SizedBox(width: 8),
                _FilterChip(
                  title: barber.name,
                  selected: controller.barberFilterId == barber.id,
                  onPressed: () => _selectBarber(barber.id),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),
        AnimatedBuilder(
          animation: _chart,
          builder: (context, child) => _RevenueCard(
            days: controller.weekRevenue,
            totalCents: controller.weekTotalCents,
            changePercent: controller.weekChangePercent,
            today: controller.today,
            progress: MediaQuery.disableAnimationsOf(context)
                ? 1
                : Curves.easeOutCubic.transform(_chart.value),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                value: controller.agenda.length,
                label: 'citas hoy',
                icon: Icons.content_cut_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                value: controller.waitlistCount,
                label: 'en lista de espera',
                icon: Icons.notifications_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        NavajaSectionTitle(
          'Agenda',
          detail: controller.agenda.isEmpty
              ? null
              : 'Toca una cita para cancelarla',
        ),
        const SizedBox(height: 16),
        if (!controller.isOpenToday)
          const _EmptyAgenda(
            icon: Icons.bedtime_rounded,
            text: 'Hoy no se abre',
          )
        else if (controller.agenda.isEmpty)
          const _EmptyAgenda(
            icon: Icons.calendar_month_rounded,
            text: 'No hay citas para hoy',
          )
        else
          for (final appointment in controller.agenda)
            _AgendaRow(
              appointment: appointment,
              status: controller.statusOf(appointment),
              tone: NavajaColors.barberTone(
                controller.catalog.barbers.indexWhere(
                  (barber) => barber.id == appointment.barber.id,
                ),
              ),
              onTap: () => _confirmCancellation(appointment),
            ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.title,
    required this.selected,
    required this.onPressed,
  });

  final String title;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return NavajaPressable(
      semanticLabel: title,
      onPressed: onPressed,
      child: AnimatedContainer(
        duration: NavajaMotion.snappy,
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? NavajaColors.tint : NavajaColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? NavajaColors.tint : NavajaColors.hairline,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: selected ? Colors.white : NavajaColors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  const _RevenueCard({
    required this.days,
    required this.totalCents,
    required this.changePercent,
    required this.today,
    required this.progress,
  });

  final List<DailyRevenue> days;
  final int totalCents;
  final int? changePercent;
  final DateTime today;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final highest = days.fold(
      0,
      (value, day) => day.cents > value ? day.cents : value,
    );
    return NavajaSurface(
      radius: 30,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Facturado en 7 días',
                      style: TextStyle(
                        color: NavajaColors.inkSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      euros((totalCents * progress).round()),
                      style: NavajaText.display(44)
                          .copyWith(letterSpacing: -1.2),
                    ),
                  ],
                ),
              ),
              if (changePercent case final change?) _ChangePill(change: change),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 146,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final day in days)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: highest == 0
                                ? 6
                                : (6 + 114 * day.cents / highest) * progress,
                            decoration: BoxDecoration(
                              gradient: _sameDay(day.day, today)
                                  ? const LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        NavajaColors.tintText,
                                        NavajaColors.tint,
                                      ],
                                    )
                                  : null,
                              color: _sameDay(day.day, today)
                                  ? null
                                  : NavajaColors.tintSoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _weekdayInitial(day.day),
                            style: TextStyle(
                              color: _sameDay(day.day, today)
                                  ? NavajaColors.ink
                                  : NavajaColors.inkTertiary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static bool _sameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  static String _weekdayInitial(DateTime date) => const {
    DateTime.monday: 'L',
    DateTime.tuesday: 'M',
    DateTime.wednesday: 'X',
    DateTime.thursday: 'J',
    DateTime.friday: 'V',
    DateTime.saturday: 'S',
    DateTime.sunday: 'D',
  }[date.weekday]!;
}

class _ChangePill extends StatelessWidget {
  const _ChangePill({required this.change});

  final int change;

  @override
  Widget build(BuildContext context) {
    final positive = change >= 0;
    final color = positive ? NavajaColors.open : NavajaColors.warning;
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(
            positive
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            size: 17,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            '${positive ? '+' : ''}$change %',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
  });

  final int value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return NavajaSurface(
      radius: 24,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: NavajaColors.tintSoft,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: NavajaColors.tintText),
          ),
          const SizedBox(height: 10),
          Text('$value', style: NavajaText.display(34)),
          Text(label, style: const TextStyle(color: NavajaColors.inkSecondary)),
        ],
      ),
    );
  }
}

class _EmptyAgenda extends StatelessWidget {
  const _EmptyAgenda({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return NavajaSurface(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: NavajaColors.inkSecondary),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: NavajaColors.inkSecondary)),
        ],
      ),
    );
  }
}

class _AgendaRow extends StatelessWidget {
  const _AgendaRow({
    required this.appointment,
    required this.status,
    required this.tone,
    required this.onTap,
  });

  final Appointment appointment;
  final AgendaStatus status;
  final Color tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: status == AgendaStatus.past ? 0.38 : 1,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 19),
            child: SizedBox(
              width: 50,
              child: Text(
                clockTime(appointment.start),
                style: NavajaText.numeral(
                  17,
                  color: status == AgendaStatus.inProgress
                      ? NavajaColors.tintText
                      : NavajaColors.ink,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 24,
            child: Column(
              children: [
                const SizedBox(height: 20),
                if (status == AgendaStatus.inProgress)
                  const NavajaPulsingDot(color: NavajaColors.tint)
                else
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: status == AgendaStatus.past
                          ? NavajaColors.inkTertiary
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: status == AgendaStatus.upcoming
                          ? Border.all(
                              color: NavajaColors.inkSecondary,
                              width: 2,
                            )
                          : null,
                    ),
                  ),
                Container(width: 2, height: 62, color: NavajaColors.hairline),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: NavajaPressable(
                semanticLabel:
                    '${appointment.clientName}, ${clockTime(appointment.start)}',
                onPressed: status == AgendaStatus.upcoming ? onTap : null,
                child: NavajaSurface(
                  radius: 22,
                  isHighlighted: status == AgendaStatus.inProgress,
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      NavajaMonogram(
                        initial: appointment.barber.initial,
                        size: 34,
                        tone: tone,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    appointment.clientName,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (status == AgendaStatus.inProgress) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    height: 18,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                    ),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: NavajaColors.tint,
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    child: const Text(
                                      'AHORA',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              appointment.service.name,
                              style: const TextStyle(
                                color: NavajaColors.inkSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        euros(appointment.service.priceCents),
                        style: NavajaText.numeral(17),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
