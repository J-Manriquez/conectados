import 'package:flutter/material.dart';
import '../services/bluetooth_service.dart';
import '../services/error_service.dart'; // Importar el servicio de errores

class ModeSelectionScreen extends StatelessWidget {
  final ErrorService _errorService = ErrorService(); // Instancia del servicio de errores

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Conectados'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Selecciona el modo de la aplicación',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                try { // Añadir try-catch
                  Navigator.pushNamed(context, '/emisor');
                } catch (e, st) { // Capturar error y stack trace
                  _errorService.logError( // Registrar el error
                    script: 'mode_selection_screen.dart - Emitter Button',
                    error: e,
                    stackTrace: st,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              child: Text('Modo Emisor', style: TextStyle(fontSize: 18)),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                try { // Añadir try-catch
                  Navigator.pushNamed(context, '/receptor');
                } catch (e, st) { // Capturar error y stack trace
                  _errorService.logError( // Registrar el error
                    script: 'mode_selection_screen.dart - Receiver Button',
                    error: e,
                    stackTrace: st,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              child: Text('Modo Receptor', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}