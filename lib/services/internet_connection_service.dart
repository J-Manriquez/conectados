import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_item.dart';
import 'error_service.dart';
import 'flow_log_service.dart';

class InternetConnectionService {
  static final InternetConnectionService _instance = InternetConnectionService._internal();
  factory InternetConnectionService() => _instance;
  InternetConnectionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ErrorService _errorService = ErrorService();
  final FlowLogService _flowLogService = FlowLogService();

  // Nombre de la colección en Firestore para las conexiones por Internet
  static const String _connectionsCollection = 'internet_connections';

  // Método para iniciar el modo emisor por Internet
  Future<void> startEmitter(String uniqueCode) async {
    _flowLogService.logFlow(script: 'internet_connection_service.dart - startEmitter', message: 'Iniciando modo emisor por Internet con código: $uniqueCode.');
    try {
      // Crear o actualizar el documento de conexión para este código
      // Usamos set con merge: true para no sobrescribir si ya existe
      await _firestore.collection(_connectionsCollection).doc(uniqueCode).set({
        'status': 'disconnected', // Estado inicial
        'notifications': [], // Lista vacía para las notificaciones
        'lastUpdated': FieldValue.serverTimestamp(), // Timestamp de la última actualización
        // Puedes añadir otros campos si son necesarios, como un ID de usuario si lo tienes
      }, SetOptions(merge: true));
      _flowLogService.logFlow(script: 'internet_connection_service.dart - startEmitter', message: 'Documento de conexión por Internet creado/actualizado para código: $uniqueCode.');
    } catch (e, st) {
      _errorService.logError(
        script: 'internet_connection_service.dart - startEmitter',
        error: e,
        stackTrace: st,
      );
      _flowLogService.logFlow(script: 'internet_connection_service.dart - startEmitter', message: 'Error al iniciar emisor por Internet: ${e.toString()}');
    }
  }

