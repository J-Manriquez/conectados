import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import '../models/notification_item.dart';
import 'error_service.dart'; // Importar el servicio de errores

// Renombramos la clase para evitar conflicto con la clase del paquete
class BluetoothConnectionService {
  static final BluetoothConnectionService _instance = BluetoothConnectionService._internal();

  factory BluetoothConnectionService() {
    return _instance;
  }

  BluetoothConnectionService._internal();

  fbp.BluetoothDevice? _connectedDevice;
  fbp.BluetoothCharacteristic? _characteristic;

  final _receivedNotificationsController = StreamController<NotificationItem>.broadcast();
  Stream<NotificationItem> get receivedNotifications => _receivedNotificationsController.stream;

  // Stream para el estado de la conexión
  final _connectionStatusController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  // UUID para el servicio y característica de notificaciones
  final String _serviceUuid = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"; // Ejemplo de UUID
  final String _characteristicUuid = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"; // Ejemplo de UUID

  // Instancia del servicio de errores
  final ErrorService _errorService = ErrorService();

  // Método para inicializar el servicio Bluetooth
  Future<bool> initialize() async {
    try {
      // Verificar si el Bluetooth está habilitado
      bool isEnabled = await fbp.FlutterBluePlus.isOn;
      if (!isEnabled) {
        // Con flutter_blue_plus no podemos habilitar directamente el Bluetooth
        // El usuario debe habilitarlo manualmente
        return false;
      }

      // Inicialmente no hay conexión
      _connectionStatusController.add(false);
      return true;
    } catch (e, st) {
      // Registrar error de inicialización
      await _errorService.logError(
        script: 'bluetooth_service.dart - initialize',
        error: e,
        stackTrace: st,
      );
      print('Error al inicializar Bluetooth: $e');
      return false;
    }
  }

  // Método para generar código de vinculación
  String generatePairingCode() {
    // Generar un código aleatorio de 6 dígitos
    final random = Random();
    final code = List.generate(6, (_) => random.nextInt(10)).join();
    return code;
  }

  // Método para buscar dispositivos cercanos
  Future<List<fbp.ScanResult>> discoverDevices() async {
    try {
      List<fbp.ScanResult> devices = [];

      // Iniciar escaneo usando métodos estáticos con timeout aumentado
      fbp.FlutterBluePlus.startScan(timeout: Duration(seconds: 15)); // Aumentado a 15 segundos

      // Escuchar resultados del escaneo
      fbp.FlutterBluePlus.scanResults.listen((results) {
        devices = results;
      });

      // Esperar a que termine el escaneo
      await Future.delayed(const Duration(seconds: 15)); // Esperar el tiempo de escaneo
      fbp.FlutterBluePlus.stopScan();

      return devices;
    } catch (e, st) {
      // Registrar error de descubrimiento
      await _errorService.logError(
        script: 'bluetooth_service.dart - discoverDevices',
        error: e,
        stackTrace: st,
      );
      print('Error al descubrir dispositivos: $e');
      return [];
    }
  }

  // Método para conectar a un dispositivo
  Future<bool> connectToDevice(fbp.BluetoothDevice device) async {
    try {
      // Conectar al dispositivo
      await device.connect();
      _connectedDevice = device;

      // Descubrir servicios
      List<fbp.BluetoothService> services = await device.discoverServices();

      // Buscar el servicio y característica que necesitamos
      for (fbp.BluetoothService service in services) {
        if (service.uuid.toString().toUpperCase() == _serviceUuid.toUpperCase()) { // Comparar UUIDs sin importar mayúsculas/minúsculas
          for (fbp.BluetoothCharacteristic characteristic in service.characteristics) {
            if (characteristic.uuid.toString().toUpperCase() == _characteristicUuid.toUpperCase()) { // Comparar UUIDs
              _characteristic = characteristic;

              // Suscribirse a notificaciones
              await _characteristic!.setNotifyValue(true);
              _characteristic!.value.listen((value) {
                if (value.isNotEmpty) {
                  String message = utf8.decode(value);
                  try {
                    Map<String, dynamic> notificationMap = jsonDecode(message);
                    NotificationItem notification = NotificationItem.fromMap(notificationMap);
                    _receivedNotificationsController.add(notification);
                  } catch (e, st) {
                    // Registrar error al procesar notificación recibida
                    _errorService.logError(
                      script: 'bluetooth_service.dart - receivedNotification',
                      error: e,
                      stackTrace: st,
                    );
                    print('Error al procesar notificación recibida: $e');
                  }
                }
              });

              // Actualizar estado de conexión
              _connectionStatusController.add(true);
              print('Conectado y suscrito a notificaciones.');
              return true; // Conexión exitosa
            }
          }
        }
      }

      // Si llegamos aquí, no se encontró el servicio o la característica
      print('Servicio o característica no encontrados.');
      // Registrar error si no se encuentra el servicio/característica
       await _errorService.logError(
        script: 'bluetooth_service.dart - connectToDevice',
        error: 'Servicio o característica Bluetooth no encontrados',
        stackTrace: StackTrace.current,
      );
      await disconnect(); // Desconectar si no se encontró lo necesario
      return false;

    } catch (e, st) {
      // Registrar error de conexión
      await _errorService.logError(
        script: 'bluetooth_service.dart - connectToDevice',
        error: e,
        stackTrace: st,
      );
      print('Error al conectar al dispositivo: $e');
      await disconnect(); // Asegurarse de desconectar en caso de error
      return false;
    }
  }

  // Método para desconectar del dispositivo
  Future<void> disconnect() async {
    try {
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
        _connectedDevice = null;
        _characteristic = null;
        _connectionStatusController.add(false);
        print('Dispositivo desconectado.');
      }
    } catch (e, st) {
      // Registrar error de desconexión
      await _errorService.logError(
        script: 'bluetooth_service.dart - disconnect',
        error: e,
        stackTrace: st,
      );
      print('Error al desconectar: $e');
    }
  }

  // Método para enviar una notificación
  Future<void> sendNotification(NotificationItem notification) async {
    try {
      if (_characteristic != null) {
        String jsonString = notification.toJson();
        List<int> bytes = utf8.encode(jsonString);
        await _characteristic!.write(bytes, withoutResponse: true);
        print('Notificación enviada por Bluetooth: ${notification.title}');
      } else {
        print('No hay característica Bluetooth disponible para enviar notificación.');
         // Registrar error si no hay característica para enviar
        await _errorService.logError(
          script: 'bluetooth_service.dart - sendNotification',
          error: 'No hay característica Bluetooth disponible para enviar notificación.',
          stackTrace: StackTrace.current,
        );
      }
    } catch (e, st) {
      // Registrar error al enviar notificación
      await _errorService.logError(
        script: 'bluetooth_service.dart - sendNotification',
        error: e,
        stackTrace: st,
      );
      print('Error al enviar notificación por Bluetooth: $e');
    }
  }

  // Método para cerrar los streams
  void dispose() {
    _receivedNotificationsController.close();
    _connectionStatusController.close();
  }
}