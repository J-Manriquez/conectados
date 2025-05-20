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
    
    // Escuchar notificaciones recibidas
    _bluetoothService.receivedNotifications.listen((notification) {
      setState(() {
        _notifications.insert(0, notification); // Añadir al principio para mostrar las más recientes primero
      });
    });
  }

  void _connectWithCode() async {
    if (_codeController.text.isEmpty || _codeController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor ingresa un código de 6 dígitos')),
      );
      return;
    }
    
    // Mostrar indicador de progreso
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Intentando conectar con el código: ${_codeController.text}')),
    );
    
    // Implementar la lógica real de conexión aquí
    // Por ahora es un placeholder
  }

  @override
  Widget build(BuildContext context) {
    // Detectar si estamos en una pantalla pequeña (smartwatch)
    final isSmallScreen = MediaQuery.of(context).size.width < 200;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Modo Receptor',
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 20,
          ),
        ),
        toolbarHeight: isSmallScreen ? 40 : 56,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_isConnected) ...[
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Conectar dispositivo',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        TextField(
                          controller: _codeController,
                          decoration: InputDecoration(
                            labelText: 'Código de vinculación',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 8 : 12,
                              vertical: isSmallScreen ? 8 : 12,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          style: TextStyle(fontSize: isSmallScreen ? 12 : 16),
                        ),
                        SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _connectWithCode,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                vertical: isSmallScreen ? 8 : 12,
                              ),
                            ),
                            child: Text(
                              'Conectar',
                              style: TextStyle(fontSize: isSmallScreen ? 12 : 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (_isConnected) ...[
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
                    child: Row(
                      children: [
                        Icon(Icons.bluetooth_connected, 
                          color: Colors.green,
                          size: isSmallScreen ? 16 : 24,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Conectado',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 12 : 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              SizedBox(height: 8),
              Text(
                'Notificaciones',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Container(
                height: isSmallScreen ? 200 : 400,
                child: _notifications.isEmpty
                    ? Center(
                        child: Text(
                          'No hay notificaciones',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 16,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final notification = _notifications[index];
                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                              leading: CircleAvatar(
                                backgroundColor: notification.color,
                                radius: isSmallScreen ? 12 : 20,
                                child: Icon(
                                  notification.iconData,
                                  size: isSmallScreen ? 12 : 20,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                notification.title,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 12 : 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                notification.content,
                                style: TextStyle(fontSize: isSmallScreen ? 10 : 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Text(
                                notification.time,
                                style: TextStyle(fontSize: isSmallScreen ? 9 : 12),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}