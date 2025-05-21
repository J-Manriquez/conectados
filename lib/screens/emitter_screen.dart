import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:conectados/screens/captured_notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
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
  String _connectionMode = 'bluetooth';
  bool _isInternetMode = false;
  bool _bluetoothPermissionGranted = false;
  // Añadir variable para el permiso de notificaciones
  bool _notificationPermissionGranted = false;
  Map<String, List<NotificationItem>> _capturedNotifications = {};

  // Estado para controlar la expansión de las tarjetas
  bool _isConnectionStatusCardExpanded = false;
  bool _isAppSelectionCardExpanded = false;


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
      // Añadir la notificación a la lista local y agruparla
      setState(() {
        if (!_capturedNotifications.containsKey(notification.packageName)) {
          _capturedNotifications[notification.packageName] = [];
        }
        _capturedNotifications[notification.packageName]!.add(notification);
      });

      // Guardar SIEMPRE en la colección global (esto debería estar en NotificationService, pero asegúrate que así sea)
      // _notificationService.saveNotificationToGlobal(notification);

      // Enviar SIEMPRE al documento de conexión de Internet (si tienes pairing code válido)
      if (_pairingCode != null && _pairingCode != 'Generando...') {
        _flowLogService.logFlow(script: 'emitter_screen.dart - notificationsStream', message: 'Enviando notificación a Internet con pairing code: $_pairingCode.');
        _internetConnectionService.sendNotification(_pairingCode, notification);
      } else {
        _flowLogService.logFlow(script: 'emitter_screen.dart - notificationsStream', message: 'No se pudo enviar la notificación a Internet. Pairing code no válido.');
      }

      // Enviar por Bluetooth SOLO si el modo es Bluetooth
      if (_connectionMode == 'bluetooth') {
        _bluetoothService.sendNotification(notification);
      }
    });
  }

  // Método para verificar permisos Bluetooth (adaptado de receiver_screen.dart)
  Future<void> _checkPermissions() async {
    try {
      _flowLogService.logFlow(script: 'emitter_screen.dart - _checkPermissions', message: 'Verificando permisos Bluetooth y notificaciones.');
      final bluetoothStatus = await Permission.bluetooth.status;
      final bluetoothConnectStatus = await Permission.bluetoothConnect.status;
      final bluetoothScanStatus = await Permission.bluetoothScan.status;
      final bluetoothAdvertiseStatus = await Permission.bluetoothAdvertise.status;
      
      // Verificar permiso de acceso a notificaciones
      final notificationListenerStatus = await NotificationListenerService.isPermissionGranted();

      setState(() {
        _bluetoothPermissionGranted =
            bluetoothStatus.isGranted &&
            bluetoothConnectStatus.isGranted &&
            bluetoothScanStatus.isGranted &&
            bluetoothAdvertiseStatus.isGranted;
            
        final _notificationPermissionGranted = notificationListenerStatus;
        
        _flowLogService.logFlow(
          script: 'emitter_screen.dart - _checkPermissions', 
          message: 'Permisos verificados. Bluetooth: $_bluetoothPermissionGranted, Notificaciones: $_notificationPermissionGranted'
        );
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

  // Método para solicitar permisos
  Future<void> _requestPermissions() async {
    try {
      _flowLogService.logFlow(script: 'emitter_screen.dart - _requestPermissions', message: 'Solicitando permisos Bluetooth y notificaciones.');
      await Permission.bluetooth.request();
      await Permission.bluetoothConnect.request();
      await Permission.bluetoothScan.request();
      await Permission.bluetoothAdvertise.request();
      
      // Solicitar permiso de acceso a notificaciones
      final notificationPermissionGranted = await NotificationListenerService.requestPermission();
      if (notificationPermissionGranted) {
        _flowLogService.logFlow(script: 'emitter_screen.dart - _requestPermissions', message: 'Permiso de notificaciones concedido.');
        // Inicializar el servicio de notificaciones después de obtener el permiso
        await _notificationService.initialize();
      } else {
        _flowLogService.logFlow(script: 'emitter_screen.dart - _requestPermissions', message: 'Permiso de notificaciones denegado.');
        // Mostrar un mensaje al usuario
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Se requiere acceso a las notificaciones para el funcionamiento correcto de la aplicación.'),
            duration: Duration(seconds: 5),
          ),
        );
      }

      _checkPermissions();
      _flowLogService.logFlow(script: 'emitter_screen.dart - _requestPermissions', message: 'Solicitud de permisos completada.');
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

  // Método para actualizar el texto de estado de conexión
  void _updateConnectionStatusText({String status = 'Desconectado', String mode = 'none'}) {
    setState(() {
      // Si el modo es internet y está conectado, mostrar "Conectado por Internet"
      if (_connectionMode == 'internet' && _isConnected) {
        _connectionStatusText = 'Conectado por Internet';
      }
      // Si el modo es bluetooth y está conectado, mostrar "Conectado por Bluetooth"
      else if (_connectionMode == 'bluetooth' && _isConnected) {
         _connectionStatusText = 'Conectado por Bluetooth';
      }
      // Si no está conectado, mostrar el estado por defecto o un mensaje de conexión
      else {
         // Aquí puedes añadir lógica más detallada si necesitas estados como "Conectando..."
         // Por ahora, si no está conectado, simplemente mostramos "Desconectado"
         _connectionStatusText = 'Desconectado';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _flowLogService.logFlow(script: 'emitter_screen.dart - build', message: 'Construyendo UI de la pantalla del emisor.');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emisor'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card de Código de Vinculación
              Card(
                elevation: 2.0,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
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
                      // Eliminar el botón "Generar Nuevo Código" si ya no es necesario
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Card de Estado de Conexión
              Card(
                elevation: 2.0,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: ExpansionTile(
                  title: const Text('Estado de Conexión'),
                  initiallyExpanded: _isConnectionStatusCardExpanded,
                  onExpansionChanged: (expanded) {
                    setState(() {
                      _isConnectionStatusCardExpanded = expanded;
                    });
                  },
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                    // Al cambiar de modo, asumimos que la conexión se pierde hasta que se establezca en el nuevo modo
                                    _isConnected = false; // Resetear estado de conexión
                                  });
                                  await _storageService.saveConnectionMode(_connectionMode); // Guardar la preferencia
                                  _updateConnectionStatusText(); // Actualizar texto de estado
                                  _flowLogService.logFlow(script: 'emitter_screen.dart - build', message: 'Toggle de modo de conexión cambiado a: $_connectionMode.');

                                  // TODO: Implementar lógica para iniciar/detener servicios según el modo
                                  if (_connectionMode == 'internet') {
                                    // Iniciar servicio de conexión por Internet (crear/actualizar documento en Firestore)
                                    _flowLogService.logFlow(script: 'emitter_screen.dart - build', message: 'Cambiando a modo Internet. Iniciando emisor.');
                                    if (_pairingCode != 'Generando...') {
                                      _flowLogService.logFlow(script: 'emitter_screen.dart - build', message: 'Llamando a startEmitter con código: $_pairingCode');
                                      await _internetConnectionService.startEmitter(_pairingCode);
                                      // Actualizar el estado a 'connected' en Firestore
                                      await FirebaseFirestore.instance
                                        .collection('internet_connections')
                                        .doc(_pairingCode)
                                        .update({'status': 'connected', 'lastUpdated': FieldValue.serverTimestamp()});
                                      setState(() {
                                        _isConnected = true;
                                        _updateConnectionStatusText();
                                      });
                                    }
                                  // Opcional: detener servicios Bluetooth si estaban activos
                                  // _bluetoothService.stopAdvertising(); // Si tienes un método para detener publicidad
                                  // _bluetoothService.stopScanning(); // Si tienes un método para detener escaneo
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
                                    // El estado de conexión Bluetooth se actualizará a través de la suscripción a _bluetoothService.connectionStatus
                                  }
                                },
                              ),
                              Text(_connectionMode == 'bluetooth' ? 'Bluetooth' : 'Internet'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Row( // Usar Row para alinear el texto y el indicador
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Mostrar CircularProgressIndicator solo si no está conectado
                                if (!_isConnected)
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                if (!_isConnected) const SizedBox(width: 8), // Espacio entre indicador y texto
                                Text(
                                  _connectionStatusText,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Card de Selección de Aplicaciones
              Card(
                elevation: 2.0,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: ExpansionTile(
                  title: const Text('Selección de Aplicaciones'),
                   initiallyExpanded: _isAppSelectionCardExpanded,
                   onExpansionChanged: (expanded) {
                     setState(() {
                       _isAppSelectionCardExpanded = expanded;
                     });
                   },
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Selecciona las aplicaciones cuyas notificaciones deseas enviar:',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              _flowLogService.logFlow(script: 'emitter_screen.dart - build', message: 'Botón "Seleccionar Aplicaciones" presionado.');
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AppSelectionPage(),
                                ),
                              );
                            },
                            child: const Text('Seleccionar Aplicaciones'),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              _flowLogService.logFlow(script: 'emitter_screen.dart - build', message: 'Botón "Solicitar Permisos de Notificación" presionado.');
                              _requestPermissions();
                            },
                            child: const Text('Solicitar Permisos de Notificación'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Nuevo Card para Herramientas de Emisor (incluye el botón de notificaciones capturadas)
              Card(
                elevation: 2.0,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Herramientas de Emisor',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // Navegar a la nueva pantalla de notificaciones capturadas
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CapturedNotificationsScreen(),
                            ),
                          );
                        },
                        child: const Text('Ver Notificaciones Capturadas'),
                      ),
                      // Puedes añadir más botones o herramientas aquí en el futuro
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}