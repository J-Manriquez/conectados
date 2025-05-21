import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:conectados/models/notification_item.dart';
import '../models/connection_document.dart';
import 'error_service.dart'; // Importar ErrorService
import 'flow_log_service.dart'; // Importar FlowLogService

class ConnectionDocumentService {
  static final ConnectionDocumentService _instance = ConnectionDocumentService._internal();
  factory ConnectionDocumentService() => _instance;
  ConnectionDocumentService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ErrorService _errorService = ErrorService();
  final FlowLogService _flowLogService = FlowLogService();

  static const String _connectionsCollection = 'internet_connections';

  // Método para crear o actualizar un documento de conexión
  Future<void> createOrUpdateConnectionDocument(String uniqueCode, {String status = 'disconnected', List<dynamic> notifications = const []}) async {
     _flowLogService.logFlow(script: 'connection_document_service.dart - createOrUpdateConnectionDocument', message: 'Creando o actualizando documento para código: $uniqueCode.');
    try {
      await _firestore.collection(_connectionsCollection).doc(uniqueCode).set({
        'status': status,
        'notifications': notifications, // Se espera una lista de mapas aquí
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // Usar merge para no sobrescribir completamente
       _flowLogService.logFlow(script: 'connection_document_service.dart - createOrUpdateConnectionDocument', message: 'Documento creado/actualizado con éxito para código: $uniqueCode.');
    } catch (e, st) {
      _errorService.logError(
        script: 'connection_document_service.dart - createOrUpdateConnectionDocument',
        error: e,
        stackTrace: st,
      );
       _flowLogService.logFlow(script: 'connection_document_service.dart - createOrUpdateConnectionDocument', message: 'Error al crear/actualizar documento para código $uniqueCode: ${e.toString()}');
      print('Error al crear/actualizar documento de conexión: $e');
      // Considerar re-lanzar o manejar el error según sea necesario
    }
  }

  // Método para obtener un stream de un documento de conexión específico
  Stream<ConnectionDocument?> getConnectionDocumentStream(String uniqueCode) {
     _flowLogService.logFlow(script: 'connection_document_service.dart - getConnectionDocumentStream', message: 'Obteniendo stream del documento para código: $uniqueCode.');
    return _firestore.collection(_connectionsCollection).doc(uniqueCode).snapshots().map((docSnapshot) {
      if (docSnapshot.exists && docSnapshot.data() != null) {
         _flowLogService.logFlow(script: 'connection_document_service.dart - getConnectionDocumentStream', message: 'Documento encontrado para código: $uniqueCode.');
        return ConnectionDocument.fromMap(docSnapshot.data()!);
      } else {
         _flowLogService.logFlow(script: 'connection_document_service.dart - getConnectionDocumentStream', message: 'Documento no encontrado para código: $uniqueCode.');
        return null; // Retorna null si el documento no existe
      }
    }).handleError((e, st) {
       _errorService.logError(
        script: 'connection_document_service.dart - getConnectionDocumentStream',
        error: e,
        stackTrace: st,
      );
       _flowLogService.logFlow(script: 'connection_document_service.dart - getConnectionDocumentStream', message: 'Error en el stream del documento para código $uniqueCode: ${e.toString()}');
      print('Error en el stream del documento de conexión: $e');
      // Puedes decidir si quieres re-lanzar el error o retornar un stream de error
      throw e; // Re-lanzar el error para que el StreamBuilder lo maneje
    });
  }

  // Método para actualizar el estado de un documento de conexión
  Future<void> updateConnectionStatus(String uniqueCode, String status) async {
     _flowLogService.logFlow(script: 'connection_document_service.dart - updateConnectionStatus', message: 'Actualizando estado a "$status" para código: $uniqueCode.');
    try {
      await _firestore.collection(_connectionsCollection).doc(uniqueCode).update({
        'status': status,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
       _flowLogService.logFlow(script: 'connection_document_service.dart - updateConnectionStatus', message: 'Estado actualizado con éxito a "$status" para código: $uniqueCode.');
    } catch (e, st) {
      _errorService.logError(
        script: 'connection_document_service.dart - updateConnectionStatus',
        error: e,
        stackTrace: st,
      );
       _flowLogService.logFlow(script: 'connection_document_service.dart - updateConnectionStatus', message: 'Error al actualizar estado para código $uniqueCode: ${e.toString()}');
      print('Error al actualizar estado del documento: $e');
    }
  }

   // Método para añadir una notificación a la lista en el documento
  Future<void> addNotificationToDocument(String uniqueCode, NotificationItem notification) async {
     _flowLogService.logFlow(script: 'connection_document_service.dart - addNotificationToDocument', message: 'Añadiendo notificación para código: $uniqueCode.');
    try {
      print('[ConnectionDocumentService] Añadiendo notificación al documento $uniqueCode: ${notification.toMap()}'); // NUEVO PRINT
      await _firestore.collection(_connectionsCollection).doc(uniqueCode).update({
        'notifications': FieldValue.arrayUnion([notification.toMap()]),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
       _flowLogService.logFlow(script: 'connection_document_service.dart - addNotificationToDocument', message: 'Notificación añadida con éxito para código: $uniqueCode.');
    } catch (e, st) {
      _errorService.logError(
        script: 'connection_document_service.dart - addNotificationToDocument',
        error: e,
        stackTrace: st,
      );
       _flowLogService.logFlow(script: 'connection_document_service.dart - addNotificationToDocument', message: 'Error al añadir notificación para código $uniqueCode: ${e.toString()}');
      print('Error al añadir notificación al documento: $e');
    }
  }

  // Método para eliminar un documento de conexión
  Future<void> deleteConnectionDocument(String uniqueCode) async {
     _flowLogService.logFlow(script: 'connection_document_service.dart - deleteConnectionDocument', message: 'Eliminando documento para código: $uniqueCode.');
    try {
      await _firestore.collection(_connectionsCollection).doc(uniqueCode).delete();
       _flowLogService.logFlow(script: 'connection_document_service.dart - deleteConnectionDocument', message: 'Documento eliminado con éxito para código: $uniqueCode.');
    } catch (e, st) {
      _errorService.logError(
        script: 'connection_document_service.dart - deleteConnectionDocument',
        error: e,
        stackTrace: st,
      );
       _flowLogService.logFlow(script: 'connection_document_service.dart - deleteConnectionDocument', message: 'Error al eliminar documento para código $uniqueCode: ${e.toString()}');
      print('Error al eliminar documento de conexión: $e');
    }
  }
}