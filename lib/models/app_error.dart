class AppError {
  final DateTime timestamp;
  final String script;
  final String content;

  AppError({
    required this.timestamp,
    required this.script,
    required this.content,
  });

  // Método para convertir el objeto a un mapa para Firestore
  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp, // Firestore puede manejar DateTime directamente
      'script': script,
      'content': content,
    };
  }
}