import '../domain/models.dart';

class DemoCatalog {
  const DemoCatalog();

  Shop get shop => const Shop(
    name: 'Navaja',
    address: 'C/ Mayor 12',
    depositCents: 500,
    hours: OpeningHours(
      weekdays: [
        OpeningBlock(startMinute: 10 * 60, endMinute: 14 * 60),
        OpeningBlock(startMinute: 16 * 60 + 30, endMinute: 20 * 60 + 30),
      ],
      saturday: [OpeningBlock(startMinute: 10 * 60, endMinute: 14 * 60)],
    ),
  );

  List<Barber> get barbers => const [
    Barber(id: 'dani', name: 'Dani', specialty: 'Degradados'),
    Barber(id: 'marcos', name: 'Marcos', specialty: 'Clásico'),
    Barber(id: 'ruben', name: 'Rubén', specialty: 'Barba'),
  ];

  List<ShopService> get services => const [
    ShopService(
      id: 'corte',
      name: 'Corte',
      durationMinutes: 30,
      priceCents: 1500,
    ),
    ShopService(
      id: 'corte-barba',
      name: 'Corte + barba',
      durationMinutes: 45,
      priceCents: 2200,
    ),
    ShopService(
      id: 'degradado',
      name: 'Degradado',
      durationMinutes: 40,
      priceCents: 1800,
    ),
    ShopService(
      id: 'barba',
      name: 'Barba',
      durationMinutes: 20,
      priceCents: 1000,
    ),
  ];

  List<String> get clientNames => const [
    'Javi M.',
    'Sergio R.',
    'Álvaro P.',
    'Hugo',
    'Mario G.',
    'Pablo',
    'Iván L.',
    'Adrián',
    'Raúl S.',
    'Diego',
    'Marcos T.',
    'Óscar',
  ];

  List<String> get waitlistNames => const ['Lucía', 'Andrés'];
}
