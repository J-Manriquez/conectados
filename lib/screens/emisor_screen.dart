import 'package:flutter/material.dart';
import '../services/bluetooth_service.dart';
import '../services/notification_service.dart';

class EmisorScreen extends StatefulWidget {
  @override
  _EmisorScreenState createState() => _EmisorScreenState();
}

class _EmisorScreenState extends State<EmisorScreen> {
  final BluetoothService _bluetoothService = BluetoothService();
  final NotificationService _notificationService = NotificationService();
  String _pairingCode = '';
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _bluetoothService.initialize();
    await _notificationService.initialize();
    
    // Generar código de vinculación
    setState(() {
      _pairingCode = _bluetoothService.generatePairingCode();
    });
    
    // Escuchar cambios en el estado de la conexión
    _bluetoothService.connectionStatus.listen((connected) {
      setState(() {
        _isConnected = connected;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Modo Emisor'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Código de vinculación:',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              _pairingCode,
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 30),
            Text(
              'Estado: ${_isConnected ? 'Conectado' : 'Desconectado'}',
              style: TextStyle(
                fontSize: 16,
                color: _isConnected ? Colors.green : Colors.red,
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/app_selection');
              },
              child: Text('Seleccionar Aplicaciones'),
            ),
          ],
        ),
      ),
    );
  }
}