package com.example.conectados;

import android.content.Intent;
import android.os.IBinder;
import android.service.notification.NotificationListenerService;
import android.service.notification.StatusBarNotification;
import android.util.Log;
import android.os.Bundle;
import android.os.Parcelable; // Importar Parcelable

import io.flutter.plugin.common.MethodChannel;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.view.FlutterCallbackInformation;
import io.flutter.embedding.engine.FlutterEngineCache;

import android.content.IntentFilter; // Importar IntentFilter
import android.content.BroadcastReceiver; // Importar BroadcastReceiver

public class ConectadosNotificationListenerService extends android.service.notification.NotificationListenerService {
    private static final String TAG = "NotificationListener";
    private static final String CHANNEL = "com.example.conectados/notifications";

    private BroadcastReceiver notificationReceiver; // Declarar el BroadcastReceiver

    @Override
    public void onCreate() {
        super.onCreate();
        Log.d(TAG, "Servicio de notificaciones creado");
        Log.d(TAG, "onCreate: Inicializando y registrando BroadcastReceiver.");

        // Inicializar y registrar el BroadcastReceiver
        notificationReceiver = new NotificationBroadcastReceiver();
        IntentFilter filter = new IntentFilter("com.example.conectados.NOTIFICATION_RECEIVED");
        // Add RECEIVER_NOT_EXPORTED flag for dynamic registration (required for API 34+)
        registerReceiver(notificationReceiver, filter, RECEIVER_NOT_EXPORTED);
        Log.d(TAG, "NotificationBroadcastReceiver registrado dinámicamente.");
        Log.d(TAG, "onCreate: Servicio de notificaciones listo.");
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        Log.d(TAG, "onDestroy: Desregistrando BroadcastReceiver.");
        // Desregistrar el BroadcastReceiver cuando el servicio se destruye
        if (notificationReceiver != null) {
            unregisterReceiver(notificationReceiver);
            Log.d(TAG, "NotificationBroadcastReceiver desregistrado dinámicamente.");
        }
        Log.d(TAG, "Servicio de notificaciones destruido");
        Log.d(TAG, "onDestroy: Servicio de notificaciones finalizado.");
    }

