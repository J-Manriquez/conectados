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

public class ConectadosNotificationListenerService extends android.service.notification.NotificationListenerService {
    private static final String TAG = "NotificationListener";
    private static final String CHANNEL = "com.example.conectados/notifications";

    @Override
    public void onCreate() {
        super.onCreate();
        Log.d(TAG, "Servicio de notificaciones creado");
    }

    @Override
    public void onNotificationPosted(StatusBarNotification sbn) {
        super.onNotificationPosted(sbn);

        if (sbn.getPackageName().equals(getPackageName())) {
            return; // Ignorar notificaciones propias
        }

        String packageName = sbn.getPackageName();
        String title = "";
        String text = "";

        if (sbn.getNotification().extras != null) {
            Bundle extras = sbn.getNotification().extras;

            // Intentar obtener título y texto usando getCharSequence para manejar SpannableString
            CharSequence titleCharSequence = extras.getCharSequence("android.title");
            if (titleCharSequence != null) {
                title = titleCharSequence.toString();
            }

            CharSequence textCharSequence = extras.getCharSequence("android.text");
            if (textCharSequence != null) {
                text = textCharSequence.toString();
            }


            // Si el texto principal está vacío, intentar obtenerlo de otras claves comunes
            if (text.isEmpty()) {
                CharSequence bigTextCharSequence = extras.getCharSequence("android.bigText");
                if (bigTextCharSequence != null && !bigTextCharSequence.toString().isEmpty()) {
                    text = bigTextCharSequence.toString();
                } else {
                    CharSequence summaryTextCharSequence = extras.getCharSequence("android.summaryText");
                    if (summaryTextCharSequence != null && !summaryTextCharSequence.toString().isEmpty()) {
                        text = summaryTextCharSequence.toString();
                    }
                }
            }

            // Lógica para manejar MessagingStyle (notificaciones de chat)
            // El contenido está en "android.messages", que es un array de Bundles
            Parcelable[] messages = (Parcelable[]) extras.get("android.messages");
            if (messages != null && messages.length > 0) {
                // Iterar sobre los mensajes para encontrar el último texto
                // O simplemente tomar el último mensaje si es suficiente
                Bundle lastMessage = (Bundle) messages[messages.length - 1];
                CharSequence messageText = lastMessage.getCharSequence("text"); // La clave común para el texto del mensaje
                if (messageText != null) {
                    // Si ya tenemos texto de otra clave, podríamos concatenar o reemplazar
                    // Aquí, vamos a reemplazar si encontramos texto de mensaje
                    if (!messageText.toString().isEmpty()) {
                         text = messageText.toString();
                         // A veces el título en MessagingStyle es el nombre del remitente o grupo
                         // Podríamos intentar obtenerlo también si el título original está vacío
                         if (title.isEmpty()) {
                             CharSequence sender = lastMessage.getCharSequence("sender");
                             if (sender != null) {
                                 title = sender.toString();
                             }
                         }
                    }
                }
            }
             // TODO: Considerar otras claves o estructuras si se identifican problemas con apps específicas
        }

        Log.d(TAG, "Notificación recibida: " + packageName + " - " + title + " - " + text);

        // Enviar la notificación al servicio de Flutter
        Intent intent = new Intent("com.example.conectados.NOTIFICATION_RECEIVED");
        intent.putExtra("package", packageName);
        intent.putExtra("title", title);
        intent.putExtra("text", text);
        sendBroadcast(intent);
    }
    
    @Override
    public void onNotificationRemoved(StatusBarNotification sbn) {
        super.onNotificationRemoved(sbn);
        Log.d(TAG, "Notificación eliminada: " + sbn.getPackageName());
    }
}