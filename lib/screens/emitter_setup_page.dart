import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math';
import 'app_selection_page.dart';
import '../widgets/permission_item.dart';

class EmitterSetupPage extends StatefulWidget {
  const EmitterSetupPage({super.key});

  @override
  State<EmitterSetupPage> createState() => _EmitterSetupPageState();
}

class _EmitterSetupPageState extends State<EmitterSetupPage> {
  bool _notificationPermissionGranted = false;
  bool _bluetoothPermissionGranted = false;
  String _pairingCode = '';
  
  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _generatePairingCode();
  }
  
  Future<void> _checkPermissions() async {
    final notificationStatus = await Permission.notification.status;
    final bluetoothStatus = await Permission.bluetooth.status;
    final bluetoothConnectStatus = await Permission.bluetoothConnect.status;
    final bluetoothScanStatus = await Permission.bluetoothScan.status;
    
    setState(() {
      _notificationPermissionGranted = notificationStatus.isGranted;
      _bluetoothPermissionGranted = bluetoothStatus.isGranted && 
                                   bluetoothConnectStatus.isGranted && 
                                   bluetoothScanStatus.isGranted;
    });
  }
  
  Future<void> _requestPermissions() async {
    await Permission.notification.request();
    await Permission.bluetooth.request();
    await Permission.bluetoothConnect.request();
    await Permission.bluetoothScan.request();
    
    _checkPermissions();
  }
  
  void _generatePairingCode() {
    final random = Random();
    String code = '';
    for (int i = 0; i < 6; i++) {
      code += random.nextInt(10).toString();
    }
    setState(() {
      _pairingCode = code;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración del Emisor'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estado de Permisos',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    PermissionItem(
                      title: 'Notificaciones',
                      isGranted: _notificationPermissionGranted,
                    ),
                    const SizedBox(height: 8),
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
            ),
            const SizedBox(height: 16),
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
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        'Ingresa este código en tu dispositivo receptor',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton(
                        onPressed: _generatePairingCode,
                        child: const Text('Generar Nuevo Código'),
                      ),
                    ),
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
                      const Center(
                        child: Text(
                          'Esperando conexión del dispositivo receptor...',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Center(
                        child: CircularProgressIndicator(),
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AppSelectionPage(),
                    ),
                  );
                },
                child: const Text('Continuar a Selección de Apps'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}