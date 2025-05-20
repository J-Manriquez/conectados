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
  // Controlador para el scroll
  final ScrollController _scrollController = ScrollController();
  // Map para almacenar el estado de visibilidad de cada notificación
  final Map<int, bool> _visibilityStatus = {};

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
        _visibilityStatus[0] = true; // La nueva notificación es visible por defecto
        // Actualizar los índices de las notificaciones existentes
        for (int i = 1; i < _notifications.length; i++) {
          if (_visibilityStatus.containsKey(i - 1)) {
            _visibilityStatus[i] = _visibilityStatus[i - 1]!;
          } else {
            _visibilityStatus[i] = true;
          }
        }
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

  // Función para alternar la visibilidad de una notificación
  void _toggleVisibility(int index) {
    setState(() {
      _visibilityStatus[index] = !(_visibilityStatus[index] ?? true);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Detectar si estamos en una pantalla muy pequeña (smartwatch)
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 200;
    
    return Scaffold(
      // Eliminamos AppBar para maximizar espacio en pantalla
      body: SafeArea(
        // Usamos LayoutBuilder para obtener el tamaño disponible
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              controller: _scrollController,
              physics: AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 4.0 : 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título con botón de retroceso integrado
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back, 
                              size: isSmallScreen ? 16 : 24,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          Text(
                            'Modo Receptor',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 4 : 8),
                      
                      if (!_isConnected) ...[
                        // Sección de conexión simplificada
                        Text(
                          'Ingresa el código:',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 16,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 4 : 8),
                        // Código de entrada más grande y fácil de usar
                        TextField(
                          controller: _codeController,
                          decoration: InputDecoration(
                            hintText: '123456',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 8 : 12,
                              vertical: isSmallScreen ? 8 : 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLength: 6,
                          buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                        ),
                        SizedBox(height: isSmallScreen ? 4 : 8),
                        // Botón grande para facilitar la pulsación
                        SizedBox(
                          width: double.infinity,
                          height: isSmallScreen ? 40 : 50,
                          child: ElevatedButton(
                            onPressed: _connectWithCode,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'CONECTAR',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                      
                      if (_isConnected) ...[
                        // Indicador de conexión más compacto
                        Container(
                          padding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? 4 : 8,
                            horizontal: isSmallScreen ? 8 : 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bluetooth_connected, 
                                color: Colors.green,
                                size: isSmallScreen ? 14 : 20,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Conectado',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isSmallScreen ? 12 : 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      SizedBox(height: isSmallScreen ? 8 : 16),
                      
                      // Sección de notificaciones
                      Text(
                        'Notificaciones',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 4 : 8),
                      
                      // Lista de notificaciones con altura adaptativa
                      Container(
                        height: isSmallScreen 
                            ? screenSize.height * 0.6  // 60% de la altura en pantallas pequeñas
                            : screenSize.height * 0.7, // 70% en pantallas normales
                        child: _notifications.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.notifications_off,
                                      size: isSmallScreen ? 24 : 40,
                                      color: Colors.grey[400],
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'No hay notificaciones',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 10 : 14,
                                        color: Colors.grey[600],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                physics: AlwaysScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: _notifications.length,
                                itemBuilder: (context, index) {
                                  final notification = _notifications[index];
                                  final bool isVisible = _visibilityStatus[index] ?? true;
                                  // Diseño ultra compacto para notificaciones
                                  return Card(
                                    margin: EdgeInsets.only(bottom: isSmallScreen ? 4 : 8),
                                    elevation: 1,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(isSmallScreen ? 6 : 10),
                                      child: Column(
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Icono de la app
                                              CircleAvatar(
                                                backgroundColor: notification.color,
                                                radius: isSmallScreen ? 10 : 16,
                                                child: Icon(
                                                  notification.iconData,
                                                  size: isSmallScreen ? 10 : 16,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              SizedBox(width: isSmallScreen ? 6 : 10),
                                              // Contenido (título y hora)
                                              Expanded(
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        notification.title,
                                                        style: TextStyle(
                                                          fontSize: isSmallScreen ? 10 : 14,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    Row(
                                                      children: [
                                                        Text(
                                                          notification.time,
                                                          style: TextStyle(
                                                            fontSize: isSmallScreen ? 8 : 10,
                                                            color: Colors.grey[600],
                                                          ),
                                                        ),
                                                        SizedBox(width: isSmallScreen ? 4 : 8),
                                                        // Icono de visibilidad en la esquina superior derecha
                                                        GestureDetector(
                                                          onTap: () => _toggleVisibility(index),
                                                          child: Icon(
                                                            isVisible ? Icons.visibility : Icons.visibility_off,
                                                            size: isSmallScreen ? 14 : 18,
                                                            color: Colors.grey[600],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          // Mostrar el contenido solo si isVisible es true
                                          if (isVisible) ...[
                                            SizedBox(height: isSmallScreen ? 4 : 6),
                                            Padding(
                                              padding: EdgeInsets.only(left: isSmallScreen ? 26 : 42),
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  notification.content,
                                                  style: TextStyle(
                                                    fontSize: isSmallScreen ? 9 : 12,
                                                  ),
                                                  maxLines: isSmallScreen ? 1 : 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
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
          },
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _codeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}