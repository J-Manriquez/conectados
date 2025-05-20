import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:math';
import '../services/bluetooth_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart'; // Importar StorageService
import '../services/error_service.dart';
import '../services/flow_log_service.dart';
import '../models/notification_item.dart';
import '../services/internet_connection_service.dart'; // Importar el nuevo servicio
import 'package:permission_handler/permission_handler.dart'; // Importar permission_handler
import 'app_selection_page.dart'; // Asegurarse de que AppSelectionPage está importado

class EmitterScreen extends StatefulWidget {
  const EmitterScreen({super.key});

  @override
  _EmitterScreenState createState() => _EmitterScreenState();
}

class _EmitterScreenState extends State<EmitterScreen> {
  final BluetoothConnectionService _bluetoothService = BluetoothConnectionService();
  final NotificationService _notificationService = NotificationService();
  final StorageService _storageService = StorageService();
  final ErrorService _errorService = ErrorService();
  final FlowLogService _flowLogService = FlowLogService();
  final InternetConnectionService _internetConnectionService = InternetConnectionService();

  String _pairingCode = 'Generando...';
  bool _isConnected = false;
  String _connectionStatusText = 'Desconectado';
  // Nuevo estado para el modo de conexión
  String _connectionMode = 'bluetooth'; // 'bluetooth' o 'internet'
  // Nuevo estado para el toggle del modo de conexión
  bool _isInternetMode = false; // Añadida la variable _isInternetMode
  // Nuevo estado para los permisos Bluetooth
  bool _bluetoothPermissionGranted = false;


  @override
  void initState() {
    super.initState();
    _flowLogService.logFlow(script: 'emitter_screen.dart - initState', message: 'Inicializando pantalla del emisor.');
    _checkPermissions(); // Llamar al método de verificación de permisos
    _loadConnectionMode(); // Cargar el modo de conexión guardado
    _loadUniqueCode(); // Cargar o generar el código único

    // Suscribirse al estado de conexión Bluetooth
    _bluetoothService.connectionStatus.listen((isConnected) {
      if (_connectionMode == 'bluetooth') { // Solo actualizar si estamos en modo Bluetooth
        setState(() {
          _isConnected = isConnected;
          _updateConnectionStatusText(); // Usar el método para actualizar el texto
        });
        _flowLogService.logFlow(script: 'emitter_screen.dart - connectionStatusStream', message: 'Estado de conexión Bluetooth actualizado: $_connectionStatusText.');
      }
    });

    // Suscribirse a las notificaciones recibidas
    _notificationService.notificationStream.listen((notification) {
      _flowLogService.logFlow(script: 'emitter_screen.dart - notificationsStream', message: 'Notificación recibida de NotificationService: ${notification.title}.');
      if (_connectionMode == 'bluetooth') {
        // Enviar por Bluetooth si el modo es Bluetooth
        _bluetoothService.sendNotification(notification);
      } else {
        // Enviar por Internet si el modo es Internet
        _internetConnectionService.sendNotification(notification, _pairingCode);
      }
    });
  }

  // Método para verificar permisos Bluetooth (adaptado de receiver_screen.dart)
  Future<void> _checkPermissions() async {
    try {
      _flowLogService.logFlow(script: 'emitter_screen.dart - _checkPermissions', message: 'Verificando permisos Bluetooth.');
      final bluetoothStatus = await Permission.bluetooth.status;
      final bluetoothConnectStatus = await Permission.bluetoothConnect.status;
      final bluetoothScanStatus = await Permission.bluetoothScan.status;
      final bluetoothAdvertiseStatus = await Permission.bluetoothAdvertise.status; // Añadir permiso de publicidad

      setState(() {
        _bluetoothPermissionGranted =
            bluetoothStatus.isGranted &&
            bluetoothConnectStatus.isGranted &&
            bluetoothScanStatus.isGranted &&
            bluetoothAdvertiseStatus.isGranted; // Incluir permiso de publicidad
        _flowLogService.logFlow(script: 'emitter_screen.dart - _checkPermissions', message: 'Permisos Bluetooth verificados. Concedidos: $_bluetoothPermissionGranted');
      });
    } catch (e, st) {
      _errorService.logError(
        script: 'emitter_screen.dart - _checkPermissions',
        error: e,
        stackTrace: st,
      );
      _flowLogService.logFlow(script: 'emitter_screen.dart - _checkPermissions', message: 'Error al verificar permisos: ${e.toString()}');
    }
  }

