import 'package:flutter/material.dart';

import '../../data/demo_catalog.dart';
import '../../design_system/components/navaja_components.dart';
import '../../design_system/navaja_theme.dart';
import '../../domain/formatting.dart';
import '../../domain/models.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.catalog,
    required this.onBook,
    this.upcomingAppointment,
    super.key,
  });

  final DemoCatalog catalog;
  final VoidCallback onBook;
  final Appointment? upcomingAppointment;

  @override
  Widget build(BuildContext context) {
    final shop = catalog.shop;
    final status = shopStatus(shop.hours, DateTime.now());
    return Stack(
      children: [
        const Positioned(top: -210, left: -150, child: NavajaAmbientGlow()),
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 210),
          children: [
            _Hero(shopName: shop.name, address: shop.address, status: status),
            if (upcomingAppointment case final appointment?) ...[
              const SizedBox(height: NavajaSpacing.section),
              _UpcomingTicket(appointment: appointment, catalog: catalog),
            ],
            const SizedBox(height: NavajaSpacing.section),
            NavajaSectionTitle(
              'La carta',
              detail: 'Señal de ${euros(shop.depositCents)} al reservar',
            ),
            const SizedBox(height: 18),
            NavajaSurface(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  for (
                    var index = 0;
                    index < catalog.services.length;
                    index++
                  ) ...[
                    _ServiceRow(serviceIndex: index, catalog: catalog),
                    if (index != catalog.services.length - 1)
                      const SizedBox(height: 18),
                  ],
                ],
              ),
            ),
            const SizedBox(height: NavajaSpacing.section),
            const NavajaSectionTitle('El equipo'),
            const SizedBox(height: 16),
            Row(
              children: [
                for (
                  var index = 0;
                  index < catalog.barbers.length;
                  index++
                ) ...[
                  Expanded(
                    child: _BarberCard(index: index, catalog: catalog),
                  ),
                  if (index != catalog.barbers.length - 1)
                    const SizedBox(width: 10),
                ],
              ],
            ),
            const SizedBox(height: NavajaSpacing.section),
            const NavajaSectionTitle('Horario'),
            const SizedBox(height: 16),
            NavajaSurface(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _HoursRow('Lunes a viernes', hoursText(shop.hours.weekdays)),
                  const SizedBox(height: 12),
                  _HoursRow('Sábado', hoursText(shop.hours.saturday)),
                  const SizedBox(height: 12),
                  const _HoursRow('Domingo', 'Cerrado'),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 88,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: NavajaColors.ground,
                  blurRadius: 24,
                  spreadRadius: 16,
                ),
              ],
            ),
            child: NavajaPrimaryButton(
              label: 'Reservar cita',
              icon: Icons.arrow_forward_rounded,
              onPressed: onBook,
            ),
          ),
        ),
      ],
    );
  }
}

class _UpcomingTicket extends StatelessWidget {
  const _UpcomingTicket({required this.appointment, required this.catalog});

  final Appointment appointment;
  final DemoCatalog catalog;

  @override
  Widget build(BuildContext context) {
    final barberIndex = catalog.barbers.indexWhere(
      (barber) => barber.id == appointment.barber.id,
    );
    return Container(
      decoration: BoxDecoration(
        color: NavajaColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: NavajaColors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 92,
              color: NavajaColors.tint,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    weekdayShort(appointment.start).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    '${appointment.start.day}',
                    style: NavajaText.display(38),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TU PRÓXIMA CITA',
                      style: TextStyle(
                        color: NavajaColors.tintText,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      appointment.service.name,
                      style: NavajaText.numeral(22),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${relativeTimePhrase(appointment.start, DateTime.now())} con ${appointment.barber.name}',
                      style: const TextStyle(color: NavajaColors.inkSecondary),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 18),
              child: NavajaMonogram(
                initial: appointment.barber.initial,
                size: 40,
                tone: NavajaColors.barberTone(
                  barberIndex < 0 ? 0 : barberIndex,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.shopName,
    required this.address,
    required this.status,
  });

  final String shopName;
  final String address;
  final ShopStatus status;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const NavajaBarberPole(),
            const SizedBox(width: 14),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  shopName,
                  style: NavajaText.display(64).copyWith(letterSpacing: -1.6),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Cortes clásicos y degradados en $address. Reserva en treinta segundos.',
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(color: NavajaColors.inkSecondary),
        ),
        const SizedBox(height: 14),
        NavajaSurface(
          radius: NavajaRadii.control,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (status.isOpen)
                const NavajaPulsingDot()
              else
                const SizedBox(
                  width: 22,
                  child: Center(
                    child: CircleAvatar(
                      radius: 4,
                      backgroundColor: NavajaColors.inkTertiary,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  status.message,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({required this.serviceIndex, required this.catalog});

  final int serviceIndex;
  final DemoCatalog catalog;

  @override
  Widget build(BuildContext context) {
    final service = catalog.services[serviceIndex];
    return Semantics(
      label:
          '${service.name}, ${euros(service.priceCents)}, ${service.durationMinutes} minutos',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  flex: 2,
                  child: Text(
                    service.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const NavajaDottedLeader(),
                const SizedBox(width: 10),
                Text(euros(service.priceCents), style: NavajaText.numeral(19)),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              '${service.durationMinutes} minutos',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _BarberCard extends StatelessWidget {
  const _BarberCard({required this.index, required this.catalog});

  final int index;
  final DemoCatalog catalog;

  @override
  Widget build(BuildContext context) {
    final barber = catalog.barbers[index];
    return NavajaSurface(
      radius: NavajaRadii.compactCard,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 6),
      child: Column(
        children: [
          NavajaMonogram(
            initial: barber.initial,
            size: 58,
            tone: NavajaColors.barberTone(index),
          ),
          const SizedBox(height: 10),
          Text(
            barber.name,
            maxLines: 1,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            barber.specialty,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _HoursRow extends StatelessWidget {
  const _HoursRow(this.days, this.hours);

  final String days;
  final String hours;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(days),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              hours,
              style: const TextStyle(color: NavajaColors.inkSecondary),
            ),
          ),
        ),
      ],
    );
  }
}
