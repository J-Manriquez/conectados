import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_error.dart';

class ErrorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> logError({
    required String script,
    required dynamic error, // Puede ser una excepción, un string, etc.
    StackTrace? stackTrace,
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

      final appError = AppError(
        timestamp: now, // Usar DateTime directamente
        script: script,
        content: 'Error: ${error.toString()}\nStackTrace: ${stackTrace.toString()}',
      );

      // Crear el mapa con los datos del error
      final Map<String, dynamic> errorData = appError.toMap();

      // Guardar el error como un campo dentro del documento horario
      // Usamos set con merge: true para añadir el campo sin sobrescribir otros errores en el mismo documento horario
      await _firestore.collection('errores').doc(hourlyDocId).set({
        timestampFieldName: errorData,
      }, SetOptions(merge: true));

      print('Error logged to Firebase (hourly doc: $hourlyDocId, field: $timestampFieldName): ${appError.content}'); // Log para depuración
    } catch (e) {
      // Si falla el registro de errores, al menos imprimir en consola
      print('Failed to log error to Firebase: $e');
      print('Original error: ${error.toString()}');
      print('Original stack trace: ${stackTrace.toString()}');
    }
  }
}