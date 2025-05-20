import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/welcome_page.dart';
import 'services/background_service.dart';
import 'services/notification_service.dart';
import 'services/bluetooth_service.dart';
import 'services/storage_service.dart';
import 'package:firebase_core/firebase_core.dart'; // Importar firebase_core
import 'firebase_options.dart'; // Importar firebase_options
import 'services/error_service.dart'; // Importar el nuevo servicio de errores

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Inicializar servicios
  final backgroundService = BackgroundService();
  
  // Usar try-catch para registrar errores durante la inicialización
  try {
    await backgroundService.initialize();
  } catch (e, st) {
    // Registrar el error usando el nuevo servicio
    final errorService = ErrorService();
    await errorService.logError(
      script: 'main.dart',
      error: e,
      stackTrace: st,
    );
    // Opcional: mostrar un mensaje al usuario o salir de la aplicación
    print('Error during service initialization: $e');
    print('Stack trace: $st');
  }


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
      home: WelcomePage(),
    );
  }
}