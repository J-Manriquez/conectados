import 'package:flutter/material.dart';
import 'emitter_screen.dart';
import 'receiver_screen.dart';
import '../services/error_service.dart'; // Importar el servicio de errores

class WelcomePage extends StatelessWidget {
  WelcomePage({super.key});

  // Instancia del servicio de errores
  final ErrorService _errorService = ErrorService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conectados'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Bienvenido a Conectados',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Selecciona el modo en que deseas utilizar esta aplicación:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 60),
                ),
                onPressed: () {
                  try {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EmitterScreen(),
                      ),
                    );
                  } catch (e, st) {
                    _errorService.logError(
                      script: 'welcome_page.dart - Emitter Button',
                      error: e,
                      stackTrace: st,
                    );
                  }
                },
                child: const Text('Modo Emisor (Smartphone)'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 60),
                ),
                onPressed: () {
                  try {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReceiverSetupPage(),
                      ),
                    );
                  } catch (e, st) {
                    _errorService.logError(
                      script: 'welcome_page.dart - Receiver Button',
                      error: e,
                      stackTrace: st,
                    );
                  }
                },
                child: const Text('Modo Receptor (Smartwatch)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}