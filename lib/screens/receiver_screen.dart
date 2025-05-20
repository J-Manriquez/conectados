import 'package:conectados/services/bluetooth_service.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'notification_display_page.dart';
import '../widgets/permission_item.dart';
import '../services/error_service.dart'; // Importar el servicio de errores
import '../services/flow_log_service.dart'; // Importar el nuevo servicio de flujo
import '../services/internet_connection_service.dart'; // Importar el servicio de Internet
import '../services/storage_service.dart'; // Importar StorageService
import '../models/notification_item.dart'; // Importar NotificationItem
import 'dart:async'; // Importar para StreamSubscription y Stream
import 'package:cloud_firestore/cloud_firestore.dart'; // Importar Firestore

class ReceiverSetupPage extends StatefulWidget {
  const ReceiverSetupPage({super.key});

  @override
  State<ReceiverSetupPage> createState() => _ReceiverSetupPageState();
}

class _ReceiverSetupPageState extends State<ReceiverSetupPage> {
  bool _bluetoothPermissionGranted = false;
  final TextEditingController _codeController = TextEditingController();

  // Variables para controlar la visibilidad de cada card
  bool _isPermissionsCardExpanded = false;
  bool _isPairingCodeCardExpanded = false;
  bool _isConnectionStatusCardExpanded = false;

  // Instancia del servicio de errores
  final ErrorService _errorService = ErrorService();
  // Instancia del nuevo servicio de flujo
  final FlowLogService _flowLogService = FlowLogService();
  // Instancia del servicio de Internet
  final InternetConnectionService _internetConnectionService = InternetConnectionService();
  // Instancia de StorageService
  final StorageService _storageService = StorageService();
  // Instancia de Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Instancia del servicio Bluetooth (asegúrate de que esté inicializada si es necesario)
  final BluetoothConnectionService _bluetoothService = BluetoothConnectionService();


  // Variables para el modo de conexión (el receptor no tiene toggle, solo muestra el estado)
  String _connectionMode = 'none'; // 'bluetooth', 'internet', o 'none'
  String _connectionStatusText = 'Desconectado'; // Texto de estado

  // StreamSubscription para escuchar notificaciones por Internet
  StreamSubscription<List<NotificationItem>>? _internetNotificationsSubscription;
  // Lista de notificaciones recibidas por Internet (ya no es la fuente principal para la pantalla de visualización)
  // final List<NotificationItem> _internetNotifications = []; // Ya no necesitamos esta lista aquí

  // TODO: StreamSubscription para notificaciones Bluetooth
  StreamSubscription<NotificationItem>? _bluetoothNotificationsSubscription;


  // StreamController para combinar notificaciones de ambos orígenes
  final StreamController<List<NotificationItem>> _combinedNotificationsController = StreamController<List<NotificationItem>>.broadcast();


  @override
  void initState() {
    super.initState();
    _flowLogService.logFlow(script: 'receiver_screen.dart - initState', message: 'Inicializando pantalla del receptor.');
    _checkPermissions();
    // Ya no necesitamos cargar el modo de conexión guardado aquí, el emisor lo controla.
    // _loadConnectionMode();
    _updateConnectionStatusText(); // Establecer el texto de estado inicial
  }

  @override
  void dispose() {
    _codeController.dispose();
    _internetNotificationsSubscription?.cancel(); // Cancelar la suscripción al stream de Internet
    _bluetoothNotificationsSubscription?.cancel(); // Cancelar suscripción al stream de Bluetooth
    _combinedNotificationsController.close(); // Cerrar el StreamController
    _flowLogService.logFlow(script: 'receiver_screen.dart - dispose', message: 'Liberando recursos de la pantalla del receptor.');
    super.dispose();
  }

  // Ya no necesitamos _loadConnectionMode ni _updateConnectionStatusText como antes
  // La actualización del estado se hará dentro de _connectToEmitter

  // Actualizar el texto de estado de conexión basado en el modo
  void _updateConnectionStatusText({String status = 'Desconectado', String mode = 'none'}) {
     setState(() {
       _connectionMode = mode;
       if (mode == 'bluetooth') {
         _connectionStatusText = status == 'connected' ? 'Conectado por Bluetooth' : 'Desconectado por Bluetooth';
       } else if (mode == 'internet') {
          _connectionStatusText = status == 'connected' ? 'Conectado por Internet' : status; // Usar el estado directo para Internet (Conectando..., Esperando código...)
       } else {
         _connectionStatusText = status; // Estado general (Desconectado, Buscando...)
       }
     });
     _flowLogService.logFlow(script: 'receiver_screen.dart - _updateConnectionStatusText', message: 'Texto de estado de conexión actualizado: $_connectionStatusText (Modo: $_connectionMode).');
  }


