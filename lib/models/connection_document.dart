import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_item.dart'; // Asegúrate de que NotificationItem está importado

class ConnectionDocument {
  final String status;
  final List<NotificationItem> notifications;
  final Timestamp? lastUpdated; // Puede ser nulo inicialmente

  ConnectionDocument({
    required this.status,
    required this.notifications,
    this.lastUpdated,
  });

  // Método para crear una instancia de ConnectionDocument desde un mapa de Firestore
  factory ConnectionDocument.fromMap(Map<String, dynamic> map) {
    return ConnectionDocument(
      status: map['status'] as String? ?? 'unknown', // Valor por defecto si es nulo
      notifications: (map['notifications'] as List<dynamic>?)
              ?.map((itemMap) => NotificationItem.fromMap(itemMap as Map<String, dynamic>))
              .toList() ??
          [], // Lista vacía por defecto si es nulo
      lastUpdated: map['lastUpdated'] as Timestamp?,
    );
  }

  // Método para convertir una instancia de ConnectionDocument a un mapa para Firestore
  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'notifications': notifications.map((item) => item.toMap()).toList(),
      'lastUpdated': lastUpdated ?? FieldValue.serverTimestamp(), // Usar serverTimestamp si es nulo
    };
  }
}