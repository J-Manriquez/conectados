import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:awesome_notifications/awesome_notifications.dart';
import 'bluetooth_service.dart';
import 'notification_service.dart';
import '../models/notification_item.dart';

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();
  
  Future<void> initialize() async {
    // Inicializar awesome_notifications
    await AwesomeNotifications().initialize(
      // Icono de la aplicación por defecto
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
    
    // Solicitar permisos de notificación
    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
    
    // Inicializar servicio en segundo plano
    final service = FlutterBackgroundService();
    
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'conectados_channel',
        initialNotificationTitle: 'Conectados',
        initialNotificationContent: 'Ejecutándose en segundo plano',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
    
    service.startService();
  }
  
  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }
  
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    
    // Inicializar awesome_notifications en el servicio
    await AwesomeNotifications().initialize(
      'resource://drawable/app_icon',
      [
        NotificationChannel(
          channelKey: 'conectados_channel',
          channelName: 'Notificaciones de Conectados',
          channelDescription: 'Canal para notificaciones de la aplicación Conectados',
          defaultColor: Colors.blue,
          ledColor: Colors.white,
          importance: NotificationImportance.High
        ),
      ]
    );
    
    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });
      
      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }
    
    service.on('stopService').listen((event) {
      service.stopSelf();
    });
    
    // Inicializar servicios
    final notificationService = NotificationService();
    await notificationService.initialize();
    
    final bluetoothService = BluetoothConnectionService();
    await bluetoothService.initialize();
    
    // Escuchar notificaciones y enviarlas por Bluetooth
    notificationService.notificationStream.listen((notification) async {
      // Enviar notificación por Bluetooth si hay conexión
      await bluetoothService.sendNotification(notification);
      
      // Mostrar notificación local usando awesome_notifications
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: 'conectados_channel',
          title: notification.title,
          body: notification.content,
          color: notification.color,
          notificationLayout: NotificationLayout.Default,
        ),
      );
    });
    
    // Mantener el servicio vivo
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          service.setForegroundNotificationInfo(
            title: "Conectados",
            content: "Ejecutándose en segundo plano",
          );
        }
      }
      
      service.invoke('update', {
        'current_date': DateTime.now().toIso8601String(),
      });
    });
  }
  
  // Método para mostrar una notificación
  Future<void> showNotification(NotificationItem notification) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'conectados_channel',
        title: notification.title,
        body: notification.content,
        color: notification.color,
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }
}