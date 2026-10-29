import 'package:flutter/material.dart';

import 'data/demo_catalog.dart';
import 'design_system/components/navaja_components.dart';
import 'design_system/navaja_theme.dart';
import 'features/booking/booking_controller.dart';
import 'features/booking/booking_screen.dart';
import 'features/dashboard/dashboard_controller.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/home/home_screen.dart';
import 'services/device_appointment_integrations.dart';
import 'services/shared_preferences_booking_store.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  final _catalog = const DemoCatalog();
  late final BookingController _booking = BookingController(
    _catalog,
    reminderService: LocalNotificationReminderService(),
    calendarService: const DeviceCalendarService(),
    store: SharedPreferencesBookingStore(_catalog),
  );
  late final DashboardController _dashboard = DashboardController(_booking);
  NavajaTab _tab = NavajaTab.booking;

  @override
  void initState() {
    super.initState();
    _booking.addListener(_refresh);
    _booking.restore();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _booking.removeListener(_refresh);
    _dashboard.dispose();
    _booking.dispose();
    super.dispose();
  }

  Future<void> _openBooking() async {
    _booking.reset();
    await Navigator.of(context).push<void>(
      PageRouteBuilder(
        fullscreenDialog: true,
        transitionDuration: NavajaMotion.page,
        reverseTransitionDuration: NavajaMotion.page,
        pageBuilder: (context, animation, secondaryAnimation) =>
            BookingScreen(controller: _booking),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _tab.index,
          children: [
            HomeScreen(
              catalog: _catalog,
              upcomingAppointment: _booking.upcomingAppointment,
              onBook: _openBooking,
            ),
            DashboardScreen(controller: _dashboard),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 2),
        child: Center(
          heightFactor: 1,
          child: NavajaTabBar(
            selection: _tab,
            onChanged: (value) => setState(() => _tab = value),
          ),
        ),
      ),
    );
  }
}
