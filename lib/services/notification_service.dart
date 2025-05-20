import 'dart:async';
import 'package:flutter/material.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import '../models/notification_item.dart';
import '../models/app_info.dart';
import 'flow_log_service.dart'; // Importar FlowLogService
import 'error_service.dart'; // Importar ErrorService

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final StreamController<NotificationItem> _notificationController = StreamController<NotificationItem>.broadcast();
  Stream<NotificationItem> get notificationStream => _notificationController.stream;

  List<String> _selectedAppPackages = [];

  final FlowLogService _flowLogService = FlowLogService(); // Instancia de FlowLogService
  final ErrorService _errorService = ErrorService(); // Instancia de ErrorService

  Future<void> initialize() async {
    _flowLogService.logFlow(script: 'notification_service.dart - initialize', message: 'Iniciando servicio de notificaciones.');
    try {
      // Inicializar awesome_notifications
      await AwesomeNotifications().initialize(
        'resource://drawable/app_icon',
        [
          NotificationChannel(
            channelKey: 'conectados_channel',
            channelName: 'Notificaciones de Conectados',
            channelDescription: 'Canal para notificaciones de la aplicación Conectados',
            defaultColor: Colors.blue,
            ledColor: Colors.white,
            importance: NotificationImportance.High,
            playSound: true,
            enableVibration: true
          ),
        ]
      );
      _flowLogService.logFlow(script: 'notification_service.dart - initialize', message: 'AwesomeNotifications inicializado.');

      // Solicitar permisos de notificación
      await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
        if (!isAllowed) {
          _flowLogService.logFlow(script: 'notification_service.dart - initialize', message: 'Solicitando permisos de notificación.');
          AwesomeNotifications().requestPermissionToSendNotifications();
        } else {
          _flowLogService.logFlow(script: 'notification_service.dart - initialize', message: 'Permisos de notificación ya concedidos.');
        }
      });

      // Cargar aplicaciones seleccionadas
      _flowLogService.logFlow(script: 'notification_service.dart - initialize', message: 'Cargando aplicaciones seleccionadas.');
      await _loadSelectedApps();
      _flowLogService.logFlow(script: 'notification_service.dart - initialize', message: 'Aplicaciones seleccionadas cargadas.');

      // Iniciar el servicio de escucha de notificaciones
      _flowLogService.logFlow(script: 'notification_service.dart - initialize', message: 'Solicitando permiso para escuchar notificaciones.');
      await NotificationListenerService.requestPermission();
      _flowLogService.logFlow(script: 'notification_service.dart - initialize', message: 'Permiso para escuchar notificaciones concedido. Iniciando stream.');
      NotificationListenerService.notificationsStream.listen(_onNotificationReceived);
      _flowLogService.logFlow(script: 'notification_service.dart - initialize', message: 'Servicio de notificaciones inicializado completamente.');
    } catch (e, st) {
      _errorService.logError(
        script: 'notification_service.dart - initialize',
        error: e,
        stackTrace: st,
      );
      _flowLogService.logFlow(script: 'notification_service.dart - initialize', message: 'Error durante la inicialización del servicio de notificaciones: ${e.toString()}');
    }
  }

  Future<void> _loadSelectedApps() async {
    _flowLogService.logFlow(script: 'notification_service.dart - _loadSelectedApps', message: 'Iniciando carga de aplicaciones seleccionadas desde SharedPreferences.');
    try {
      final prefs = await SharedPreferences.getInstance();
      _selectedAppPackages = prefs.getStringList('selected_apps') ?? [];
      _flowLogService.logFlow(script: 'notification_service.dart - _loadSelectedApps', message: 'Aplicaciones seleccionadas cargadas: ${_selectedAppPackages.length} paquetes.');
    } catch (e, st) {
      _errorService.logError(
        script: 'notification_service.dart - _loadSelectedApps',
        error: e,
        stackTrace: st,
      );
      _flowLogService.logFlow(script: 'notification_service.dart - _loadSelectedApps', message: 'Error al cargar aplicaciones seleccionadas: ${e.toString()}');
    }
  }

  void _onNotificationReceived(ServiceNotificationEvent event) {
    _flowLogService.logFlow(script: 'notification_service.dart - _onNotificationReceived', message: 'Notificación recibida del sistema: ${event.packageName ?? 'Desconocido'} - ${event.title ?? ''}');
    // Verificar si la aplicación está en la lista de seleccionadas
    if (_selectedAppPackages.contains(event.packageName)) {
      _flowLogService.logFlow(script: 'notification_service.dart - _onNotificationReceived', message: 'La aplicación ${event.packageName} está seleccionada. Procesando notificación.');
      // Convertir la notificación a nuestro modelo
      final notification = NotificationItem(
        packageName: event.packageName ?? '',
        appName: event.packageName ?? 'Desconocido', // Considerar obtener el nombre real de la app si es posible
        title: event.title ?? '',
        content: event.content ?? '',
        timestamp: DateTime.now(),
        time: DateTime.now().toString().substring(11, 16),
        color: _getColorForApp(event.packageName),
        iconData: _getIconForApp(event.packageName),
      );

      // Enviar la notificación al stream
      _notificationController.add(notification);
      _flowLogService.logFlow(script: 'notification_service.dart - _onNotificationReceived', message: 'Notificación añadida al stream: ${notification.title}');

      // Mostrar la notificación usando awesome_notifications
      _showNotification(notification);
      _flowLogService.logFlow(script: 'notification_service.dart - _onNotificationReceived', message: 'Solicitando mostrar notificación local.');
    } else {
      _flowLogService.logFlow(script: 'notification_service.dart - _onNotificationReceived', message: 'La aplicación ${event.packageName} no está seleccionada. Ignorando notificación.');
    }
  }

  Future<void> _showNotification(NotificationItem notification) async {
    _flowLogService.logFlow(script: 'notification_service.dart - _showNotification', message: 'Mostrando notificación local para: ${notification.title}');
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: 'conectados_channel',
          title: notification.title,
          body: notification.content,
          color: notification.color,
          notificationLayout: NotificationLayout.Default,
          // Usar el paquete de la aplicación para mostrar su icono
          icon: 'resource://drawable/app_icon', // Considerar usar un icono específico si es posible
          payload: {'packageName': notification.packageName}
        ),
      );
      _flowLogService.logFlow(script: 'notification_service.dart - _showNotification', message: 'Notificación local mostrada con éxito.');
    } catch (e, st) {
      _errorService.logError(
        script: 'notification_service.dart - _showNotification',
        error: e,
        stackTrace: st,
      );
      _flowLogService.logFlow(script: 'notification_service.dart - _showNotification', message: 'Error al mostrar notificación local: ${e.toString()}');
    }
  }

  Color _getColorForApp(String? packageName) {
    _flowLogService.logFlow(script: 'notification_service.dart - _getColorForApp', message: 'Obteniendo color para el paquete: $packageName');
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
    _flowLogService.logFlow(script: 'notification_service.dart - _getIconForApp', message: 'Obteniendo icono para el paquete: $packageName');
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
    _flowLogService.logFlow(script: 'notification_service.dart - updateSelectedApps', message: 'Actualizando lista de aplicaciones seleccionadas.');
    try {
      final prefs = await SharedPreferences.getInstance();
      _selectedAppPackages = apps
          .where((app) => app.isSelected)
          .map((app) => app.packageName)
          .toList();

      await prefs.setStringList('selected_apps', _selectedAppPackages);
      _flowLogService.logFlow(script: 'notification_service.dart - updateSelectedApps', message: 'Lista de aplicaciones seleccionadas actualizada y guardada: ${_selectedAppPackages.length} paquetes.');
    } catch (e, st) {
      _errorService.logError(
        script: 'notification_service.dart - updateSelectedApps',
        error: e,
        stackTrace: st,
      );
      _flowLogService.logFlow(script: 'notification_service.dart - updateSelectedApps', message: 'Error al actualizar aplicaciones seleccionadas: ${e.toString()}');
    }
  }

  void dispose() {
    _flowLogService.logFlow(script: 'notification_service.dart - dispose', message: 'Cerrando stream de notificaciones.');
    _notificationController.close();
  }
}