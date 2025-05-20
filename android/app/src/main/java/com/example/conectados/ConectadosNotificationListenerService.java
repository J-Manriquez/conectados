package com.example.conectados;

import android.content.Intent;
import android.os.IBinder;
import android.service.notification.NotificationListenerService;
import android.service.notification.StatusBarNotification;
import android.util.Log;

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
            title = sbn.getNotification().extras.getString("android.title", "");
            text = sbn.getNotification().extras.getString("android.text", "");
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