  // Método para verificar permisos (ya existente, asegúrate de que incluya Bluetooth)
  Future<void> _checkPermissions() async {
    try {
      _flowLogService.logFlow(script: 'receiver_screen.dart - _checkPermissions', message: 'Verificando permisos Bluetooth.');
      final bluetoothScanStatus = await Permission.bluetoothScan.status;
      final bluetoothConnectStatus = await Permission.bluetoothConnect.status;

      setState(() {
        _bluetoothPermissionGranted = bluetoothScanStatus.isGranted && bluetoothConnectStatus.isGranted;
      });

      if (!_bluetoothPermissionGranted) {
        _flowLogService.logFlow(script: 'receiver_screen.dart - _checkPermissions', message: 'Permisos Bluetooth no concedidos.');
        // Puedes solicitar permisos aquí si quieres que se haga automáticamente al iniciar
        // _requestPermissions();
      } else {
         _flowLogService.logFlow(script: 'receiver_screen.dart - _checkPermissions', message: 'Permisos Bluetooth concedidos.');
      }
    } catch (e, st) {
      _errorService.logError(
        script: 'receiver_screen.dart - _checkPermissions',
        error: e,
        stackTrace: st,
      );
      _flowLogService.logFlow(script: 'receiver_screen.dart - _checkPermissions', message: 'Error al verificar permisos: ${e.toString()}');
    }
  }

  // Método para solicitar permisos Bluetooth (adaptado para receptor)
  Future<void> _requestPermissions() async {
    try {
      _flowLogService.logFlow(script: 'receiver_screen.dart - _requestPermissions', message: 'Solicitando permisos Bluetooth para receptor.');
      // Solicitar permisos de escaneo y conexión para el receptor
      final Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();

      setState(() {
        _bluetoothPermissionGranted = statuses[Permission.bluetoothScan]!.isGranted && statuses[Permission.bluetoothConnect]!.isGranted;
      });

      if (_bluetoothPermissionGranted) {
        _flowLogService.logFlow(script: 'receiver_screen.dart - _requestPermissions', message: 'Permisos Bluetooth concedidos.');
      } else {
        _flowLogService.logFlow(script: 'receiver_screen.dart - _requestPermissions', message: 'Permisos Bluetooth no concedidos.');
        // Opcional: Mostrar un mensaje al usuario si los permisos no fueron concedidos
      }
    } catch (e, st) {
      _errorService.logError(
        script: 'receiver_screen.dart - _requestPermissions',
        error: e,
        stackTrace: st,
      );
      _flowLogService.logFlow(script: 'receiver_screen.dart - _requestPermissions', message: 'Error al solicitar permisos Bluetooth: ${e.toString()}');
    }
  }

  // Método principal para iniciar la conexión (ahora maneja ambos modos)
  void _connectToEmitter() async {
    try {
      _flowLogService.logFlow(script: 'receiver_screen.dart - _connectToEmitter', message: 'Iniciando proceso de conexión.');
      final uniqueCode = _codeController.text.trim();

      if (uniqueCode.length != 6) {
        _flowLogService.logFlow(script: 'receiver_screen.dart - _connectToEmitter', message: 'Código de vinculación inválido.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El código debe tener 6 dígitos')),
        );
        return;
      }

      _updateConnectionStatusText(status: 'Verificando código...');

