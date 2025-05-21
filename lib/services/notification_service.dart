import 'dart:async';
import 'package:conectados/services/internet_connection_service.dart';
import 'package:conectados/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import '../models/notification_item.dart';
import '../models/app_info.dart';
import 'flow_log_service.dart'; // Importar FlowLogService
import 'error_service.dart'; // Importar ErrorService
import 'package:cloud_firestore/cloud_firestore.dart'; // Importar Firestore

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final StreamController<NotificationItem> _notificationController =
      StreamController<NotificationItem>.broadcast();
  Stream<NotificationItem> get notificationStream =>
      _notificationController.stream;

  List<String> _selectedAppPackages = [];

  final FlowLogService _flowLogService =
      FlowLogService(); // Instancia de FlowLogService
  final ErrorService _errorService =
      ErrorService(); // Instancia de ErrorService
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Instancia de Firestore

  Future<void> initialize() async {
    _flowLogService.logFlow(
      script: 'notification_service.dart - initialize',
      message: 'Iniciando servicio de notificaciones.',
    );
    try {
      // Inicializar awesome_notifications
      await AwesomeNotifications().initialize('resource://drawable/app_icon', [
        NotificationChannel(
          channelKey: 'conectados_channel',
          channelName: 'Notificaciones de Conectados',
          channelDescription:
              'Canal para notificaciones de la aplicación Conectados',
          defaultColor: Colors.blue,
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          playSound: true,
          enableVibration: true,
        ),
      ]);
      _flowLogService.logFlow(
        script: 'notification_service.dart - initialize',
        message: 'AwesomeNotifications inicializado.',
      );

      // Solicitar permisos de notificación
      await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
        if (!isAllowed) {
          _flowLogService.logFlow(
            script: 'notification_service.dart - initialize',
            message: 'Solicitando permisos de notificación.',
          );
          AwesomeNotifications().requestPermissionToSendNotifications();
        } else {
          _flowLogService.logFlow(
            script: 'notification_service.dart - initialize',
            message: 'Permisos de notificación ya concedidos.',
          );
        }
      });

      // Cargar aplicaciones seleccionadas
      _flowLogService.logFlow(
        script: 'notification_service.dart - _loadSelectedApps',
        message: 'Cargando aplicaciones seleccionadas.',
      );
      await _loadSelectedApps();
      _flowLogService.logFlow(
        script: 'notification_service.dart - _loadSelectedApps',
        message: 'Aplicaciones seleccionadas cargadas.',
      );

      // Iniciar el servicio de escucha de notificaciones
      _flowLogService.logFlow(
        script: 'notification_service.dart - initialize',
        message: 'Solicitando permiso para escuchar notificaciones.',
      );
      await NotificationListenerService.requestPermission();
      _flowLogService.logFlow(
        script: 'notification_service.dart - initialize',
        message:
            'Permiso para escuchar notificaciones concedido. Iniciando stream.',
      );
      NotificationListenerService.notificationsStream.listen(
        onNotificationReceived
            as void Function(ServiceNotificationEvent event)?,
      );
      _flowLogService.logFlow(
        script: 'notification_service.dart - initialize',
        message: 'Servicio de notificaciones inicializado completamente.',
      );
    } catch (e, st) {
      _errorService.logError(
        script: 'notification_service.dart - initialize',
        error: e,
        stackTrace: st,
      );
      _flowLogService.logFlow(
        script: 'notification_service.dart - initialize',
        message:
            'Error durante la inicialización del servicio de notificaciones: ${e.toString()}',
      );
    }
  }

  // Método para cargar las aplicaciones seleccionadas
  Future<void> _loadSelectedApps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedApps = prefs.getStringList('selectedApps') ?? [];
      _selectedAppPackages = selectedApps;
      _flowLogService.logFlow(
        script: 'notification_service.dart - _loadSelectedApps',
        message:
            'Aplicaciones seleccionadas cargadas: ${_selectedAppPackages.length}',
      );
    } catch (e, st) {
      _errorService.logError(
        script: 'notification_service.dart - _loadSelectedApps',
        error: e,
        stackTrace: st,
      );
    }
  }

  // Método para procesar las notificaciones recibidas
  // Método para manejar las notificaciones recibidas del MethodChannel
  // Acepta directamente un Map<String, dynamic> con los datos de la notificación
  Future<void> onNotificationReceived(Map<String, dynamic> notificationData) async {
    _flowLogService.logFlow(
      script: 'notification_service.dart - _onNotificationReceived',
      message: 'Notificación recibida del MethodChannel.',
    );
    print(
      '[_onNotificationReceived] Raw notificationData type: ${notificationData.runtimeType}',
    ); // Log: Tipo de dato recibido
    print(
      '[_onNotificationReceived] Raw notificationData: $notificationData',
    ); // Log: Contenido crudo del dato recibido

    try {
      // Extraer datos directamente del mapa recibido
      final packageName = notificationData['package'] as String?;
      final title = notificationData['title'] as String?;
      final text = notificationData['text'] as String?;
      // Generar un ID simple si no se proporciona uno desde Android
      final id = DateTime.now().millisecondsSinceEpoch.toString();

      print(
        '[_onNotificationReceived] Extracted packageName: $packageName',
      ); // Log: Paquete extraído
      print(
        '[_onNotificationReceived] Extracted title: $title',
      ); // Log: Título extraído
      print(
        '[_onNotificationReceived] Extracted text: $text',
      ); // Log: Texto extraído
      print(
        '[_onNotificationReceived] Selected app packages: $_selectedAppPackages',
      ); // Log: Lista de apps seleccionadas

      // Filtrar notificaciones por paquete si la lista de seleccionadas no está vacía
      // Si la lista de seleccionadas está vacía, procesar todas las notificaciones
      if (_selectedAppPackages.isEmpty ||
          (packageName != null && _selectedAppPackages.contains(packageName))) {
        _flowLogService.logFlow(
          script: 'notification_service.dart - _onNotificationReceived',
          message: 'Procesando notificación de $packageName.',
        );
        print(
          '[_onNotificationReceived] Package $packageName is in selected list or list is empty. Processing...',
        ); // Log: Paquete en lista o lista vacía

        // Crear un NotificationItem a partir de los datos extraídos
        final notificationItem = NotificationItem(
          id: id,
          appName: title ?? 'App desconocida', // Usar título como nombre de app
          packageName: packageName ?? 'unknown',
          title: title ?? 'Sin título',
          content: text ?? 'Sin contenido',
          timestamp: DateTime.now(),
          time: DateTime.now().toString().substring(11, 16),
          color: _getColorForApp(packageName),
          iconData: _getIconForApp(packageName),
        );

        print(
          '[_onNotificationReceived] NotificationItem created: ${notificationItem.toMap()}',
        ); // Log: NotificationItem creado

        // Añadir la notificación al stream principal (para la UI u otros listeners)
        _notificationController.sink.add(notificationItem);
        _flowLogService.logFlow(
          script: 'notification_service.dart - _onNotificationReceived',
          message: 'Notificación añadida al stream principal.',
        );
        print(
          '[_onNotificationReceived] NotificationItem added to stream.',
        ); // Log: Notificación añadida al stream

        // *** Guardar la notificación en Firebase ***
        _flowLogService.logFlow(
          script: 'notification_service.dart - _onNotificationReceived',
          message: 'Intentando guardar notificación en Firebase.',
        );
        print(
          '[_onNotificationReceived] Attempting to save notification to Firebase: ${notificationItem.title} - ${notificationItem.content}',
        ); // Log: Intentando guardar en Firebase (incluye contenido)

        await _firestore
            .collection('notifications')
            .add(notificationItem.toMap());

        _flowLogService.logFlow(
          script: 'notification_service.dart - _onNotificationReceived',
          message: 'Notificación guardada en Firebase.',
        );
        print(
          '[_onNotificationReceived] Notification saved to Firebase.',
        ); // Log: Notificación guardada en Firebase

        // *** Enviar por InternetConnectionService ***
        _flowLogService.logFlow(
          script: 'notification_service.dart - _onNotificationReceived',
          message: 'Intentando enviar notificación por InternetConnectionService.',
        );
        print(
          '[_onNotificationReceived] Attempting to send notification via InternetConnectionService: ${notificationItem.title} - ${notificationItem.content}',
        ); // Log: Intentando enviar por Internet (incluye contenido)

        try {
          final storageService = StorageService();
          final connectionMode = await storageService.getConnectionMode();
          final uniqueCode = await storageService.getUniqueCode();

          if (connectionMode == 'internet' && uniqueCode != null) {
            final internetService = InternetConnectionService();
            await internetService.sendNotification(
              uniqueCode,
              notificationItem,
            );
            _flowLogService.logFlow(
              script: 'notification_service.dart - _onNotificationReceived',
              message: 'Notificación enviada por Internet.',
            );
            print('[NotificationService] Notificación enviada por Internet.'); // Log: Enviada por Internet
          } else {
             _flowLogService.logFlow(
              script: 'notification_service.dart - _onNotificationReceived',
              message: 'No se cumplen las condiciones para enviar por Internet (modo: $connectionMode, uniqueCode: $uniqueCode).',
            );
            print('[NotificationService] No se cumplen las condiciones para enviar por Internet (modo: $connectionMode, uniqueCode: $uniqueCode).'); // Log: No enviada por Internet
          }
        } catch (e, st) {
          _errorService.logError(
            script: 'notification_service.dart - _onNotificationReceived - Internet Send',
            error: e,
            stackTrace: st,
          );
          _flowLogService.logFlow(
            script: 'notification_service.dart - _onNotificationReceived - Internet Send',
            message: 'Error enviando notificación por Internet: ${e.toString()}',
          );
          print(
            '[NotificationService] Error enviando notificación por Internet: $e',
          ); // Log: Error enviando por Internet
        }

        // Opcional: Mostrar una notificación local (si es necesario para depuración o feedback)
        // await _showNotification(notificationItem);
      } else {
        _flowLogService.logFlow(
          script: 'notification_service.dart - _onNotificationReceived',
          message:
              'Notificación ignorada de $packageName (no está en la lista de seleccionadas)',
        );
        print(
          '[_onNotificationReceived] Package $packageName is NOT in selected list. Ignoring.',
        ); // Log: Paquete no está en lista seleccionada
      }
    } catch (e, st) {
      _errorService.logError(
        script: 'notification_service.dart - _onNotificationReceived',
        error: e,
        stackTrace: st,
      );
      print(
        '[_onNotificationReceived] Caught error: $e',
      ); // Log: Error capturado
    }
  }

  Future<void> _showNotification(NotificationItem notification) async {
    _flowLogService.logFlow(
      script: 'notification_service.dart - _showNotification',
      message: 'Mostrando notificación local para: ${notification.title}',
    );
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
          icon:
              'resource://drawable/app_icon', // Considerar usar un icono específico si es posible
          payload: {'packageName': notification.packageName},
        ),
      );
      _flowLogService.logFlow(
        script: 'notification_service.dart - _showNotification',
        message: 'Notificación local mostrada con éxito.',
      );
    } catch (e, st) {
      _errorService.logError(
        script: 'notification_service.dart - _showNotification',
        error: e,
        stackTrace: st,
      );
      _flowLogService.logFlow(
        script: 'notification_service.dart - _showNotification',
        message: 'Error al mostrar notificación local: ${e.toString()}',
      );
    }
  }

  Color _getColorForApp(String? packageName) {
    _flowLogService.logFlow(
      script: 'notification_service.dart - _getColorForApp',
      message: 'Obteniendo color para el paquete: $packageName',
    );
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
    _flowLogService.logFlow(
      script: 'notification_service.dart - _getIconForApp',
      message: 'Obteniendo icono para el paquete: $packageName',
    );
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
    _flowLogService.logFlow(
      script: 'notification_service.dart - updateSelectedApps',
      message: 'Actualizando lista de aplicaciones seleccionadas.',
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      _selectedAppPackages =
          apps
              .where((app) => app.isSelected)
              .map((app) => app.packageName)
              .toList();

      await prefs.setStringList('selected_apps', _selectedAppPackages);
      _flowLogService.logFlow(
        script: 'notification_service.dart - updateSelectedApps',
        message:
            'Lista de aplicaciones seleccionadas actualizada y guardada: ${_selectedAppPackages.length} paquetes.',
      );
    } catch (e, st) {
      _errorService.logError(
        script: 'notification_service.dart - updateSelectedApps',
        error: e,
        stackTrace: st,
      );
      _flowLogService.logFlow(
        script: 'notification_service.dart - updateSelectedApps',
        message:
            'Error al actualizar aplicaciones seleccionadas: ${e.toString()}',
      );
    }
  }

  void dispose() {
    _flowLogService.logFlow(
      script: 'notification_service.dart - dispose',
      message: 'Cerrando stream de notificaciones.',
    );
    _notificationController.close();
  }
}
