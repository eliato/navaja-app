# Navaja Flutter

Base multiplataforma de la migración de Navaja. Actualmente incluye el sistema visual, Home, flujo completo de reserva y dashboard: disponibilidad, lista de espera, checkout, pago simulado, confirmación, próxima cita, facturación semanal, filtros, agenda y cancelaciones. Las citas y la lista de espera se conservan localmente entre sesiones. La confirmación programa recordatorios locales y permite abrir el calendario nativo para guardar la cita.

## Ejecutar

```sh
flutter pub get
flutter run
```

## Verificar

```sh
flutter analyze
flutter test
```

Para actualizar deliberadamente las referencias golden:

```sh
flutter test --update-goldens
```

La configuración inicial del backend está documentada en [SUPABASE.md](SUPABASE.md).

La referencia SwiftUI está documentada en `../docs/design-reference/README.md`.
