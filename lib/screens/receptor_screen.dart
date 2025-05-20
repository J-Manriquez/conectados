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
  final Map<NotificationItem, bool> _visibilityStatus = {}; // Changed to NotificationItem key

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
        _visibilityStatus[notification] = true; // Associate visibility with the notification object
      });
      // Scroll to the top when a new notification arrives
      _scrollController.animateTo(
        0.0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
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
  void _toggleVisibility(NotificationItem notification) { // Changed to NotificationItem parameter
    setState(() {
      _visibilityStatus[notification] = !(_visibilityStatus[notification] ?? true);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Siempre usaremos el tamaño pequeño como predeterminado para el diseño
    final screenSize = MediaQuery.of(context).size;
    const bool isSmallScreen = true; // Force small screen styling for consistent compact view

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
                  padding: const EdgeInsets.all(4.0), // Default to small padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título con botón de retroceso integrado
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back,
                              size: 16, // Default to small icon size
                            ),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const Text(
                            'Modo Receptor',
                            style: TextStyle(
                              fontSize: 14, // Default to small font size
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4), // Default to small SizedBox height

                      if (!_isConnected) ...[
                        // Sección de conexión simplificada
                        const Text(
                          'Ingresa el código:',
                          style: TextStyle(
                            fontSize: 12, // Default to small font size
                          ),
                        ),
                        const SizedBox(height: 4), // Default to small SizedBox height
                        // Código de entrada más grande y fácil de usar
                        TextField(
                          controller: _codeController,
                          decoration: InputDecoration(
                            hintText: '123456',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, // Default to small content padding
                              vertical: 8, // Default to small content padding
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontSize: 16, // Default to small font size
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLength: 6,
                          buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                        ),
                        const SizedBox(height: 4), // Default to small SizedBox height
                        // Botón grande para facilitar la pulsación
                        SizedBox(
                          width: double.infinity,
                          height: 40, // Default to small button height
                          child: ElevatedButton(
                            onPressed: _connectWithCode,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'CONECTAR',
                              style: TextStyle(
                                fontSize: 14, // Default to small font size
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],

                      if (_isConnected) ...[
                        // Indicador de conexión más compacto
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4, // Default to small padding
                            horizontal: 8, // Default to small padding
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bluetooth_connected,
                                color: Colors.green,
                                size: 14, // Default to small icon size
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Conectado',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12, // Default to small font size
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 8), // Default to small SizedBox height

                      // Sección de notificaciones
                      const Text(
                        'Notificaciones',
                        style: TextStyle(
                          fontSize: 12, // Default to small font size
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4), // Default to small SizedBox height

                      // Lista de notificaciones con altura adaptativa
                      SizedBox(
                        height: screenSize.height * 0.6, // Always use 60% of screen height
                        child: _notifications.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.notifications_off,
                                      size: 24, // Default to small icon size
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No hay notificaciones',
                                      style: TextStyle(
                                        fontSize: 10, // Default to small font size
                                        color: Colors.grey[600],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: _notifications.length,
                                itemBuilder: (context, index) {
                                  final notification = _notifications[index];
                                  final bool isVisible = _visibilityStatus[notification] ?? true; // Get visibility from map

                                  // Diseño ultra compacto para notificaciones
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 4), // Default to small margin
                                    elevation: 1,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(6), // Default to small padding
                                      child: Column(
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Icono de la app
                                              CircleAvatar(
                                                backgroundColor: notification.color,
                                                radius: 10, // Default to small radius
                                                child: Icon(
                                                  notification.iconData,
                                                  size: 10, // Default to small icon size
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(width: 6), // Default to small SizedBox width
                                              // Contenido (título y hora)
                                              Expanded(
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        notification.title,
                                                        style: const TextStyle(
                                                          fontSize: 10, // Default to small font size
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
                                                            fontSize: 8, // Default to small font size
                                                            color: Colors.grey[600],
                                                          ),
                                                        ),
                                                        const SizedBox(width: 4), // Default to small SizedBox width
                                                        // Icono de visibilidad en la esquina superior derecha
                                                        GestureDetector(
                                                          onTap: () => _toggleVisibility(notification), // Pass notification object
                                                          child: Icon(
                                                            isVisible ? Icons.visibility : Icons.visibility_off,
                                                            size: 14, // Default to small icon size
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
                                            const SizedBox(height: 4), // Default to small SizedBox height
                                            Padding(
                                              padding: const EdgeInsets.only(left: 26), // Default to small left padding
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  notification.content,
                                                  style: const TextStyle(
                                                    fontSize: 9, // Default to small font size
                                                  ),
                                                  maxLines: 1, // Default to 1 max line
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