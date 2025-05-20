import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import '../models/notification_item.dart';

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
    } catch (e) {
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
      
      // Iniciar escaneo usando métodos estáticos
      fbp.FlutterBluePlus.startScan(timeout: Duration(seconds: 10));
      
      // Escuchar resultados del escaneo
      fbp.FlutterBluePlus.scanResults.listen((results) {
        devices = results;
      });
      
      // Esperar a que termine el escaneo
      await Future.delayed(const Duration(seconds: 10));
      fbp.FlutterBluePlus.stopScan();
      
      return devices;
    } catch (e) {
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
        if (service.uuid.toString() == _serviceUuid) {
          for (fbp.BluetoothCharacteristic characteristic in service.characteristics) {
            if (characteristic.uuid.toString() == _characteristicUuid) {
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
                  } catch (e) {
                    print('Error al procesar notificación recibida: $e');
                  }
                }
              });
              
              // Actualizar estado de conexión
              _connectionStatusController.add(true);
              return true;
            }
          }
        }
      }
      
      // Si llegamos aquí, no encontramos el servicio o característica
      await disconnect();
      return false;
    } catch (e) {
      print('Error al conectar con dispositivo: $e');
      _connectionStatusController.add(false);
      return false;
    }
  }
  
  // Método para enviar una notificación
  Future<bool> sendNotification(NotificationItem notification) async {
    if (_connectedDevice == null || _characteristic == null) {
      return false;
    }
    
    try {
      List<int> data = utf8.encode(notification.toJson());
      await _characteristic!.write(data);
      return true;
    } catch (e) {
      print('Error al enviar notificación: $e');
      return false;
    }
  }
  
  // Método para desconectar
  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
      _characteristic = null;
      _connectionStatusController.add(false);
    }
  }
  
  // Método para limpiar recursos
  void dispose() {
    _receivedNotificationsController.close();
    _connectionStatusController.close();
    disconnect();
  }
}