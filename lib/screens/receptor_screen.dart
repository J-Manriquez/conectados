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
  final ScrollController _scrollController = ScrollController();
  final Map<int, bool> _visibilityStatus = {};

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _bluetoothService.initialize();
    _bluetoothService.connectionStatus.listen((connected) {
      setState(() {
        _isConnected = connected;
      });
    });
    _bluetoothService.receivedNotifications.listen((notification) {
      setState(() {
        _notifications.insert(0, notification);
        _visibilityStatus[0] = true;
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Intentando conectar con el código: ${_codeController.text}')),
    );
  }

  void _toggleVisibility(int index) {
    setState(() {
      _visibilityStatus[index] = !(_visibilityStatus[index] ?? true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 200;

    return Scaffold(
      body: SafeArea(
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
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back, size: isSmallScreen ? 16 : 24),
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
                        Text(
                          'Ingresa el código:',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 16,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 4 : 8),
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
                              Icon(Icons.bluetooth_connected, color: Colors.green, size: isSmallScreen ? 14 : 20),
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
                      Text(
                        'Notificaciones',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 4 : 8),
                      Container(
                        height: isSmallScreen ? screenSize.height * 0.6 : screenSize.height * 0.7,
                        child: _notifications.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.notifications_off, size: isSmallScreen ? 24 : 40, color: Colors.grey[400]),
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
                                              CircleAvatar(
                                                backgroundColor: notification.color,
                                                radius: isSmallScreen ? 10 : 16,
                                                child: Icon(notification.iconData, size: isSmallScreen ? 10 : 16, color: Colors.white),
                                              ),
                                              SizedBox(width: isSmallScreen ? 6 : 10),
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