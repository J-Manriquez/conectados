import 'dart:async';
import 'package:flutter/material.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_item.dart';
import '../models/app_info.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final StreamController<NotificationItem> _notificationController = StreamController<NotificationItem>.broadcast();
  Stream<NotificationItem> get notificationStream => _notificationController.stream;
  
  List<String> _selectedAppPackages = [];
  
  Future<void> initialize() async {
    // Cargar aplicaciones seleccionadas
    await _loadSelectedApps();
    
    // Iniciar el servicio de escucha de notificaciones
    await NotificationListenerService.requestPermission();
    NotificationListenerService.notificationsStream.listen(_onNotificationReceived);
  }
  
  Future<void> _loadSelectedApps() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedAppPackages = prefs.getStringList('selected_apps') ?? [];
  }
  
  void _onNotificationReceived(ServiceNotificationEvent event) {
    // Verificar si la aplicación está en la lista de seleccionadas
    if (_selectedAppPackages.contains(event.packageName)) {
      // Convertir la notificación a nuestro modelo
      final notification = NotificationItem(
        packageName: event.packageName ?? '',
        appName: event.packageName ?? 'Desconocido',
        title: event.title ?? '',
        content: event.content ?? '',  // Nota: cambié event.text a event.content según la documentación
        timestamp: DateTime.now(),
        time: DateTime.now().toString().substring(11, 16),
        color: _getColorForApp(event.packageName),
        iconData: _getIconForApp(event.packageName),
      );
      
      // Enviar la notificación al stream
      _notificationController.add(notification);
    }
  }
  
  Color _getColorForApp(String? packageName) {
    // Lógica para asignar colores según la aplicación
    switch (packageName) {
      case 'com.whatsapp':
        return Colors.green;
      case 'com.google.android.gm':
        return Colors.red;
      case 'org.telegram.messenger':
        return Colors.lightBlueAccent;
      default:
        return Colors.blue;
    }
  }
  
  IconData _getIconForApp(String? packageName) {
    // Lógica para asignar iconos según la aplicación
    switch (packageName) {
      case 'com.whatsapp':
        return Icons.message;
      case 'com.google.android.gm':
        return Icons.email;
      case 'org.telegram.messenger':
        return Icons.send;
      default:
        return Icons.notifications;
    }
  }
  
  Future<void> updateSelectedApps(List<AppInfo> apps) async {
    final prefs = await SharedPreferences.getInstance();
    _selectedAppPackages = apps
        .where((app) => app.isSelected)
        .map((app) => app.packageName)
        .toList();
    
    await prefs.setStringList('selected_apps', _selectedAppPackages);
  }
  
  void dispose() {
    _notificationController.close();
  }
}