import 'package:flutter/material.dart';

class NotificationItem {
  final String id; // Nuevo campo id
  final String packageName;
  final String appName;
  final String title;
  final String content;
  final DateTime timestamp;
  final Color color;
  final IconData iconData;
  final String time;

  NotificationItem({
    required this.id, // Requerido en el constructor
    required this.packageName,
    required this.appName,
    required this.title,
    required this.content,
    required this.timestamp,
    required this.color,
    required this.iconData,
    required this.time,
  });

  // Método para convertir desde un mapa (útil para recibir desde plataforma nativa)
  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    return NotificationItem(
      id: map['id'] ?? '', // Se obtiene el id del mapa
      packageName: map['package'] ?? '',
      appName: map['appName'] ?? '',
      title: map['title'] ?? '',
      content: map['text'] ?? '',
      color: map['color'] ?? Colors.blue,
      iconData: map['iconData'] ?? Icons.notifications,
      time: map['time'] ?? '',
      timestamp: DateTime.now(),
    );
  }

  // Método para convertir a un mapa (útil para enviar por Bluetooth)
  Map<String, dynamic> toMap() {
    return {
      'id': id, // Se agrega el id al mapa
      'package': packageName,
      'appName': appName,
      'title': title,
      'text': content,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  // Método para convertir a JSON (para transmisión)
  String toJson() {
    return '{"id":"$id","package":"$packageName","appName":"$appName","title":"$title","text":"$content","timestamp":${timestamp.millisecondsSinceEpoch}}';
  }
}