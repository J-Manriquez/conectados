import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  print('[main.dart] WidgetsFlutterBinding inicializado.');

  // Inicializar Firebase
  print('[main.dart] Inicializando Firebase...');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('[main.dart] Firebase inicializado.');

  // Inicializar servicios
  final backgroundService = BackgroundService();
  print('[main.dart] Instancia de BackgroundService creada.');

  // Usar try-catch para registrar errores durante la inicialización
  try {
    print('[main.dart] Intentando inicializar BackgroundService...');
    await backgroundService.initialize();
    print('[main.dart] BackgroundService inicializado correctamente.');
  } catch (e, st) {
    // Registrar el error usando el nuevo servicio
    final errorService = ErrorService();
    await errorService.logError(script: 'main.dart', error: e, stackTrace: st);
    // Opcional: mostrar un mensaje al usuario o salir de la aplicación
    print('[main.dart] Error durante la inicialización del servicio: $e');
    print('[main.dart] Stack trace: $st');
  }

  print('[main.dart] Configurando MethodChannel para notificaciones...');
  const MethodChannel _channel = MethodChannel(
    'com.example.conectados/notifications',
  );
  print(
    '[main.dart] MethodChannel creado con nombre: com.example.conectados/notifications',
  );

  print('[main.dart] Instancia de NotificationService creada.');

  _channel.setMethodCallHandler((call) async {
    print(
      '[main.dart] MethodCallHandler activado. Método recibido: ${call.method}',
    );
    if (call.method == 'onNotificationReceived') {
      print('[main.dart] Método onNotificationReceived recibido.');
      // Inicializar Firebase si aún no está inicializado en este aislado
      // Esto es crucial para que funcione en el aislado de fondo si se llama desde allí
      //   if (Firebase.apps.isEmpty) {
      //     print('[main.dart] Firebase no inicializado en este aislado, inicializando...');
      //     await Firebase.initializeApp();
      //     print('[main.dart] Firebase inicializado en este aislado.');
      //   } else {
      //     print('[main.dart] Firebase ya inicializado en este aislado.');
      //   }

      //   final Map notification = call.arguments['notification'];
      //   print('[Flutter] Notificación recibida desde Android: $notification');
      //   // Guardar en Firebase (colección global)
      //   print('[main.dart] Intentando guardar notificación en Firebase (global)...');
      //   await FirebaseFirestore.instance.collection('notifications').add({
      //     'package': notification['package'],
      //     'title': notification['title'],
      //     'text': notification['text'],
      //     'timestamp': FieldValue.serverTimestamp(),
      //   });
      //   print('[main.dart] Notificación guardada en Firebase (global).');

      //   // Guardar en internet_connections
      //   print('[main.dart] Intentando obtener unique_user_code de SharedPreferences...');
      //   final prefs = await SharedPreferences.getInstance();
      //   final uniqueCode = prefs.getString('unique_user_code');
      //   if (uniqueCode != null && uniqueCode.isNotEmpty) {
      //     print('[main.dart] unique_user_code encontrado: $uniqueCode. Intentando guardar en internet_connections...');
      //     await FirebaseFirestore.instance
      //         .collection('internet_connections')
      //         .doc(uniqueCode)
      //         .update({
      //       'notifications': FieldValue.arrayUnion([
      //         {
      //           'package': notification['package'],
      //           'title': notification['title'],
      //           'text': notification['text'],
      //           'timestamp': FieldValue.serverTimestamp(),
      //         }
      //       ]),
      //       'lastUpdated': FieldValue.serverTimestamp(),
      //     });
      //     print('[main.dart] Notificación guardada en internet_connections.');
      //   } else {
      //     print('[main.dart] unique_user_code no encontrado o vacío, no se guardó en internet_connections.');
      //   }
      // } else {
      //     print('[main.dart] Método de MethodChannel no reconocido: ${call.method}');
      // }
      //  // Obtener una instancia del NotificationService
      final notificationService = NotificationService(); // Corregido el nombre de la clase
      if (Firebase.apps.isEmpty) {
        print(
          '[main.dart] Firebase no inicializado en este aislado, inicializando...',
        );
        await Firebase.initializeApp();
        print('[main.dart] Firebase inicializado en este aislado.');
      } else {
        print('[main.dart] Firebase ya inicializado en este aislado.');
      }

      final Map notification = call.arguments['notification'];
      print('[Flutter] Notificación recibida desde Android: $notification');

      // Llamar al método onNotificationReceived del NotificationService
      // Este método ya contiene la lógica para procesar, guardar y enviar la notificación
      await notificationService.onNotificationReceived( // Llamando al método público
        Map<String, dynamic>.from(notification),
      );

      // Eliminar la lógica de guardado duplicada aquí
      // La lógica de guardado en Firebase y envío por Internet ahora está centralizada en NotificationService
      print(
        '[main.dart] Lógica de guardado en Firebase y envío por Internet delegada a NotificationService.',
      );

      return Future.value(true);
    }
    return Future.value(false);
  });
  print('[main.dart] MethodCallHandler configurado.');

  print('[main.dart] Ejecutando runApp...');
  runApp(const MainApp());
  print('[main.dart] runApp ejecutado.');
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Conectados',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: WelcomePage(),
    );
  }
}
