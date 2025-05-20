import 'package:flutter/material.dart';
import '../models/notification_item.dart';
import '../services/bluetooth_service.dart';

class NotificationDisplayPage extends StatefulWidget {
  const NotificationDisplayPage({super.key});

  @override
  State<NotificationDisplayPage> createState() => _NotificationDisplayPageState();
}

class _NotificationDisplayPageState extends State<NotificationDisplayPage> {
  final List<NotificationItem> _notifications = [];
  final BluetoothConnectionService _bluetoothService = BluetoothConnectionService();
  
  @override
  void initState() {
    super.initState();
    _listenForNotifications();
  }
  
  void _listenForNotifications() {
    _bluetoothService.receivedNotifications.listen((notification) {
      setState(() {
        // Añadir al principio para mostrar las más recientes primero
        _notifications.insert(0, notification);
      });
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