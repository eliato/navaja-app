# Próximos pasos

## 1. Backend y autenticación

Este es el siguiente bloque recomendado porque los pagos y la sincronización fiable necesitan una fuente de datos central.

- Supabase seleccionado como backend.
- Definir usuarios, empleados, barberos y administradores.
- Implementar sesiones seguras y control de acceso por roles.
- Crear la API de servicios, horarios, citas y lista de espera.
- Sustituir progresivamente los datos demo y la persistencia local.

### Criterio de finalización

Los clientes pueden consultar y crear citas, mientras que solo el personal autorizado puede gestionar la agenda y la configuración del negocio.

## 2. Pagos reales

- Integrar Stripe PaymentSheet.
- Añadir Apple Pay y Google Pay.
- Confirmar pagos mediante webhooks del servidor.
- Gestionar errores, reintentos, cancelaciones y reembolsos.
- Evitar que el cliente confirme una cita basándose únicamente en una respuesta local.

### Criterio de finalización

Una cita solo queda confirmada cuando el backend valida el pago, y cada operación puede auditarse mediante su referencia de Stripe.

## 3. Sincronización de agenda

- Evitar reservas simultáneas del mismo horario mediante transacciones del servidor.
- Actualizar el dashboard cuando cambie una cita.
- Centralizar los estados de las citas en el backend.
- Añadir reintentos y manejo de conectividad intermitente.
- Definir qué información puede consultarse sin conexión.

### Criterio de finalización

Dos clientes no pueden reservar el mismo hueco y todos los dispositivos muestran una agenda consistente.

## 4. Panel operativo

- Añadir acceso exclusivo para empleados.
- Gestionar servicios, precios y duración.
- Editar horarios de apertura y disponibilidad por barbero.
- Bloquear vacaciones, ausencias y cierres excepcionales.
- Reprogramar y cancelar citas.
- Consultar clientes y gestionar la lista de espera.

### Criterio de finalización

El negocio puede operar la agenda diaria sin modificar código ni acceder directamente a la base de datos.

## 5. Calidad de producción

- Probar Android e iOS en dispositivos físicos.
- Revisar accesibilidad, tamaños de texto y navegación asistida.
- Añadir tests de integración para reserva, pago y cancelación.
- Configurar crash reporting, analítica y logs sin datos sensibles.
- Preparar iconos, splash screen y configuración por entorno.
- Revisar rendimiento, consumo de batería y notificaciones.

### Criterio de finalización

Los recorridos críticos están automatizados, los fallos pueden diagnosticarse y la aplicación cumple los requisitos de accesibilidad acordados.

## 6. Distribución

- Configurar firma de Android e iOS.
- Separar variables y secretos de desarrollo, staging y producción.
- Preparar política de privacidad y términos de servicio.
- Configurar TestFlight y Play Console.
- Realizar una beta cerrada antes de publicar.
- Preparar fichas, capturas y metadatos de las tiendas.

### Criterio de finalización

La aplicación puede desplegarse de forma reproducible en ambos canales y dispone de la documentación legal y comercial necesaria.

## Orden recomendado

1. Aplicar la migración inicial de Supabase.
2. Implementar autenticación y autorización en Flutter.
3. Migrar agenda y reservas al backend.
4. Integrar pagos reales y webhooks.
5. Completar sincronización y panel operativo.
6. Ejecutar el bloque de calidad y distribución.

## Decisión tomada

Supabase será la fuente central de autenticación, catálogo, disponibilidad, citas y lista de espera. PostgreSQL y las políticas RLS protegerán el acceso, mientras que Realtime sincronizará posteriormente el dashboard.
