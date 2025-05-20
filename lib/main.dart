import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/welcome_page.dart';
import 'services/background_service.dart';
import 'services/notification_service.dart';
import 'services/bluetooth_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar servicios
  final backgroundService = BackgroundService();
  await backgroundService.initialize();
  
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Conectados',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const WelcomePage(),
    );
  }
}