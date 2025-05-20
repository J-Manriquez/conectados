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
      final appError = AppError(
        timestamp: DateTime.now(),
        script: script,
        content: 'Error: ${error.toString()}\nStackTrace: ${stackTrace.toString()}',
      );

      await _firestore.collection('errores').add(appError.toMap());
      print('Error logged to Firebase: ${appError.content}'); // Log para depuración
    } catch (e) {
      // Si falla el registro de errores, al menos imprimir en consola
      print('Failed to log error to Firebase: $e');
      print('Original error: ${error.toString()}');
      print('Original stack trace: ${stackTrace.toString()}');
    }
  }
}