  // Método para solicitar permisos Bluetooth (adaptado de receiver_screen.dart)
  Future<void> _requestPermissions() async {
    try {
      _flowLogService.logFlow(script: 'emitter_screen.dart - _requestPermissions', message: 'Solicitando permisos Bluetooth.');
      await Permission.bluetooth.request();
      await Permission.bluetoothConnect.request();
      await Permission.bluetoothScan.request();
      await Permission.bluetoothAdvertise.request(); // Solicitar permiso de publicidad

      _checkPermissions();
      _flowLogService.logFlow(script: 'emitter_screen.dart - _requestPermissions', message: 'Solicitud de permisos Bluetooth completada.');
    } catch (e, st) {
      _errorService.logError(
        script: 'emitter_screen.dart - _requestPermissions',
        error: e,
        stackTrace: st,
      );
      _flowLogService.logFlow(script: 'emitter_screen.dart - _requestPermissions', message: 'Error al solicitar permisos: ${e.toString()}');
    }
  }

  // Cargar el modo de conexión guardado
  Future<void> _loadConnectionMode() async {
    final mode = await _storageService.getConnectionMode();
    setState(() {
      _connectionMode = mode;
      _isInternetMode = (mode == 'internet');
      _updateConnectionStatusText(); // Actualizar texto basado en el modo cargado
    });
     _flowLogService.logFlow(script: 'emitter_screen.dart - _loadConnectionMode', message: 'Modo de conexión cargado: $_connectionMode.');
  }

  // Cargar o generar el código único
  Future<void> _loadUniqueCode() async {
    String? code = await _storageService.getUniqueCode();
    if (code == null) {
      // Generar un nuevo código si no existe
      code = _generateUniqueCode();
      await _storageService.saveUniqueCode(code);
      _flowLogService.logFlow(script: 'emitter_screen.dart - _loadUniqueCode', message: 'Código único generado y guardado: $code.');
    } else {
       _flowLogService.logFlow(script: 'emitter_screen.dart - _loadUniqueCode', message: 'Código único cargado: $code.');
    }
    setState(() {
      _pairingCode = code!;
    });
  }

  // Generar un código único de 6 dígitos (ahora fijo por usuario)
  String _generateUniqueCode() {
    _flowLogService.logFlow(script: 'emitter_screen.dart - _generateUniqueCode', message: 'Generando código único de 6 dígitos.');
    final random = Random();
    String code = '';
    for (int i = 0; i < 6; i++) {
      code += random.nextInt(10).toString();
    }
    return code;
  }

  // Actualizar el texto de estado de conexión basado en el modo
  void _updateConnectionStatusText() {
    if (_connectionMode == 'bluetooth') {
      _connectionStatusText = _isConnected ? 'Conectado por Bluetooth' : 'Desconectado';
    } else {
      // Para el modo Internet, el estado "conectado" es cuando el receptor se conecta
      // Inicialmente, el emisor está "Esperando conexión por Internet"
      _connectionStatusText = 'Esperando conexión por Internet...';
      // TODO: Implementar lógica para detectar si un receptor se ha conectado por Internet
      // Esto podría implicar escuchar cambios en el documento de Firestore.
    }
     setState(() {}); // Forzar reconstrucción para actualizar el texto
     _flowLogService.logFlow(script: 'emitter_screen.dart - _updateConnectionStatusText', message: 'Texto de estado de conexión actualizado: $_connectionStatusText.');
  }

