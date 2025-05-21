import 'package:flutter/material.dart';
import '../models/notification_item.dart';

class CapturedNotificationsScreen extends StatelessWidget {
  final Map<String, List<NotificationItem>> capturedNotifications;

  const CapturedNotificationsScreen({
    super.key,
    required this.capturedNotifications,
  });

  @override
  Widget build(BuildContext context) {
    // Ordenar las aplicaciones por nombre para una visualización consistente
    final sortedAppPackages = capturedNotifications.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones Capturadas'),
      ),
      body: sortedAppPackages.isEmpty
          ? const Center(
              child: Text('No se han capturado notificaciones aún.'),
            )
          : ListView.builder(
              itemCount: sortedAppPackages.length,
              itemBuilder: (context, index) {
                final packageName = sortedAppPackages[index];
                final notifications = capturedNotifications[packageName]!;

                // Obtener el nombre de la aplicación (si está disponible en NotificationItem)
                // Si NotificationItem no tiene appName, podrías necesitar un servicio para obtenerlo
                // Basándome en el modelo NotificationItem, parece que solo tiene packageName.
                // Para mostrar un nombre legible, podrías necesitar un mapa packageName -> appName
                // o modificar NotificationItem para incluir appName.
                // Por ahora, usaremos el packageName como identificador.
                // TODO: Implementar la obtención del nombre legible de la aplicación si es necesario.
                final appName = packageName; // Usar packageName por ahora

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: ExpansionTile(
                    title: Text(
                      appName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    // Mostrar el número de notificaciones para esta app
                    trailing: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      radius: 12,
                      child: Text(
                        notifications.length.toString(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    children: notifications.map((notification) {
                      return ListTile(
                        title: Text(notification.title ?? 'Sin título'),
                        subtitle: Text(notification.content ?? 'Sin texto'),
                        // Puedes añadir más detalles aquí si NotificationItem los tiene
                        // Por ejemplo: leading: Icon(Icons.notifications),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
    );
  }
}