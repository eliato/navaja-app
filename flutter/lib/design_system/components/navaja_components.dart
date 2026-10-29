import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../navaja_theme.dart';

class NavajaSurface extends StatelessWidget {
  const NavajaSurface({
    required this.child,
    this.padding,
    this.radius = NavajaRadii.card,
    this.isRaised = false,
    this.isHighlighted = false,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final bool isRaised;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: NavajaMotion.snappy,
      curve: NavajaMotion.gentleCurve,
      padding: padding,
      decoration: BoxDecoration(
        color: isHighlighted
            ? NavajaColors.tintSoft
            : isRaised
            ? NavajaColors.surfaceRaised
            : NavajaColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: isHighlighted ? NavajaColors.tint : NavajaColors.hairline,
          width: isHighlighted ? 2 : 1,
        ),
      ),
      child: child,
    );
  }
}

class NavajaPressable extends StatefulWidget {
  const NavajaPressable({
    required this.child,
    required this.onPressed,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final String? semanticLabel;

  @override
  State<NavajaPressable> createState() => _NavajaPressableState();
}

class _NavajaPressableState extends State<NavajaPressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onPressed != null && _pressed != value) {
      setState(() => _pressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      enabled: widget.onPressed != null,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: AnimatedScale(
          scale: _pressed && !reduceMotion ? NavajaMotion.pressScale : 1,
          duration: reduceMotion ? Duration.zero : NavajaMotion.snappy,
          curve: NavajaMotion.snappyCurve,
          child: widget.child,
        ),
      ),
    );
  }
}

class NavajaPrimaryButton extends StatelessWidget {
  const NavajaPrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.4 : 1,
      child: NavajaPressable(
        semanticLabel: label,
        onPressed: onPressed == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                onPressed!();
              },
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            color: NavajaColors.tint,
            borderRadius: BorderRadius.circular(29),
            border: Border.all(color: const Color(0x1FFFFFFF)),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              if (icon != null) ...[
                const SizedBox(width: 10),
                Icon(icon, size: 20, color: Colors.white),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class NavajaSectionTitle extends StatelessWidget {
  const NavajaSectionTitle(this.title, {this.detail, super.key});

  final String title;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(title, style: NavajaText.numeral(22)),
        const Spacer(),
        if (detail != null)
          Flexible(
            child: Text(
              detail!,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}

class NavajaMonogram extends StatelessWidget {
  const NavajaMonogram({
    required this.initial,
    required this.size,
    required this.tone,
    super.key,
  });

  final String initial;
  final double size;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tone,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: Text(initial, style: NavajaText.display(size * 0.46)),
    );
  }
}

class NavajaPulsingDot extends StatefulWidget {
  const NavajaPulsingDot({this.color = NavajaColors.open, super.key});

  final Color color;

  @override
  State<NavajaPulsingDot> createState() => _NavajaPulsingDotState();
}

class _NavajaPulsingDotState extends State<NavajaPulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return SizedBox.square(
      dimension: 22,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final value = reduceMotion
              ? 0.0
              : Curves.easeOut.transform(_controller.value);
          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: 1 + value * 1.6,
                child: Opacity(
                  opacity: 0.5 * (1 - value),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class NavajaDottedLeader extends StatelessWidget {
  const NavajaDottedLeader({super.key});

  @override
  Widget build(BuildContext context) => const Expanded(
    child: SizedBox(
      height: 2,
      child: CustomPaint(painter: _DottedLeaderPainter()),
    ),
  );
}

class _DottedLeaderPainter extends CustomPainter {
  const _DottedLeaderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = NavajaColors.inkTertiary
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (double x = 1; x < size.width; x += 7) {
      canvas.drawCircle(Offset(x, size.height / 2), 0.75, paint);
    }
  }

  @override
  bool shouldRepaint(_DottedLeaderPainter oldDelegate) => false;
}

class NavajaAmbientGlow extends StatelessWidget {
  const NavajaAmbientGlow({super.key});

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: 440,
      height: 440,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Color(0x73D93A26), Color(0x00D93A26)],
        ),
      ),
    ),
  );
}

