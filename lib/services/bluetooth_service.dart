import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../models/notification_item.dart';

class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  
  factory BluetoothService() {
    return _instance;
  }
  
  BluetoothService._internal();
  
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  BluetoothConnection? _connection;
  
  final _receivedNotificationsController = StreamController<NotificationItem>.broadcast();
  Stream<NotificationItem> get receivedNotifications => _receivedNotificationsController.stream;
  
  // Stream para el estado de la conexión
  final _connectionStatusController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStatus => _connectionStatusController.stream;
  
  // Método para inicializar el servicio Bluetooth
  Future<bool> initialize() async {
    try {
      // Verificar si el Bluetooth está habilitado
      bool isEnabled = await _bluetooth.isEnabled ?? false;
      if (!isEnabled) {
        await _bluetooth.requestEnable();
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
  Future<List<BluetoothDevice>> discoverDevices() async {
    try {
      List<BluetoothDevice> devices = [];
      
      // Iniciar descubrimiento
      _bluetooth.startDiscovery().listen((result) {
        if (result.device.name != null) {
          devices.add(result.device);
        }
      });
      
      // Esperar un tiempo para el descubrimiento
      await Future.delayed(const Duration(seconds: 10));
      
      return devices;
    } catch (e) {
      print('Error al descubrir dispositivos: $e');
      return [];
    }
  }
  
  // Método para conectar a un dispositivo
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      _connection = await BluetoothConnection.toAddress(device.address);
      
      // Actualizar estado de conexión
      _connectionStatusController.add(true);
      
      // Escuchar datos entrantes
      _connection?.input?.listen((data) {
        String message = utf8.decode(data);
        try {
          Map<String, dynamic> notificationMap = jsonDecode(message);
          NotificationItem notification = NotificationItem.fromMap(notificationMap);
          _receivedNotificationsController.add(notification);
        } catch (e) {
          print('Error al procesar notificación recibida: $e');
        }
      });
      
      return true;
    } catch (e) {
      print('Error al conectar con dispositivo: $e');
      _connectionStatusController.add(false);
      return false;
    }
  }
  
  // Método para enviar una notificación
  Future<bool> sendNotification(NotificationItem notification) async {
    if (_connection == null || !(_connection?.isConnected ?? false)) {
      return false;
    }
    
    try {
      _connection?.output.add(utf8.encode(notification.toJson()));
      await _connection?.output.allSent;
      return true;
    } catch (e) {
      print('Error al enviar notificación: $e');
      return false;
    }
  }
  
  // Método para desconectar
  Future<void> disconnect() async {
    await _connection?.close();
    _connection = null;
    _connectionStatusController.add(false);
  }
  
  // Método para limpiar recursos
  void dispose() {
    _receivedNotificationsController.close();
    _connectionStatusController.close();
    disconnect();
  }
}