      // 1. Intentar conexión por Internet
      _flowLogService.logFlow(script: 'receiver_screen.dart - _connectToEmitter', message: 'Intentando conexión por Internet con código: $uniqueCode.');
      final docSnapshot = await _firestore.collection('internet_connections').doc(uniqueCode).get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        // Verificar si el emisor está configurado para Internet (podríamos añadir un campo 'mode' en el documento)
        // Por ahora, asumimos que si el documento existe, el emisor *podría* estar en modo Internet.
        // Una verificación más robusta podría ser necesaria.
        _flowLogService.logFlow(script: 'receiver_screen.dart - _connectToEmitter', message: 'Documento de conexión por Internet encontrado. Intentando conectar por Internet.');
        _startInternetConnection(uniqueCode); // Iniciar la conexión por Internet
        // La actualización del estado y la navegación se manejarán dentro de _startInternetConnection
      } else {
        // 2. Si no hay documento de Internet, intentar conexión por Bluetooth
        _flowLogService.logFlow(script: 'receiver_screen.dart - _connectToEmitter', message: 'Documento de conexión por Internet no encontrado. Intentando conexión por Bluetooth.');
        _startBluetoothConnection(uniqueCode); // Iniciar la conexión por Bluetooth
        // La actualización del estado y la navegación se manejarán dentro de _startBluetoothConnection
      }

    } catch (e, st) {
      _errorService.logError(
        script: 'receiver_screen.dart - _connectToEmitter',
        error: e,
        stackTrace: st,
      );
       _flowLogService.logFlow(script: 'receiver_screen.dart - _connectToEmitter', message: 'Error general en el proceso de conexión: ${e.toString()}');
       _updateConnectionStatusText(status: 'Error al conectar');
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al conectar: ${e.toString()}')),
      );
    }
  }


  // Método para iniciar la conexión por Internet como receptor
  void _startInternetConnection(String uniqueCode) {
    _flowLogService.logFlow(script: 'receiver_screen.dart - _startInternetConnection', message: 'Intentando iniciar conexión por Internet con código: $uniqueCode.');

    // Cancelar suscripciones anteriores si existen
    _internetNotificationsSubscription?.cancel();
    _bluetoothNotificationsSubscription?.cancel(); // Cancelar también la de Bluetooth si estaba activa
    // _internetNotifications.clear(); // Ya no necesitamos limpiar esta lista

    _updateConnectionStatusText(status: 'Conectando por Internet...', mode: 'internet');

    final notificationsStream = _internetConnectionService.connectReceiver(uniqueCode);

    if (notificationsStream != null) {
      _flowLogService.logFlow(script: 'receiver_screen.dart - _startInternetConnection', message: 'Suscrito al stream de notificaciones por Internet.');

      // Suscribirse al stream de Internet y añadir las notificaciones al StreamController combinado
      _internetNotificationsSubscription = notificationsStream.listen(
        (notifications) {
          // Notificaciones recibidas
          _flowLogService.logFlow(script: 'receiver_screen.dart - _startInternetConnection', message: 'Notificaciones recibidas por stream de Internet: ${notifications.length}.');
          // Añadir las notificaciones al StreamController combinado
          _combinedNotificationsController.sink.add(notifications);

          setState(() {
            _updateConnectionStatusText(status: 'connected', mode: 'internet'); // Actualizar estado a conectado
          });
          // Navegar a la pantalla de visualización de notificaciones si no estamos ya allí
           _navigateToNotificationDisplay();
        },
        onError: (e, st) {
          // Error en el stream
          _errorService.logError(
            script: 'receiver_screen.dart - _startInternetConnection - stream.listen',
            error: e,
            stackTrace: st,
          );
          _flowLogService.logFlow(script: 'receiver_screen.dart - _startInternetConnection - stream.listen', message: 'Error en el stream de notificaciones por Internet: ${e.toString()}');
          _updateConnectionStatusText(status: 'Error de conexión por Internet', mode: 'internet');
          _internetNotificationsSubscription?.cancel(); // Cancelar suscripción en caso de error
        },
        onDone: () {
          // Stream cerrado
          _flowLogService.logFlow(script: 'receiver_screen.dart - _startInternetConnection - stream.listen', message: 'Stream de notificaciones por Internet cerrado.');
          _updateConnectionStatusText(status: 'Conexión por Internet cerrada', mode: 'internet');
        }
      );
    } else {
      // connectReceiver retornó null (código inválido o error inicial)
       _flowLogService.logFlow(script: 'receiver_screen.dart - _startInternetConnection', message: 'connectReceiver retornó null. Código inválido o error inicial.');
       _updateConnectionStatusText(status: 'Código inválido o error', mode: 'internet'); // TODO: Mensaje más específico
    }
  }

  // Método para detener la conexión por Internet (opcional)
  void _stopInternetConnection() async {
     _flowLogService.logFlow(script: 'receiver_screen.dart - _stopInternetConnection', message: 'Deteniendo conexión por Internet.');
     _internetNotificationsSubscription?.cancel();
     _internetNotificationsSubscription = null;
     // Opcional: Actualizar estado en Firestore si es necesario
     final uniqueCode = _codeController.text.trim();
     if (uniqueCode.isNotEmpty) {
       await _internetConnectionService.disconnectReceiver(uniqueCode);
     }
     _updateConnectionStatusText(status: 'Desconectado por Internet', mode: 'internet');
     // No limpiamos el StreamController aquí, solo la suscripción de esta fuente.
     // El StreamController se cierra en dispose.
  }

  // Método para iniciar la conexión Bluetooth (ya existente o a implementar)
  void _startBluetoothConnection(String uniqueCode) {
    _flowLogService.logFlow(script: 'receiver_screen.dart - _startBluetoothConnection', message: 'Intentando iniciar conexión por Bluetooth con código: $uniqueCode.');

    // Cancelar suscripciones anteriores si existen
    _internetNotificationsSubscription?.cancel(); // Cancelar también la de Internet si estaba activa
    _bluetoothNotificationsSubscription?.cancel();

    _updateConnectionStatusText(status: 'Buscando dispositivos Bluetooth...', mode: 'bluetooth');

    // TODO: Implementar lógica para iniciar escaneo/conexión Bluetooth en el receptor
    // Usar el uniqueCode para identificar el dispositivo emisor (esto requerirá que el emisor publicite su código)

    // Ejemplo de cómo manejar el stream de Bluetooth y añadirlo al StreamController combinado:
    // Asumiendo que BluetoothConnectionService tiene un stream como `receivedNotifications`
    // y que emite `NotificationItem` individualmente.
    // Necesitamos mapearlo a `Stream<List<NotificationItem>>` o añadir individualmente.
    // Si emite individualmente (Stream<NotificationItem>):
    /*
    _bluetoothNotificationsSubscription = _bluetoothService.receivedNotifications.listen(
      (notification) {
        _flowLogService.logFlow(script: 'receiver_screen.dart - _startBluetoothConnection', message: 'Notificación recibida por Bluetooth.');
        // Añadir la notificación al StreamController combinado como una lista de un solo elemento
        _combinedNotificationsController.sink.add([notification]);
        setState(() {
           _updateConnectionStatusText(status: 'connected', mode: 'bluetooth'); // Actualizar estado a conectado
        });
        _navigateToNotificationDisplay(); // Navegar si no estamos ya allí
      },
      onError: (e, st) {
         _errorService.logError(script: 'receiver_screen.dart - _startBluetoothConnection - stream.listen', error: e, stackTrace: st);
         _flowLogService.logFlow(script: 'receiver_screen.dart - _startBluetoothConnection', message: 'Error en el stream de notificaciones por Bluetooth: ${e.toString()}');
         _updateConnectionStatusText(status: 'Error Bluetooth', mode: 'bluetooth');
         _bluetoothNotificationsSubscription?.cancel();
      },
      onDone: () {
         _flowLogService.logFlow(script: 'receiver_screen.dart - _startBluetoothConnection', message: 'Stream de notificaciones por Bluetooth cerrado.');
         _updateConnectionStatusText(status: 'Conexión por Bluetooth cerrada', mode: 'bluetooth');
      }
    );
    */

    // Si el servicio Bluetooth ya emite Stream<List<NotificationItem>>, la suscripción sería más simple:
    /*
    final bluetoothStream = _bluetoothService.bluetoothNotificationsStream; // Asumiendo que existe este stream
    _bluetoothNotificationsSubscription = bluetoothStream.listen(
      (notifications) {
        _flowLogService.logFlow(script: 'receiver_screen.dart - _startBluetoothConnection', message: 'Notificaciones recibidas por stream de Bluetooth: ${notifications.length}.');
        _combinedNotificationsController.sink.add(notifications);
        setState(() {
           _updateConnectionStatusText(status: 'connected', mode: 'bluetooth'); // Actualizar estado a conectado
        });
        _navigateToNotificationDisplay(); // Navegar si no estamos ya allí
      },
      onError: (e, st) { ... },
      onDone: () { ... }
    );
    */

    // Por ahora, solo actualizamos el estado y navegamos (la suscripción real debe ir en el TODO)
     setState(() {
        _updateConnectionStatusText(status: 'Conectando por Bluetooth...', mode: 'bluetooth');
     });
     // _navigateToNotificationDisplay(); // Navegar aquí si la conexión es exitosa y el stream está listo
  }

  // Método para detener la conexión Bluetooth (ya existente o a implementar)
  void _stopBluetoothConnection() {
     _flowLogService.logFlow(script: 'receiver_screen.dart - _stopBluetoothConnection', message: 'Deteniendo conexión por Bluetooth.');
     // TODO: Implementar lógica para detener escaneo/conexión Bluetooth en el receptor
     // Ejemplo: _bluetoothService.stopScanning();
     // Ejemplo: _bluetoothService.disconnect();
     _bluetoothNotificationsSubscription?.cancel();
     _bluetoothNotificationsSubscription = null;
     _updateConnectionStatusText(status: 'Desconectado por Bluetooth', mode: 'bluetooth');
     // No limpiamos el StreamController aquí, solo la suscripción de esta fuente.
  }

  // Método para navegar a la pantalla de visualización de notificaciones
  void _navigateToNotificationDisplay() {
     // Verificar si ya estamos en esa pantalla para evitar duplicados
     bool alreadyOnDisplayPage = false;
     Navigator.popUntil(context, (route) {
       if (route.settings.name == '/notificationDisplay') { // Usar un nombre de ruta si lo tienes
         alreadyOnDisplayPage = true;
         return true;
       }
       return true;
     });

     // Solo navegar si el StreamController combinado está activo y no estamos ya en la página
     if (!alreadyOnDisplayPage && !_combinedNotificationsController.isClosed) {
        _flowLogService.logFlow(script: 'receiver_screen.dart - _navigateToNotificationDisplay', message: 'Navegando a la pantalla de visualización de notificaciones.');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NotificationDisplayPage(
              // Pasar el stream combinado
              notificationsStream: _combinedNotificationsController.stream,
            ),
            settings: const RouteSettings(name: '/notificationDisplay'), // Opcional: añadir nombre de ruta
          ),
        );
     } else if (alreadyOnDisplayPage) {
        _flowLogService.logFlow(script: 'receiver_screen.dart - _navigateToNotificationDisplay', message: 'Ya en la pantalla de visualización de notificaciones.');
        // Si ya estamos en la pantalla, no hacemos nada. La pantalla ya está escuchando el stream combinado.
     } else { // _combinedNotificationsController.isClosed
        _flowLogService.logFlow(script: 'receiver_screen.dart - _navigateToNotificationDisplay', message: 'El StreamController combinado está cerrado. No se puede navegar.');
        // Opcional: Mostrar un mensaje al usuario si no hay conexión activa
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay conexión activa para mostrar notificaciones')),
        );
     }
  }


  // Widget reutilizable para crear cards con control de visibilidad
  Widget _buildCard({
    required String title,
    required bool isExpanded,
    required VoidCallback onToggleExpanded,
    required Widget content,
  }) {
    return Card(
      child: Column(
        children: [
          // Cabecera de la card con el título y el icono de visibilidad
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                IconButton(
                  icon: Icon(
                    isExpanded ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: onToggleExpanded,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Contenido de la card que se muestra/oculta
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                bottom: 16.0,
              ),
              child: content,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _flowLogService.logFlow(script: 'receiver_screen.dart - build', message: 'Construyendo UI de la pantalla del receptor.');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modo Receptor'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCard(
                title: 'Estado de Permisos',
                isExpanded: _isPermissionsCardExpanded,
                onToggleExpanded: () {
                  setState(() {
                    _isPermissionsCardExpanded = !_isPermissionsCardExpanded;
                    _flowLogService.logFlow(script: 'receiver_screen.dart - build', message: 'Card "Verificar Permisos" ${_isPermissionsCardExpanded ? "expandida" : "colapsada"}.');
                  });
                },
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PermissionItem(
                      title: 'Bluetooth',
                      isGranted: _bluetoothPermissionGranted,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _requestPermissions,
                      child: const Text('Solicitar Permisos'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildCard(
                title: 'Código de Vinculación',
                isExpanded: _isPairingCodeCardExpanded,
                onToggleExpanded: () {
                  setState(() {
                    _isPairingCodeCardExpanded = !_isPairingCodeCardExpanded;
                     _flowLogService.logFlow(script: 'receiver_screen.dart - build', message: 'Card "Ingresar Código" ${_isPairingCodeCardExpanded ? "expandida" : "colapsada"}.');
                  });
                },
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Código de 6 dígitos',
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, letterSpacing: 8),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _connectToEmitter, // Llama al método unificado
                        child: const Text('Conectar'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildCard(
                title: 'Estado de Conexión',
                isExpanded: _isConnectionStatusCardExpanded,
                onToggleExpanded: () {
                  setState(() {
                    _isConnectionStatusCardExpanded = !_isConnectionStatusCardExpanded;
                     _flowLogService.logFlow(script: 'receiver_screen.dart - build', message: 'Card "Estado de Conexión" ${_isConnectionStatusCardExpanded ? "expandida" : "colapsada"}.');
                  });
                },
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        _connectionStatusText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          // Color basado en el estado de conexión
                          color: _connectionStatusText.contains('Conectado') ? Colors.green : (_connectionStatusText.contains('Error') ? Colors.red : Colors.orange),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Mostrar indicador de progreso cuando se está conectando
                    if (_connectionStatusText.contains('Conectando') || _connectionStatusText.contains('Buscando') || _connectionStatusText.contains('Verificando'))
                         const Center(
                           child: CircularProgressIndicator(),
                         ),
                    // Ya no mostramos la lista de notificaciones aquí, se muestran en NotificationDisplayPage
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
