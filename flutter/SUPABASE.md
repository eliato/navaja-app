# Supabase

Supabase es el backend elegido para Navaja. La app conserva temporalmente su modo local cuando no recibe configuración.

## Requisitos

- Un proyecto de Supabase o Supabase CLI para desarrollo local.
- Flutter con las dependencias de `pubspec.yaml` instaladas.
- Supabase CLI para aplicar las migraciones.

## Base de datos

La migración inicial está en:

```text
../supabase/migrations/202610280001_initial_schema.sql
```

Incluye:

- Perfiles vinculados a Supabase Auth.
- Roles `client`, `staff` y `admin`.
- Barbería, barberos, servicios y horarios.
- Citas protegidas contra solapamientos por barbero.
- Lista de espera.
- Row Level Security en todas las tablas públicas.
- RPC pública para consultar huecos ocupados sin exponer clientes.
- RPC autenticada para crear citas con precio y duración validados en servidor.
- Catálogo inicial equivalente a los datos demo de Flutter.

Para aplicar la migración a un proyecto remoto:

```sh
supabase login
supabase link --project-ref TU_PROJECT_REF
supabase db push
```

## Configuración Flutter

No guardes la clave `service_role` en la app. Flutter solo debe recibir la URL y la clave pública `anon` o `publishable`.

```sh
flutter run \
  --dart-define=SUPABASE_URL=https://TU_PROJECT.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=TU_CLAVE_PUBLICA
```

También se acepta temporalmente `SUPABASE_ANON_KEY` para proyectos que aún usan la clave `anon` heredada. Si ninguna variable está presente, la app arranca con datos y persistencia locales. Si solo se proporciona la URL o la clave, el arranque falla deliberadamente para detectar una configuración incompleta.

## Siguiente integración

1. Añadir autenticación de clientes y empleados.
2. Leer catálogo y horarios desde Supabase.
3. Consultar disponibilidad mediante `get_booked_slots`.
4. Crear citas mediante `create_appointment`.
5. Reemplazar la persistencia local por caché sincronizada.
6. Añadir Realtime al dashboard.

La RPC de creación confirma citas directamente durante esta primera etapa. Al integrar Stripe deberá cambiarse para crear reservas pendientes y confirmar únicamente desde un webhook seguro.
