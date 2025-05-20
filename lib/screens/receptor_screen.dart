import 'package:flutter/material.dart';
import '../services/bluetooth_service.dart';
import '../models/notification_item.dart';

class ReceptorScreen extends StatefulWidget {
  @override
  _ReceptorScreenState createState() => _ReceptorScreenState();
}

class _ReceptorScreenState extends State<ReceptorScreen> {
  final BluetoothConnectionService _bluetoothService = BluetoothConnectionService();
  final TextEditingController _codeController = TextEditingController();
  bool _isConnected = false;
  List<NotificationItem> _notifications = [];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _bluetoothService.initialize();
    
    // Escuchar cambios en el estado de la conexión
    _bluetoothService.connectionStatus.listen((connected) {
      setState(() {
        _isConnected = connected;
      });
    });
    
    // Aquí deberías implementar la lógica para recibir notificaciones
    // y agregarlas a la lista _notifications
  }

  void _connectWithCode() async {
    // Aquí implementar la lógica para conectarse usando el código
    // Por ahora es un placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Intentando conectar con el código: ${_codeController.text}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Modo Receptor'),
      ),
      body: Column(
        children: [
          if (!_isConnected) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      labelText: 'Ingresa el código de vinculación',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _connectWithCode,
                    child: Text('Conectar'),
                  ),
                ],
              ),
            ),
          ],
          if (_isConnected) ...[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Conectado',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          Expanded(
            child: _notifications.isEmpty
                ? Center(child: Text('No hay notificaciones'))
                : ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return ListTile(
                        leading: Icon(
                          notification.iconData,
                          color: notification.color,
                        ),
                        title: Text(notification.title),
                        subtitle: Text(notification.content),
                        trailing: Text(notification.time),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}