  // Método para detener el modo emisor por Internet (opcional, podrías querer mantener el documento)
  Future<void> stopEmitter(String uniqueCode) async {
    _flowLogService.logFlow(script: 'internet_connection_service.dart - stopEmitter', message: 'Intentando detener emisor por Internet con código: $uniqueCode.');
    try {
      final docRef = _firestore.collection(_connectionsCollection).doc(uniqueCode);

      // Verificar si el documento existe antes de intentar actualizarlo
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        // Si el documento existe, actualizar su estado a 'disconnected'
        await docRef.update({
          'status': 'disconnected',
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        _flowLogService.logFlow(script: 'internet_connection_service.dart - stopEmitter', message: 'Estado de conexión por Internet actualizado a "disconnected" para código: $uniqueCode.');
      } else {
        // Si el documento no existe, simplemente registrar que no se encontró
        _flowLogService.logFlow(script: 'internet_connection_service.dart - stopEmitter', message: 'Documento de conexión por Internet no encontrado para código: $uniqueCode. No se requiere actualización.');
      }

      // Opcional: Si deseas eliminar el documento al detener el emisor, descomenta la siguiente línea
      // await _firestore.collection(_connectionsCollection).doc(uniqueCode).delete();
      // _flowLogService.logFlow(script: 'internet_connection_service.dart - stopEmitter', message: 'Documento de conexión por Internet eliminado.');
    } catch (e, st) {
      _errorService.logError(
        script: 'internet_connection_service.dart - stopEmitter',
        error: e,
        stackTrace: st,
      );
      _flowLogService.logFlow(script: 'internet_connection_service.dart - stopEmitter', message: 'Error al detener emisor por Internet: ${e.toString()}');
    }
  }


  // Método para enviar una notificación a través de Firestore
  Future<void> sendNotification(NotificationItem notification, String uniqueCode) async {
    _flowLogService.logFlow(script: 'internet_connection_service.dart - sendNotification', message: 'Intentando enviar notificación por Internet: ${notification.title}.');
    try {
      // Convertir la notificación a mapa
      final notificationMap = notification.toMap();

      // Añadir la notificación a la lista en el documento de Firestore
      // Usamos FieldValue.arrayUnion para añadir el mapa a la lista 'notifications'
      await _firestore.collection(_connectionsCollection).doc(uniqueCode).update({
        'notifications': FieldValue.arrayUnion([notificationMap]),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      _flowLogService.logFlow(script: 'internet_connection_service.dart - sendNotification', message: 'Notificación enviada por Internet a Firestore para código: $uniqueCode.');
      print('Notificación enviada por Internet: ${notification.title}');
    } catch (e, st) {
      _errorService.logError(
        script: 'internet_connection_service.dart - sendNotification',
        error: e,
        stackTrace: st,
      );
      _flowLogService.logFlow(script: 'internet_connection_service.dart - sendNotification', message: 'Error al enviar notificación por Internet: ${e.toString()}');
      print('Error al enviar notificación por Internet: $e');
    }
  }

  // --- Métodos para el modo receptor por Internet ---
  // Estos métodos deberían usarse en la pantalla del receptor

  // Método para conectar como receptor por Internet
  // Retorna un Stream de notificaciones o null si el código no es válido
  Stream<List<NotificationItem>>? connectReceiver(String uniqueCode) {
     _flowLogService.logFlow(script: 'internet_connection_service.dart - connectReceiver', message: 'Intentando conectar como receptor por Internet con código: $uniqueCode.');
    try {
      final docRef = _firestore.collection(_connectionsCollection).doc(uniqueCode);

      // Verificar si el documento existe y actualizar el estado a 'connected'
      // Usamos then/catchError para manejar la operación asíncrona inicial
      docRef.get().then((docSnapshot) async {
        if (docSnapshot.exists) {
           _flowLogService.logFlow(script: 'internet_connection_service.dart - connectReceiver', message: 'Documento de conexión encontrado. Actualizando estado a conectado.');
          await docRef.update({'status': 'connected', 'lastConnected': FieldValue.serverTimestamp()});
        } else {
           _flowLogService.logFlow(script: 'internet_connection_service.dart - connectReceiver', message: 'Documento de conexión no encontrado para código: $uniqueCode.');
          // Manejar caso de código inválido en la UI del receptor
          print('Código de conexión por Internet inválido.');
          // TODO: Notificar a la UI que el código es inválido
        }
      }).catchError((e, st) {
         _errorService.logError(
            script: 'internet_connection_service.dart - connectReceiver - get/update',
            error: e,
            stackTrace: st,
          );
          _flowLogService.logFlow(script: 'internet_connection_service.dart - connectReceiver - get/update', message: 'Error al verificar/actualizar documento de conexión: ${e.toString()}');
          print('Error al verificar/actualizar documento de conexión: $e');
          // TODO: Notificar a la UI sobre el error
      });


      // Retornar un stream que escucha los cambios en el campo 'notifications'
      // El suscriptor deberá manejar los errores de este stream
      return docRef.snapshots().map((docSnapshot) {
        if (docSnapshot.exists) {
          final data = docSnapshot.data();
          if (data != null && data.containsKey('notifications')) {
            final List<dynamic> notificationsData = data['notifications'] ?? [];
             _flowLogService.logFlow(script: 'internet_connection_service.dart - connectReceiver', message: 'Notificaciones recibidas por stream: ${notificationsData.length}.');
            // Convertir la lista de mapas a lista de NotificationItem
            return notificationsData.map((item) => NotificationItem.fromMap(item as Map<String, dynamic>)).toList();
          }
        }
         _flowLogService.logFlow(script: 'internet_connection_service.dart - connectReceiver', message: 'No se encontraron notificaciones en el stream o documento no existe.');
        return []; // Devolver lista vacía si no hay notificaciones o el documento no existe
      });
      // Eliminado .handleError aquí

    } catch (e, st) {
      _errorService.logError(
        script: 'internet_connection_service.dart - connectReceiver',
        error: e,
        stackTrace: st,
      );
      _flowLogService.logFlow(script: 'internet_connection_service.dart - connectReceiver', message: 'Error general en connectReceiver: ${e.toString()}');
      print('Error general en connectReceiver: $e');
      return null; // Retornar null si hay un error inicial
    }
  }

  // Método para desconectar como receptor por Internet (opcional)
  Future<void> disconnectReceiver(String uniqueCode) async {
     _flowLogService.logFlow(script: 'internet_connection_service.dart - disconnectReceiver', message: 'Desconectando receptor por Internet para código: $uniqueCode.');
    try {
       final docRef = _firestore.collection(_connectionsCollection).doc(uniqueCode);
       // Opcional: podrías actualizar el estado a 'disconnected' o similar
       await docRef.update({'status': 'disconnected', 'lastDisconnected': FieldValue.serverTimestamp()});
        _flowLogService.logFlow(script: 'internet_connection_service.dart - disconnectReceiver', message: 'Estado del documento de conexión actualizado a disconnected.');
    } catch (e, st) {
      _errorService.logError(
        script: 'internet_connection_service.dart - disconnectReceiver',
        error: e,
        stackTrace: st,
      );
      _flowLogService.logFlow(script: 'internet_connection_service.dart - disconnectReceiver', message: 'Error al desconectar receptor por Internet: ${e.toString()}');
      print('Error al desconectar receptor por Internet: $e');
    }
  }
}