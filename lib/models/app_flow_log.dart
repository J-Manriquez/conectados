import 'package:cloud_firestore/cloud_firestore.dart';

class AppFlowLog {
  final DateTime timestamp;
  final String script; // Ubicación o nombre del script/función
  final String message; // Mensaje describiendo el paso del flujo

  AppFlowLog({
    required this.timestamp,
    required this.script,
    required this.message,
  });

  // Método para convertir a Map para almacenamiento en Firestore
  Map<String, dynamic> toMap() {
    return {
      'timestamp': Timestamp.fromDate(timestamp), // Usar Timestamp de Firestore
      'script': script,
      'message': message,
    };
  }

  // Método para crear desde Map (útil si necesitas leerlos, aunque no es el objetivo principal ahora)
  factory AppFlowLog.fromMap(Map<String, dynamic> map) {
    return AppFlowLog(
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      script: map['script'],
      message: map['message'],
    );
  }
}