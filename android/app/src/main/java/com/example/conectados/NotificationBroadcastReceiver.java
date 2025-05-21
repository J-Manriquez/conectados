package com.example.conectados;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

import java.util.Map; // Añadir esta importación
import java.util.HashMap; // Añadir esta importación

import io.flutter.plugin.common.MethodChannel;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterEngineCache;

public class NotificationBroadcastReceiver extends BroadcastReceiver {
    private static final String TAG = "NotificationBroadcastReceiver";
    private static final String CHANNEL = "com.example.conectados/notifications";

    @Override
    public void onReceive(Context context, Intent intent) {
        Log.d(TAG, "onReceive: Broadcast recibido en NotificationBroadcastReceiver con acción: " + intent.getAction());
        if ("com.example.conectados.NOTIFICATION_RECEIVED".equals(intent.getAction())) {
            String packageName = intent.getStringExtra("package");
            String title = intent.getStringExtra("title");
            String text = intent.getStringExtra("text");

            Log.d(TAG, "Recibido broadcast: [Paquete: " + packageName + "] [Título: " + title + "] [Texto: " + text + "]");

            // Obtener el FlutterEngine de la caché
            Log.d(TAG, "onReceive: Intentando obtener FlutterEngine de la caché con ID: my_engine_id");
            FlutterEngine flutterEngine = FlutterEngineCache.getInstance().get("my_engine_id");
            if (flutterEngine != null) {
                Log.d(TAG, "onReceive: FlutterEngine encontrado en caché.");
                // Crear un solo mapa con todos los datos de la notificación
                Map<String, Object> notificationData = new HashMap<>();
                notificationData.put("package", packageName);
                notificationData.put("title", title);
                notificationData.put("text", text);
                Log.d(TAG, "onReceive: Datos de notificación preparados para enviar a Flutter.");

                Log.d(TAG, "onReceive: Invocando método 'onNotificationReceived' en MethodChannel.");
                new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                    .invokeMethod(
                        "onNotificationReceived",
                        java.util.Collections.singletonMap("notification", notificationData)
                    );
                 Log.d(TAG, "onReceive: Método 'onNotificationReceived' invocado.");
            } else {
                Log.e(TAG, "onReceive: FlutterEngine no encontrado en caché con ID: my_engine_id. No se puede enviar a Flutter.");
            }
        } else {
            Log.d(TAG, "onReceive: Acción de broadcast no manejada: " + intent.getAction());
        }
    }
}