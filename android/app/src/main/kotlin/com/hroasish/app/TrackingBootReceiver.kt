package com.hroasish.app

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat

/**
 * Setelah HP dinyalakan ulang (atau app diperbarui) foreground service lokasi tidak bisa
 * dimulai dari background tanpa ACCESS_BACKGROUND_LOCATION. Bila karyawan masih clock-in,
 * tampilkan notifikasi; ketukan membuka app dan LocationTrackingService memulihkan sesi.
 */
class TrackingBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED &&
            intent.action != Intent.ACTION_MY_PACKAGE_REPLACED
        ) return

        TrackingResumeNotifier.showIfTrackingActive(context)
    }
}

/** Notifikasi "ketuk untuk melanjutkan" bila karyawan masih clock-in tetapi service lokasi berhenti. */
object TrackingResumeNotifier {
    const val TRACKING_ACTIVE_KEY = "tracking_session_active"
    private const val CHANNEL_ID = "tracking_resume"
    private const val NOTIFICATION_ID = 7301

    fun isTrackingActive(context: Context): Boolean {
        // Flag ditulis dari Dart lewat shared_preferences (file & prefix bawaan plugin).
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        return prefs.getBoolean("flutter.$TRACKING_ACTIVE_KEY", false)
    }

    fun showIfTrackingActive(context: Context) {
        if (!isTrackingActive(context)) return

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) return

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Pelacakan Lokasi Kerja",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply { description = "Pengingat untuk melanjutkan pelacakan lokasi kerja" }
            context.getSystemService(NotificationManager::class.java)
                .createNotificationChannel(channel)
        }

        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?.apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP }
            ?: return
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Pelacakan lokasi kerja dijeda")
            .setContentText("Ketuk untuk melanjutkan pelacakan selama jam kerja Anda.")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()

        NotificationManagerCompat.from(context).notify(NOTIFICATION_ID, notification)
    }

    fun cancel(context: Context) {
        NotificationManagerCompat.from(context).cancel(NOTIFICATION_ID)
    }
}
