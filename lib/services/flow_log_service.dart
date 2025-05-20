import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_flow_log.dart';

class FlowLogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> logFlow({
    required String script,
    required String message,
  }) async {
    try {
      final appFlowLog = AppFlowLog(
        timestamp: DateTime.now(),
        script: script,
        message: message,
      );

      // Guardar en una colección específica para logs de flujo
      await _firestore.collection('flow_logs').add(appFlowLog.toMap());
      print('Flow logged to Firebase: [${appFlowLog.script}] ${appFlowLog.message}'); // Log para depuración
    } catch (e) {
      // Si falla el registro de flujo, al menos imprimir en consola
      print('Failed to log flow to Firebase: $e');
      print('Original flow log: [script: $script, message: $message]');
    }
  }
}