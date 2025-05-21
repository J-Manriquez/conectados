package com.example.conectados;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

public class BootCompletedReceiver extends BroadcastReceiver {
    private static final String TAG = "BootCompletedReceiver";
    
    @Override
    public void onReceive(Context context, Intent intent) {
        Log.d(TAG, "onReceive: Broadcast recibido con acción: " + intent.getAction());
        if (Intent.ACTION_BOOT_COMPLETED.equals(intent.getAction())) {
            Log.d(TAG, "Dispositivo iniciado, iniciando aplicación");
            
            // Iniciar la aplicación
            Intent launchIntent = context.getPackageManager()
                    .getLaunchIntentForPackage(context.getPackageName());
            
            if (launchIntent != null) {
                Log.d(TAG, "onReceive: Launch intent encontrado para el paquete: " + context.getPackageName());
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                context.startActivity(launchIntent);
                Log.d(TAG, "onReceive: Actividad principal iniciada.");
            } else {
                Log.e(TAG, "onReceive: No se encontró launch intent para el paquete: " + context.getPackageName());
            }
        } else {
             Log.d(TAG, "onReceive: Acción de broadcast no manejada: " + intent.getAction());
        }
    }
}