class NavajaTicket extends StatelessWidget {
  const NavajaTicket({
    required this.child,
    this.notchY = 112,
    this.padding = const EdgeInsets.all(20),
    super.key,
  });

  final Widget child;
  final double notchY;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _TicketClipper(notchY),
      child: ColoredBox(
        color: NavajaColors.surface,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class NavajaToast extends StatelessWidget {
  const NavajaToast({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return NavajaSurface(
      isRaised: true,
      radius: NavajaRadii.compactCard,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: NavajaColors.tint,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 1),
                Text(message, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketClipper extends CustomClipper<Path> {
  const _TicketClipper(this.notchY);

  final double notchY;

  @override
  Path getClip(Size size) {
    final card = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(26)),
      );
    final notches = Path()
      ..addOval(Rect.fromCircle(center: Offset(0, notchY), radius: 12))
      ..addOval(
        Rect.fromCircle(center: Offset(size.width, notchY), radius: 12),
      );
    return Path.combine(PathOperation.difference, card, notches);
  }

  @override
  bool shouldReclip(_TicketClipper oldClipper) => oldClipper.notchY != notchY;
}

class NavajaBarberPole extends StatefulWidget {
  const NavajaBarberPole({this.width = 15, this.height = 56, super.key});

  final double width;
  final double height;

  @override
  State<NavajaBarberPole> createState() => _NavajaBarberPoleState();
}

class _NavajaBarberPoleState extends State<NavajaBarberPole>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.width / 2),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => CustomPaint(
            painter: _BarberPolePainter(reduceMotion ? 0 : _controller.value),
          ),
        ),
      ),
    );
  }
}

class _BarberPolePainter extends CustomPainter {
  const _BarberPolePainter(this.phase);

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final stripe = math.max(size.width * 0.42, 4.0);
    const colors = [
      NavajaColors.tint,
      Colors.white,
      Color(0xFF4D4D4D),
      Colors.white,
    ];
    final period = stripe * colors.length;
    final offset = phase * period;
    var index = ((-size.height - period) / stripe).floor();
    final last = (size.width / stripe).ceil() + 1;
    for (; index <= last; index++) {
      final x = index * stripe + offset;
      final path = Path()
        ..moveTo(x, size.height)
        ..lineTo(x + stripe, size.height)
        ..lineTo(x + stripe + size.height, 0)
        ..lineTo(x + size.height, 0)
        ..close();
      canvas.drawPath(path, Paint()..color = colors[index % colors.length]);
    }
  }

  @override
  bool shouldRepaint(_BarberPolePainter oldDelegate) =>
      oldDelegate.phase != phase;
}

enum NavajaTab { booking, dashboard }

class NavajaTabBar extends StatelessWidget {
  const NavajaTabBar({
    required this.selection,
    required this.onChanged,
    super.key,
  });

  final NavajaTab selection;
  final ValueChanged<NavajaTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: NavajaColors.surfaceRaised,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: NavajaColors.hairline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x8C000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TabItem(
              tab: NavajaTab.booking,
              selected: selection == NavajaTab.booking,
              label: 'Reservar',
              icon: Icons.content_cut_rounded,
              onChanged: onChanged,
            ),
            _TabItem(
              tab: NavajaTab.dashboard,
              selected: selection == NavajaTab.dashboard,
              label: 'Panel',
              icon: Icons.bar_chart_rounded,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.tab,
    required this.selected,
    required this.label,
    required this.icon,
    required this.onChanged,
  });

  final NavajaTab tab;
  final bool selected;
  final String label;
  final IconData icon;
  final ValueChanged<NavajaTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return NavajaPressable(
      semanticLabel: label,
      onPressed: () {
        HapticFeedback.selectionClick();
        onChanged(tab);
      },
      child: AnimatedContainer(
        height: 48,
        duration: NavajaMotion.snappy,
        curve: NavajaMotion.snappyCurve,
        padding: EdgeInsets.symmetric(horizontal: selected ? 20 : 18),
        decoration: BoxDecoration(
          color: selected ? NavajaColors.tint : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? Colors.white : NavajaColors.inkSecondary,
            ),
            AnimatedSize(
              duration: NavajaMotion.snappy,
              child: selected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
