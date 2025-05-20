import 'package:conectados/services/bluetooth_service.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'notification_display_page.dart';
import '../widgets/permission_item.dart';
import '../services/error_service.dart'; // Importar el servicio de errores
import '../services/flow_log_service.dart'; // Importar el nuevo servicio de flujo

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

  @override
  void initState() {
    super.initState();
    _flowLogService.logFlow(script: 'receiver_screen.dart - initState', message: 'Inicializando pantalla del receptor.');
    _checkPermissions();
  }

  @override
  void dispose() {
    _flowLogService.logFlow(script: 'receiver_screen.dart - dispose', message: 'Liberando recursos de la pantalla del receptor.');
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    try {
      _flowLogService.logFlow(script: 'receiver_screen.dart - _checkPermissions', message: 'Verificando permisos Bluetooth.');
      final bluetoothStatus = await Permission.bluetooth.status;
      final bluetoothConnectStatus = await Permission.bluetoothConnect.status;
      final bluetoothScanStatus = await Permission.bluetoothScan.status;

      setState(() {
        _bluetoothPermissionGranted =
            bluetoothStatus.isGranted &&
            bluetoothConnectStatus.isGranted &&
            bluetoothScanStatus.isGranted;
        _flowLogService.logFlow(script: 'receiver_screen.dart - _checkPermissions', message: 'Permisos Bluetooth verificados. Concedidos: $_bluetoothPermissionGranted');
      });
    } catch (e, st) {
      _errorService.logError(
        script: 'receiver_screen.dart - _checkPermissions',
        error: e,
        stackTrace: st,
      );
      _flowLogService.logFlow(script: 'receiver_screen.dart - _checkPermissions', message: 'Error al verificar permisos: ${e.toString()}');
    }
  }

  Future<void> _requestPermissions() async {
    try {
      _flowLogService.logFlow(script: 'receiver_screen.dart - _requestPermissions', message: 'Solicitando permisos Bluetooth.');
      await Permission.bluetooth.request();
      await Permission.bluetoothConnect.request();
      await Permission.bluetoothScan.request();

      _checkPermissions();
      _flowLogService.logFlow(script: 'receiver_screen.dart - _requestPermissions', message: 'Solicitud de permisos Bluetooth completada.');
    } catch (e, st) {
      _errorService.logError(
        script: 'receiver_screen.dart - _requestPermissions',
        error: e,
        stackTrace: st,
      );
      _flowLogService.logFlow(script: 'receiver_screen.dart - _requestPermissions', message: 'Error al solicitar permisos: ${e.toString()}');
    }
  }

  void _connectToEmitter() {
    try {
      _flowLogService.logFlow(script: 'receiver_screen.dart - _connectToEmitter', message: 'Iniciando proceso de conexión.');
      if (_codeController.text.length != 6) {
        _flowLogService.logFlow(script: 'receiver_screen.dart - _connectToEmitter', message: 'Código de vinculación inválido.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El código debe tener 6 dígitos')),
        );
        return;
      }

      _flowLogService.logFlow(script: 'receiver_screen.dart - _connectToEmitter', message: 'Código de vinculación válido. Inicializando servicio Bluetooth.');
      // Implementar la lógica de conexión Bluetooth
      final bluetoothService = BluetoothConnectionService();
      bluetoothService.initialize().then((_) {
        _flowLogService.logFlow(script: 'receiver_screen.dart - _connectToEmitter', message: 'Servicio Bluetooth inicializado. Buscando dispositivos.');
        // Buscar dispositivos y conectar usando el código
        bluetoothService.discoverDevices().then((devices) {
          _flowLogService.logFlow(script: 'receiver_screen.dart - _connectToEmitter', message: 'Dispositivos encontrados: ${devices.length}.');
          // Aquí deberíamos implementar la lógica para verificar el código
          // y conectar con el dispositivo correcto

          _flowLogService.logFlow(script: 'receiver_screen.dart - _connectToEmitter', message: 'Lógica de conexión con dispositivo específico pendiente.');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Conectando... Por favor espere')),
          );

          // Por ahora, simplemente navegamos a la siguiente pantalla
          _flowLogService.logFlow(script: 'receiver_screen.dart - _connectToEmitter', message: 'Navegando a la pantalla de visualización de notificaciones (temporal).');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NotificationDisplayPage(),
            ),
          );
        }).catchError((e, st) { // Capturar errores en la cadena de Future
           _errorService.logError(
            script: 'receiver_screen.dart - _connectToEmitter - discoverDevices',
            error: e,
            stackTrace: st,
          );
           _flowLogService.logFlow(script: 'receiver_screen.dart - _connectToEmitter', message: 'Error al buscar dispositivos: ${e.toString()}');
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al buscar dispositivos: ${e.toString()}')),
          );
        });
      }).catchError((e, st) { // Capturar errores en la cadena de Future
         _errorService.logError(
          script: 'receiver_screen.dart - _connectToEmitter - initialize',
          error: e,
          stackTrace: st,
        );
         _flowLogService.logFlow(script: 'receiver_screen.dart - _connectToEmitter', message: 'Error al inicializar Bluetooth: ${e.toString()}');
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al inicializar Bluetooth: ${e.toString()}')),
        );
      });
    } catch (e, st) {
      _errorService.logError(
        script: 'receiver_screen.dart - _connectToEmitter',
        error: e,
        stackTrace: st,
      );
       _flowLogService.logFlow(script: 'receiver_screen.dart - _connectToEmitter', message: 'Error general en el proceso de conexión: ${e.toString()}');
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error general al conectar: ${e.toString()}')),
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
                        onPressed: _connectToEmitter,
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
                     _flowLogService.logFlow(script: 'receiver_screen.dart - build', message: 'Card "Estado de la Conexión" ${_isConnectionStatusCardExpanded ? "expandida" : "colapsada"}.');
                  });
                },
                content: const Center(
                  child: Text(
                    'Esperando ingreso del código...',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              // Espacio adicional al final para evitar que el contenido quede oculto por el teclado
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
