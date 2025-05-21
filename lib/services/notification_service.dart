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
      NotificationListenerService.notificationsStream.listen(_onNotificationReceived as void Function(ServiceNotificationEvent event)?);
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

  // Método para cargar las aplicaciones seleccionadas
  Future<void> _loadSelectedApps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedApps = prefs.getStringList('selectedApps') ?? [];
      _selectedAppPackages = selectedApps;
      _flowLogService.logFlow(script: 'notification_service.dart - _loadSelectedApps', message: 'Aplicaciones seleccionadas cargadas: ${_selectedAppPackages.length}');
    } catch (e, st) {
      _errorService.logError(
        script: 'notification_service.dart - _loadSelectedApps',
        error: e,
        stackTrace: st,
      );
    }
  }
  
  // Método para procesar las notificaciones recibidas
  // Método para manejar las notificaciones recibidas del servicio de escucha
  // Modificado para aceptar dynamic y manejar posible Map<String, dynamic>
  void _onNotificationReceived(dynamic eventData) async {
    _flowLogService.logFlow(script: 'notification_service.dart - _onNotificationReceived', message: 'Notificación recibida del servicio de escucha.');
    try {
      // Intentar convertir el dato recibido a ServiceNotificationEvent
      ServiceNotificationEvent? event;
      if (eventData is ServiceNotificationEvent) {
        event = eventData;
      } else if (eventData is Map<String, dynamic>) {
        // Si es un mapa, intentar construir un ServiceNotificationEvent (esto puede variar según la estructura real del mapa)
        // Esta es una suposición basada en el mensaje de error. Puede requerir ajuste.
        try {
           event = ServiceNotificationEvent(
            packageName: eventData['packageName'] as String?,
            // Añadir otros campos si están disponibles en el mapa y son necesarios
            // title: eventData['title'] as String?,
            // text: eventData['text'] as String?,
            // id: eventData['id'] as int?,
            // canPost: eventData['canPost'] as bool?,
            // isOngoing: eventData['isOngoing'] as bool?,
            // isClearable: eventData['isClearable'] as bool?,
            // postTime: eventData['postTime'] != null ? DateTime.fromMillisecondsSinceEpoch(eventData['postTime']) : null,
            // tag: eventData['tag'] as String?,
            // key: eventData['key'] as String?,
            // groupKey: eventData['groupKey'] as String?,
            // groupAlertBehavior: eventData['groupAlertBehavior'] as int?,
            // groupSummary: eventData['groupSummary'] as bool?,
            // category: eventData['category'] as String?,
            // extras: eventData['extras'] as Map<String, dynamic>?,
            // overrideGroupKey: eventData['overrideGroupKey'] as String?,
          );
          _flowLogService.logFlow(script: 'notification_service.dart - _onNotificationReceived', message: 'Convertido Map a ServiceNotificationEvent.');
        } catch (e, st) {
           _errorService.logError(
            script: 'notification_service.dart - _onNotificationReceived - Map conversion',
            error: e,
            stackTrace: st,
          );
          _flowLogService.logFlow(script: 'notification_service.dart - _onNotificationReceived - Map conversion', message: 'Error al convertir Map a ServiceNotificationEvent: ${e.toString()}');
          print('Error al convertir Map a ServiceNotificationEvent: $e');
          return; // Salir si la conversión falla
        }
      } else {
        // Si el tipo no es el esperado, registrar y salir
        _errorService.logError(
          script: 'notification_service.dart - _onNotificationReceived',
          error: 'Tipo de evento inesperado recibido: ${eventData.runtimeType}',
          stackTrace: StackTrace.current,
        );
        _flowLogService.logFlow(script: 'notification_service.dart - _onNotificationReceived', message: 'Tipo de evento inesperado recibido: ${eventData.runtimeType}.');
        print('Tipo de evento inesperado recibido: ${eventData.runtimeType}');
        return; // Salir si el tipo no es ServiceNotificationEvent ni Map
      }

      // Continuar solo si event no es null después de la conversión/verificación
      if (event == null) {
         _flowLogService.logFlow(script: 'notification_service.dart - _onNotificationReceived', message: 'Evento nulo después de la verificación/conversión.');
         print('Evento nulo después de la verificación/conversión.');
         return;
      }


      // Filtrar notificaciones por paquete si la lista de seleccionadas no está vacía
      if (_selectedAppPackages.isNotEmpty) {
        if (event.packageName != null && _selectedAppPackages.contains(event.packageName)) {
          _flowLogService.logFlow(script: 'notification_service.dart - _onNotificationReceived', message: 'Notificación recibida de ${event.packageName} (está en la lista de seleccionadas).');
          // Crear un NotificationItem a partir del evento
          final notificationItem = NotificationItem(
            id: event.id.toString(), // Convertir id a String
            appName: event.title ?? 'App desconocida',
            packageName: event.packageName!,
            title: event.title ?? 'Sin título', // Usar título del evento o un valor por defecto
            content: event.content ?? 'Sin contenido', // Usar texto del evento o un valor por defecto
            timestamp: DateTime.now(), // Usar timestamp del evento o la hora actual
            time: DateTime.now().toString().substring(11, 16),
            color: _getColorForApp(event.packageName), // Obtener color basado en el paquete
            iconData: _getIconForApp(event.packageName), // Obtener icono basado en el paquete
          );

          // Añadir la notificación al stream principal
          _notificationController.sink.add(notificationItem);
          _flowLogService.logFlow(script: 'notification_service.dart - _onNotificationReceived', message: 'Notificación añadida al stream principal.');
          // Opcional: Mostrar una notificación local (si es necesario para depuración o feedback)
          // await _showNotification(notificationItem);

        } else {
          _flowLogService.logFlow(
            script: 'notification_service.dart - _onNotificationReceived',
            message: 'Notificación recibida de ${event.packageName}: ${event.title}'
          );
          
          // Emitir la notificación al stream
          // _notificationController.add(notificationItem);
        }
      } else {
        _flowLogService.logFlow(
          script: 'notification_service.dart - _onNotificationReceived', 
          message: 'Notificación ignorada de ${event.packageName} (no está en la lista de seleccionadas)'
        );
      }
    } catch (e, st) {
      _errorService.logError(
        script: 'notification_service.dart - _onNotificationReceived',
        error: e,
        stackTrace: st,
      );
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