  @override
  Widget build(BuildContext context) {
    _flowLogService.logFlow(script: 'emitter_screen.dart - build', message: 'Construyendo UI de la pantalla del emisor.');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emisor'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Código de Vinculación',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        _pairingCode,
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Eliminar el botón "Generar Nuevo Código"
                    // Center(
                    //   child: ElevatedButton(
                    //     onPressed: () {
                    //       _flowLogService.logFlow(script: 'emitter_screen.dart - build', message: 'Botón "Generar Nuevo Código" presionado.');
                    //       _generateUniqueCode(); // Usar _generateUniqueCode
                    //     },
                    //     child: const Text('Generar Nuevo Código'),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estado de Conexión',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      // Toggle para seleccionar el modo de conexión
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Modo de Conexión:'),
                          Switch(
                            value: _isInternetMode,
                            onChanged: (value) async {
                              setState(() {
                                _isInternetMode = value;
                                _connectionMode = value ? 'internet' : 'bluetooth';
                              });
                              await _storageService.saveConnectionMode(_connectionMode); // Guardar la preferencia
                              _updateConnectionStatusText(); // Actualizar texto de estado
                              _flowLogService.logFlow(script: 'emitter_screen.dart - build', message: 'Toggle de modo de conexión cambiado a: $_connectionMode.');

                              // TODO: Implementar lógica para iniciar/detener servicios según el modo
                              if (_connectionMode == 'internet') {
                                // Iniciar servicio de conexión por Internet (crear/actualizar documento en Firestore)
                                _flowLogService.logFlow(script: 'emitter_screen.dart - build', message: 'Cambiando a modo Internet. Iniciando emisor.');
                                // Asegurarse de que _pairingCode ya esté cargado/generado
                                _flowLogService.logFlow(script: 'emitter_screen.dart - build', message: 'Valor actual de _pairingCode: $_pairingCode'); // Añadir este log
                                if (_pairingCode != 'Generando...') {
                                  _flowLogService.logFlow(script: 'emitter_screen.dart - build', message: 'Llamando a startEmitter con código: $_pairingCode'); // Añadir este log
                                  await _internetConnectionService.startEmitter(_pairingCode);
                                  // Opcional: detener servicios Bluetooth si estaban activos
                                  // _bluetoothService.stopAdvertising(); // Si tienes un método para detener publicidad
                                  // _bluetoothService.stopScanning(); // Si tienes un método para detener escaneo
                                } else {
                                   _flowLogService.logFlow(script: 'emitter_screen.dart - build', message: 'Código de emparejamiento no disponible al intentar iniciar emisor Internet.');
                                }
                              } else {
                                // Cambiando a modo Bluetooth
                                _flowLogService.logFlow(script: 'emitter_screen.dart - build', message: 'Cambiando a modo Bluetooth.');
                                // Opcional: detener servicio de Internet (actualizar estado en Firestore)
                                if (_pairingCode != 'Generando...') {
                                  await _internetConnectionService.stopEmitter(_pairingCode);
                                }
                                // Iniciar servicios Bluetooth (escaneo/publicidad) si es necesario
                                // Esto dependerá de tu implementación actual de Bluetooth en el emisor
                                // Por ejemplo: _bluetoothService.startAdvertising();
                              }
                            },
                          ),
                          Text(_connectionMode == 'bluetooth' ? 'Bluetooth' : 'Internet'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          _connectionStatusText,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Mostrar indicador de progreso solo en modo Bluetooth o cuando se espera conexión Internet
                      if (_connectionMode == 'bluetooth' && !_isConnected)
                         const Center(
                           child: CircularProgressIndicator(),
                         ),
                      if (_connectionMode == 'internet')
                         const Center(
                           child: CircularProgressIndicator(), // O un indicador diferente para Internet
                         ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  try {
                    _flowLogService.logFlow(script: 'emitter_screen.dart - build', message: 'Botón "Continuar a Selección de Apps" presionado.');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AppSelectionPage(),
                      ),
                    );
                  } catch (e, st) {
                    _errorService.logError(
                      script: 'emitter_screen.dart - App Selection Button',
                      error: e,
                      stackTrace: st,
                    );
                     _flowLogService.logFlow(script: 'emitter_screen.dart - build', message: 'Error al navegar a Selección de Apps: ${e.toString()}');
                  }
                },
                child: const Text('Continuar a Selección de Apps'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _flowLogService.logFlow(script: 'emitter_screen.dart - dispose', message: 'Liberando recursos de la pantalla del emisor.');
    // No cerramos los streams aquí porque los servicios son singletons y se usan en segundo plano
    // _bluetoothService.dispose(); // Esto podría detener el servicio de fondo
    super.dispose();
  }
}