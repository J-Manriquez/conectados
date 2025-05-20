import 'package:flutter/material.dart';
import '../models/notification_item.dart';
// import '../services/bluetooth_service.dart'; // Ya no necesitamos el servicio Bluetooth directamente aquí
import '../services/error_service.dart'; // Importar el servicio de errores
import 'dart:async'; // Importar para StreamSubscription

class NotificationDisplayPage extends StatefulWidget {
  // Añadir el parámetro notificationsStream al constructor
  final Stream<List<NotificationItem>> notificationsStream;

  const NotificationDisplayPage({
    super.key,
    required this.notificationsStream, // Hacer el parámetro requerido
  });

  @override
  State<NotificationDisplayPage> createState() => _NotificationDisplayPageState();
}

class _NotificationDisplayPageState extends State<NotificationDisplayPage> {
  // Cambiar la lista para que contenga NotificationItem directamente, ya que el stream ahora emite List<NotificationItem>
  final List<NotificationItem> _notifications = [];
  // final BluetoothConnectionService _bluetoothService = BluetoothConnectionService(); // Ya no necesitamos esta instancia
  final ErrorService _errorService = ErrorService(); // Instancia del servicio de errores

  // Suscripción al stream de notificaciones
  StreamSubscription<List<NotificationItem>>? _notificationsSubscription;


  @override
  void initState() {
    super.initState();
    try { // Añadir try-catch
      // Llamar a _listenForNotifications con el stream pasado al widget
      _listenForNotifications(widget.notificationsStream);
    } catch (e, st) { // Capturar error y stack trace
      _errorService.logError( // Registrar el error
        script: 'notification_display_page.dart - initState',
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  void dispose() {
    // Cancelar la suscripción al stream cuando el widget se destruye
    _notificationsSubscription?.cancel();
    super.dispose();
  }

  // Modificar el método para aceptar el stream como parámetro
  void _listenForNotifications(Stream<List<NotificationItem>> stream) {
    // Suscribirse al stream pasado
    _notificationsSubscription = stream.listen((newNotifications) {
      try { // Añadir try-catch dentro del listener
        setState(() {
          // Limpiar la lista actual y añadir todas las nuevas notificaciones
          _notifications.clear();
          _notifications.addAll(newNotifications);
          // Opcional: ordenar si quieres las más recientes primero, aunque el stream combinado ya debería manejarse así
          // _notifications.sort((a, b) => b.time.compareTo(a.time)); // Si NotificationItem tiene un campo 'time' comparable
        });
      } catch (e, st) { // Capturar error y stack trace
        _errorService.logError( // Registrar el error
          script: 'notification_display_page.dart - _listenForNotifications',
          error: e,
          stackTrace: st,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Detectar si estamos en una pantalla pequeña (smartwatch)
    final isSmallScreen = MediaQuery.of(context).size.width < 200;
    
    return Scaffold(
      appBar: isSmallScreen 
        ? AppBar(
            title: const Text('Notificaciones', style: TextStyle(fontSize: 14)),
            toolbarHeight: 40,
          )
        : AppBar(
            title: const Text('Notificaciones'),
          ),
      body: _notifications.isEmpty
          ? const Center(
              child: Text('No hay notificaciones'),
            )
          : ListView.builder(
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                
                // Diseño optimizado para pantallas pequeñas
                if (isSmallScreen) {
                  return SmallScreenNotificationCard(notification: notification);
                } else {
                  return RegularNotificationCard(notification: notification);
                }
              },
            ),
    );
  }
}

class SmallScreenNotificationCard extends StatelessWidget {
  final NotificationItem notification;
  
  const SmallScreenNotificationCard({
    super.key,
    required this.notification,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: notification.color,
                  radius: 10,
                  child: Icon(
                    notification.iconData,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    notification.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              notification.content,
              style: const TextStyle(fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class RegularNotificationCard extends StatelessWidget {
  final NotificationItem notification;
  
  const RegularNotificationCard({
    super.key,
    required this.notification,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: notification.color,
          child: Icon(
            notification.iconData,
            color: Colors.white,
          ),
        ),
        title: Text(notification.title),
        subtitle: Text(notification.content),
        trailing: Text(notification.time),
      ),
    );
  }
}