import 'package:flutter/material.dart';

import '../components/navaja_components.dart';
import '../navaja_theme.dart';

class DesignSystemShowcase extends StatefulWidget {
  const DesignSystemShowcase({super.key});

  @override
  State<DesignSystemShowcase> createState() => _DesignSystemShowcaseState();
}

class _DesignSystemShowcaseState extends State<DesignSystemShowcase> {
  NavajaTab _tab = NavajaTab.booking;
  bool _selected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned(top: -210, left: -150, child: NavajaAmbientGlow()),
          SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 130),
              children: [
                Row(
                  children: [
                    const NavajaBarberPole(),
                    const SizedBox(width: 14),
                    Text(
                      'Navaja',
                      style: NavajaText.display(58)
                          .copyWith(letterSpacing: -1.6),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Sistema visual Flutter · referencia de migración',
                  style: TextStyle(
                    color: NavajaColors.inkSecondary,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: NavajaSurface(
                    radius: NavajaRadii.control,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        NavajaPulsingDot(),
                        SizedBox(width: 4),
                        Text('Abierto · cierra a las 20:00'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 34),
                const NavajaSectionTitle(
                  'La carta',
                  detail: 'Señal de 5,00 € al reservar',
                ),
                const SizedBox(height: 18),
                const NavajaSurface(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _MenuRow('Corte clásico', '15,00 €', '30 minutos'),
                      SizedBox(height: 18),
                      _MenuRow('Corte y barba', '22,00 €', '45 minutos'),
                      SizedBox(height: 18),
                      _MenuRow('Arreglo de barba', '12,00 €', '30 minutos'),
                    ],
                  ),
                ),
                const SizedBox(height: 34),
                const NavajaSectionTitle('Componentes'),
                const SizedBox(height: 16),
                NavajaPressable(
                  semanticLabel: 'Seleccionar a Dani',
                  onPressed: () => setState(() => _selected = !_selected),
                  child: NavajaSurface(
                    isHighlighted: _selected,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const NavajaMonogram(
                          initial: 'D',
                          size: 58,
                          tone: Color(0xFF6B261C),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Dani', style: NavajaText.numeral(24)),
                              const SizedBox(height: 3),
                              const Text(
                                'Degradados',
                                style: TextStyle(
                                  color: NavajaColors.inkSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Libre hoy a las 17:30',
                                style: TextStyle(
                                  color: NavajaColors.open,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedContainer(
                          duration: NavajaMotion.snappy,
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _selected
                                ? NavajaColors.tint
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _selected
                                  ? NavajaColors.tint
                                  : NavajaColors.inkTertiary,
                            ),
                          ),
                          child: _selected
                              ? const Icon(Icons.check, size: 17)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const NavajaTicket(
                  notchY: 78,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TU PRÓXIMA CITA',
                        style: TextStyle(
                          color: NavajaColors.tintText,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Corte y barba',
                        style: TextStyle(
                          fontFamily: 'BricolageGrotesque',
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Mañana a las 17:30 con Dani',
                        style: TextStyle(color: NavajaColors.inkSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                NavajaPrimaryButton(
                  label: 'Reservar cita',
                  icon: Icons.arrow_forward,
                  onPressed: () {},
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 14,
            child: SafeArea(
              top: false,
              child: Center(
                child: NavajaTabBar(
                  selection: _tab,
                  onChanged: (value) => setState(() => _tab = value),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow(this.name, this.price, this.duration);

  final String name;
  final String price;
  final String duration;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              name,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 10),
            const NavajaDottedLeader(),
            const SizedBox(width: 10),
            Text(price, style: NavajaText.numeral(19)),
          ],
        ),
        const SizedBox(height: 3),
        Text(duration, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
