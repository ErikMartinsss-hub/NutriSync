package com.mamba.nutrisync.mamba_fast_tracker

import android.content.Intent
import android.os.Build
import android.provider.Settings
import androidx.biometric.BiometricManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val biometricChannel = "com.mamba.nutrisync/biometric"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, biometricChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openBiometricEnroll" -> { openBiometricEnroll(); result.success(null) }
                    else -> result.notImplemented()
                }
            }
    }

    private fun openBiometricEnroll() {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            Intent(Settings.ACTION_BIOMETRIC_ENROLL).apply {
                putExtra(
                    Settings.EXTRA_BIOMETRIC_AUTHENTICATORS_ALLOWED,
                    BiometricManager.Authenticators.BIOMETRIC_STRONG or
                        BiometricManager.Authenticators.BIOMETRIC_WEAK
                )
            }
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            Intent(Settings.ACTION_BIOMETRIC_ENROLL)
        } else {
            Intent(Settings.ACTION_SECURITY_SETTINGS)
        }
        try {
            startActivity(intent)
        } catch (_: Exception) {
            try {
                startActivity(Intent(Settings.ACTION_SECURITY_SETTINGS))
            } catch (_: Exception) {}
        }
    }
}