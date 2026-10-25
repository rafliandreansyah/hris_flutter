package com.hroasish.app

import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onResume() {
        super.onResume()
        // App terbuka lagi: LocationTrackingService.restoreOnAppStart melanjutkan sesi.
        TrackingResumeNotifier.cancel(this)
    }

    override fun onDestroy() {
        // Ditutup dari recents saat masih clock-in: engine Flutter ikut berhenti sehingga
        // stream lokasi mati. Ingatkan karyawan untuk membuka app kembali.
        if (isFinishing && !isChangingConfigurations) {
            TrackingResumeNotifier.showIfTrackingActive(applicationContext)
        }
        super.onDestroy()
    }
}