    @Override
    public void onNotificationPosted(StatusBarNotification sbn) {
        super.onNotificationPosted(sbn);
        if (sbn.getPackageName().equals(getPackageName())) {
            // Log.d(TAG, "onNotificationPosted: Ignorando notificación propia.");
            return; // Ignorar notificaciones propias
        }

        // Mostrar este log solo si la notificación NO es propia
        Log.d(TAG, "onNotificationPosted: Notificación recibida.");

        String packageName = sbn.getPackageName();
        String title = "";
        String text = "";

        Log.d(TAG, "onNotificationPosted: Procesando notificación de paquete: " + packageName);

        if (sbn.getNotification().extras != null) {
            Bundle extras = sbn.getNotification().extras;
            Log.d(TAG, "onNotificationPosted: Extras de notificación disponibles.");

            // Intentar obtener título y texto usando getCharSequence para manejar SpannableString
            CharSequence titleCharSequence = extras.getCharSequence("android.title");
            if (titleCharSequence != null) {
                title = titleCharSequence.toString();
                Log.d(TAG, "onNotificationPosted: Título extraído: " + title);
            } else {
                 Log.d(TAG, "onNotificationPosted: Clave 'android.title' no encontrada o nula.");
            }

            CharSequence textCharSequence = extras.getCharSequence("android.text");
            if (textCharSequence != null) {
                text = textCharSequence.toString();
                Log.d(TAG, "onNotificationPosted: Texto extraído: " + text);
            } else {
                Log.d(TAG, "onNotificationPosted: Clave 'android.text' no encontrada o nula.");
            }


            // Si el texto principal está vacío, intentar obtenerlo de otras claves comunes
            if (text.isEmpty()) {
                Log.d(TAG, "onNotificationPosted: Texto principal vacío, buscando en otras claves.");
                CharSequence bigTextCharSequence = extras.getCharSequence("android.bigText");
                if (bigTextCharSequence != null && !bigTextCharSequence.toString().isEmpty()) {
                    text = bigTextCharSequence.toString();
                    Log.d(TAG, "onNotificationPosted: Texto extraído de 'android.bigText': " + text);
                } else
 {
                    Log.d(TAG, "onNotificationPosted: Clave 'android.bigText' no encontrada o vacía.");
                    CharSequence summaryTextCharSequence = extras.getCharSequence("android.summaryText");
                    if (summaryTextCharSequence != null && !summaryTextCharSequence.toString().isEmpty()) {
                        text = summaryTextCharSequence.toString();
                        Log.d(TAG, "onNotificationPosted: Texto extraído de 'android.summaryText': " + text);
                    } else {
                         Log.d(TAG, "onNotificationPosted: Clave 'android.summaryText' no encontrada o vacía.");
                    }
                }
            }

            // Lógica para manejar MessagingStyle (notificaciones de chat)
            // El contenido está en "android.messages", que es un array de Bundles
            Parcelable[] messages = (Parcelable[]) extras.get("android.messages");
            if (messages != null && messages.length > 0) {
                Log.d(TAG, "onNotificationPosted: MessagingStyle detectado, procesando mensajes.");
                // Iterar sobre los mensajes para encontrar el último texto
                // O simplemente tomar el último mensaje si es suficiente
                Bundle lastMessage = (Bundle) messages[messages.length - 1];
                CharSequence messageText = lastMessage.getCharSequence("text"); // La clave común para el texto del mensaje
                if (messageText != null) {
                    // Si ya tenemos texto de otra clave, podríamos concatenar o reemplazar
                    // Aquí, vamos a reemplazar si encontramos texto de mensaje
                    if (!messageText.toString().isEmpty()) {
                         text = messageText.toString();
                         Log.d(TAG, "onNotificationPosted: Texto extraído de MessagingStyle: " + text);
                         // A veces el título en MessagingStyle es el nombre del remitente o grupo

                         // Podríamos intentar obtenerlo también si el título original está vacío
                         if (title.isEmpty()) {
                             CharSequence sender = lastMessage.getCharSequence("sender");
                             if (sender != null) {
                                 title = sender.toString();
                                 Log.d(TAG, "onNotificationPosted: Título extraído de MessagingStyle (sender): " + title);
                             } else {
                                 Log.d(TAG, "onNotificationPosted: Clave 'sender' en MessagingStyle no encontrada o nula.");
                             }
                         }
                    } else {
                         Log.d(TAG, "onNotificationPosted: Texto de mensaje en MessagingStyle vacío.");
                    }
                } else {
                    Log.d(TAG, "onNotificationPosted: Clave 'text' en MessagingStyle no encontrada o nula.");
                }
            } else {
                Log.d(TAG, "onNotificationPosted: Clave 'android.messages' no encontrada o vacía.");
            }
             // TODO: Considerar otras claves o estructuras si se identifican problemas con apps específicas
        } else {
            Log.d(TAG, "onNotificationPosted: Extras de notificación no disponibles.");
        }

        Log.d(TAG, "Notificación recibida: [Paquete: " + packageName + "] [Título: " + title + "] [Texto: " + text + "]");

        // Enviar la notificación al servicio de Flutter
        Intent intent = new Intent("com.example.conectados.NOTIFICATION_RECEIVED");
        intent.putExtra("package", packageName);
        intent.putExtra("title", title);
        intent.putExtra("text", text);
        Log.d(TAG, "onNotificationPosted: Enviando broadcast a NotificationBroadcastReceiver.");
        sendBroadcast(intent);
        Log.d(TAG, "onNotificationPosted: Broadcast enviado.");
    }
    
    @Override
    public void onNotificationRemoved(StatusBarNotification sbn) {
        super.onNotificationRemoved(sbn);
        Log.d(TAG, "onNotificationRemoved: Notificación eliminada: " + sbn.getPackageName());
    }
}