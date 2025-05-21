import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Importar Firestore
import '../models/notification_item.dart';

class CapturedNotificationsScreen extends StatelessWidget {
  // Eliminamos el parámetro capturedNotifications del constructor
  // final Map<String, List<NotificationItem>> capturedNotifications;

  const CapturedNotificationsScreen({
    super.key,
    // required this.capturedNotifications, // Eliminamos este parámetro
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones Capturadas'),
      ),
      // Usamos StreamBuilder para escuchar los cambios en Firestore
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('notifications').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar notificaciones: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No se han capturado notificaciones aún.'),
            );
          }

          // Procesar los documentos para agrupar por packageName
          final notifications = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return NotificationItem(
              id: doc.id, // Usar el ID del documento como ID de notificación
              packageName: data['packageName'] ?? 'Desconocido',
              title: data['title'] ?? 'Sin título',
              content: data['content'] ?? 'Sin contenido',
              timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
              time: (data['timestamp'] as Timestamp?)?.toDate().toString().substring(11, 16) ?? '',
              // Puedes añadir color e icono si los guardas en Firestore o los generas aquí
              color: Colors.blue, // Color por defecto o lógica para obtenerlo
              iconData: Icons.notifications, // Icono por defecto o lógica para obtenerlo
              appName: data['title'] ?? 'App Desconocida',
            );
          }).toList();

          // Agrupar notificaciones por packageName
          final Map<String, List<NotificationItem>> groupedNotifications = {};
          for (var notification in notifications) {
            if (!groupedNotifications.containsKey(notification.packageName)) {
              groupedNotifications[notification.packageName] = [];
            }
            groupedNotifications[notification.packageName]!.add(notification);
          }

          // Ordenar las aplicaciones por nombre para una visualización consistente
          final sortedAppPackages = groupedNotifications.keys.toList()..sort();

          return ListView.builder(
              itemCount: sortedAppPackages.length,
              itemBuilder: (context, index) {
                final packageName = sortedAppPackages[index];
                final appNotifications = groupedNotifications[packageName]!;

                // Obtener el nombre de la aplicación (si está disponible en NotificationItem)
                // Si NotificationItem no tiene appName, podrías necesitar un servicio para obtenerlo
                // Basándome en el modelo NotificationItem, parece que solo tiene packageName.
                // Para mostrar un nombre legible, podrías necesitar un mapa packageName -> appName
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
                        appNotifications.length.toString(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    children: appNotifications.map((notification) {
                      return ListTile(
                        title: Text(notification.title ?? 'Sin título'),
                        subtitle: Text(notification.content ?? 'Sin texto'),
                        // Puedes añadir más detalles aquí si NotificationItem los tiene
                        trailing: Text(notification.time), // Mostrar la hora
                      );
                    }).toList(),
                  ),
                );
              },
            );
        },
      ),
    );
  }
}