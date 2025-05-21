import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_item.dart';
import 'error_service.dart';
import 'flow_log_service.dart';
import 'connection_document_service.dart'; // Importar el nuevo servicio

class InternetConnectionService {
  static final InternetConnectionService _instance = InternetConnectionService._internal();
  factory InternetConnectionService() => _instance;
  InternetConnectionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ErrorService _errorService = ErrorService();
  final FlowLogService _flowLogService = FlowLogService();
  final ConnectionDocumentService _connectionDocumentService = ConnectionDocumentService(); // Instancia del nuevo servicio

  // Nombre de la colección en Firestore para las conexiones por Internet
  static const String _connectionsCollection = 'internet_connections';

  // Método para iniciar el modo emisor por Internet
  Future<void> startEmitter(String uniqueCode) async {
    _flowLogService.logFlow(script: 'internet_connection_service.dart - startEmitter', message: 'Iniciando modo emisor por Internet con código: $uniqueCode.');
    try {
      // Usar el nuevo servicio para crear o actualizar el documento
      await _connectionDocumentService.createOrUpdateConnectionDocument(
        uniqueCode,
        status: 'disconnected', // Estado inicial
        notifications: [], // Lista vacía inicial
      );
      _flowLogService.logFlow(script: 'internet_connection_service.dart - startEmitter', message: 'Documento de conexión creado/actualizado con éxito para código: $uniqueCode.');
      print('Documento de conexión creado/actualizado con éxito para código: $uniqueCode');
    } catch (e, st) {
      _errorService.logError(
        script: 'internet_connection_service.dart - startEmitter',
        error: e,
        stackTrace: st,
      );
      _flowLogService.logFlow(script: 'internet_connection_service.dart - startEmitter', message: 'Error al iniciar modo emisor: ${e.toString()}');
      print('Error al iniciar modo emisor: $e');
      // Considerar re-lanzar o manejar el error
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
  Future<void> sendNotification(String uniqueCode, NotificationItem notification) async {
    _flowLogService.logFlow(script: 'internet_connection_service.dart - sendNotification', message: 'Intentando enviar notificación por Internet: ${notification.title}.');
    try {
      // Usar el nuevo servicio para añadir la notificación al documento
      await _connectionDocumentService.addNotificationToDocument(uniqueCode, notification);
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
    if (uniqueCode.isEmpty) {
      _flowLogService.logFlow(script: 'internet_connection_service.dart - connectReceiver', message: 'Código vacío proporcionado.');
      print('Código vacío proporcionado.');
      return null; // O lanzar un error, dependiendo de la lógica de UI
    }

    // Verificar si el documento existe y actualizar el estado
    final docRef = _firestore.collection(_connectionsCollection).doc(uniqueCode);

    // Usar el nuevo servicio para obtener el stream del documento
    final connectionDocumentStream = _connectionDocumentService.getConnectionDocumentStream(uniqueCode);

    // Escuchar el stream del documento para actualizar el estado y obtener notificaciones
    // Este listener es solo para actualizar el estado en Firestore, no para consumir notificaciones
    docRef.get().then((docSnapshot) async {
      if (docSnapshot.exists) {
        _flowLogService.logFlow(script: 'internet_connection_service.dart - connectReceiver - get', message: 'Documento encontrado para código: $uniqueCode. Actualizando estado a "connected".');
        // Usar el nuevo servicio para actualizar el estado
        await _connectionDocumentService.updateConnectionStatus(uniqueCode, 'connected');
        print('Documento encontrado y estado actualizado a "connected".');
      } else {
        _flowLogService.logFlow(script: 'internet_connection_service.dart - connectReceiver - get', message: 'Documento no encontrado para código: $uniqueCode.');
        print('Documento no encontrado para código: $uniqueCode.');
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
    // Modificamos para mapear el stream de ConnectionDocument a un stream de List<NotificationItem>
    return connectionDocumentStream.map((connectionDoc) {
      if (connectionDoc != null) {
         _flowLogService.logFlow(script: 'internet_connection_service.dart - connectReceiver', message: 'Notificaciones recibidas por stream: ${connectionDoc.notifications.length}.');
        // Retornar la lista de notificaciones del modelo
        return connectionDoc.notifications;
      } else {
         _flowLogService.logFlow(script: 'internet_connection_service.dart - connectReceiver', message: 'Documento de conexión nulo en el stream.');
        return []; // Retornar lista vacía si el documento es nulo
      }
    });
  }

  // Método para desconectar como receptor por Internet (opcional)
  Future<void> disconnectReceiver(String uniqueCode) async {
     _flowLogService.logFlow(script: 'internet_connection_service.dart - disconnectReceiver', message: 'Desconectando receptor por Internet con código: $uniqueCode.');
     try {
       // Opción 1: Actualizar estado a 'disconnected'
       await _connectionDocumentService.updateConnectionStatus(uniqueCode, 'disconnected');
       _flowLogService.logFlow(script: 'internet_connection_service.dart - disconnectReceiver', message: 'Estado actualizado a "disconnected" para código: $uniqueCode.');
       print('Estado actualizado a "disconnected" para código: $uniqueCode');
   
       // Opción 2: Eliminar el documento completamente (si ya no se necesita)
       // await _connectionDocumentService.deleteConnectionDocument(uniqueCode);
       // _flowLogService.logFlow(script: 'internet_connection_service.dart - disconnectReceiver', message: 'Documento eliminado para código: $uniqueCode.');
       // print('Documento eliminado para código: $uniqueCode');
   
     } catch (e, st) {
       _errorService.logError(
         script: 'internet_connection_service.dart - disconnectReceiver',
         error: e,
         stackTrace: st,
       );
       _flowLogService.logFlow(script: 'internet_connection_service.dart - disconnectReceiver', message: 'Error al desconectar receptor para código $uniqueCode: ${e.toString()}');
       print('Error al desconectar receptor: $e');
     }
  }
}