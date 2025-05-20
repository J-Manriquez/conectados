import 'package:cloud_firestore/cloud_firestore.dart';
// import '../models/app_flow_log.dart'; // Ya no necesitamos el modelo AppFlowLog como documento principal

class FlowLogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> logFlow({
    required String script,
    required String message,
  }) async {
    try {
      // Obtener la hora actual
      final now = DateTime.now();
      // Formatear la hora para usarla como ID del documento (YYYY-MM-DD-HH)
      // Asegurarse de que el mes, día y hora tengan dos dígitos
      final String hourlyDocId = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}-${now.hour.toString().padLeft(2, '0')}';

      // Usar el timestamp completo como nombre del campo dentro del documento horario
      // Esto asegura unicidad y orden dentro de la hora
      final String timestampFieldName = now.toIso8601String(); // Formato ISO 8601

      // Crear el mapa con los datos del log
      final Map<String, dynamic> logData = {
        'script': script,
        'message': message,
        // Opcional: podrías añadir el timestamp aquí también si lo necesitas dentro del logData
        // 'timestamp': Timestamp.fromDate(now),
      };

      // Guardar el log como un campo dentro del documento horario
      // Usamos set con merge: true para añadir el campo sin sobrescribir otros logs en el mismo documento horario
      await _firestore.collection('flow_logs').doc(hourlyDocId).set({
        timestampFieldName: logData,
      }, SetOptions(merge: true));

      print('Flow logged to Firebase (hourly doc: $hourlyDocId, field: $timestampFieldName): [script: $script] $message'); // Log para depuración
    } catch (e) {
      // Si falla el registro de flujo, al menos imprimir en consola
      print('Failed to log flow to Firebase: $e');
      print('Original flow log: [script: $script, message: $message]');
      // Nota: No usamos ErrorService aquí para evitar un bucle infinito si ErrorService también usa FlowLogService
    }
  }
}