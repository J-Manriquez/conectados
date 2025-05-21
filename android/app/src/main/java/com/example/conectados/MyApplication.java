package com.example.conectados;

import io.flutter.app.FlutterApplication;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterEngineCache;
import io.flutter.embedding.engine.dart.DartExecutor;
import android.util.Log; // Importar la clase Log

public class MyApplication extends FlutterApplication {
    public static final String ENGINE_ID = "my_engine_id";

    @Override
    public void onCreate() {
        super.onCreate();
        Log.d("MyApplication", "onCreate: Inicializando MyApplication.");
        // Inicializar y cachear el FlutterEngine
        FlutterEngine flutterEngine = new FlutterEngine(this);
        Log.d("MyApplication", "onCreate: FlutterEngine creado.");

        // Configura el ejecutor Dart para que apunte a tu punto de entrada principal
        // Asegúrate de que 'main' es el nombre de tu función principal en Dart
        // y que 'lib/main.dart' es la ruta a tu archivo principal.
        flutterEngine.getDartExecutor().executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        );
        Log.d("MyApplication", "onCreate: Dart entrypoint ejecutado.");

        // Cachea el motor Flutter para que pueda ser reutilizado por otros componentes
        FlutterEngineCache.getInstance().put(ENGINE_ID, flutterEngine);
        Log.d("MyApplication", "onCreate: FlutterEngine cacheado con ID: " + ENGINE_ID);

        // Opcional: Si necesitas inicializar plugins aquí, puedes hacerlo
        // GeneratedPluginRegistrant.registerWith(flutterEngine);
        Log.d("MyApplication", "onCreate: MyApplication inicializada.");
    }

    // Opcional: Sobrescribe onTerminate si necesitas limpiar recursos
    @Override
    public void onTerminate() {
        super.onTerminate();
        Log.d("MyApplication", "onTerminate: Terminando MyApplication.");
        // Limpia el motor de la caché cuando la aplicación termina
        FlutterEngineCache.getInstance().remove(ENGINE_ID);
        Log.d("MyApplication", "onTerminate: FlutterEngine con ID " + ENGINE_ID + " eliminado de la caché.");
        Log.d("MyApplication", "onTerminate: MyApplication finalizada.");
    }
}