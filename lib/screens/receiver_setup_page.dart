import 'package:conectados/services/bluetooth_service.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'notification_display_page.dart';
import '../widgets/permission_item.dart';

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

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    final bluetoothStatus = await Permission.bluetooth.status;
    final bluetoothConnectStatus = await Permission.bluetoothConnect.status;
    final bluetoothScanStatus = await Permission.bluetoothScan.status;

    setState(() {
      _bluetoothPermissionGranted =
          bluetoothStatus.isGranted &&
          bluetoothConnectStatus.isGranted &&
          bluetoothScanStatus.isGranted;
    });
  }

  Future<void> _requestPermissions() async {
    await Permission.bluetooth.request();
    await Permission.bluetoothConnect.request();
    await Permission.bluetoothScan.request();

    _checkPermissions();
  }

  void _connectToEmitter() {
    if (_codeController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El código debe tener 6 dígitos')),
      );
      return;
    }

    // Implementar la lógica de conexión Bluetooth
    final bluetoothService = BluetoothConnectionService();
    bluetoothService.initialize().then((_) {
      // Buscar dispositivos y conectar usando el código
      bluetoothService.discoverDevices().then((devices) {
        // Aquí deberíamos implementar la lógica para verificar el código
        // y conectar con el dispositivo correcto

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conectando... Por favor espere')),
        );

        // Por ahora, simplemente navegamos a la siguiente pantalla
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NotificationDisplayPage(),
          ),
        );
      });
    });
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
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración del Receptor')),
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
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
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
                    _isConnectionStatusCardExpanded =
                        !_isConnectionStatusCardExpanded;
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
