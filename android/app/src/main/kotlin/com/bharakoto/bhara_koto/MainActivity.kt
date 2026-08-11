package com.bharakoto.bhara_koto

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.math.abs

class MainActivity: FlutterActivity(), LocationListener {
    private val CHANNEL = "com.bharakoto.app/overlay"
    private var methodChannel: MethodChannel? = null
    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var layoutParams: WindowManager.LayoutParams? = null

    private var isExpanded: Boolean = true
    private var isTripActive: Boolean = false
    private var isAppInBackground: Boolean = false

    private var overlayX: Int = 24
    private var overlayY: Int = 100

    private var currentFareStr: String = "৳ 10.00"
    private var currentDistanceStr: String = "0.00"
    private var currentSpeedStr: String = "0"
    private var currentSpeedKmhDouble: Double = 0.0

    private var locationManager: LocationManager? = null
    private var detectThresholdKmh: Double = 1.0
    private var currentLanguage: String = "en"
    private var isMonitoringMotion: Boolean = false
    private var lastMotionLocation: Location? = null
    private var popupTriggered: Boolean = false
    private var startupTimeMs: Long = System.currentTimeMillis()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkPermission" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            result.success(Settings.canDrawOverlays(this@MainActivity))
                        } else {
                            result.success(true)
                        }
                    }
                    "requestPermission" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this@MainActivity)) {
                            val intent = Intent(
                                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                Uri.parse("package:$packageName")
                            )
                            startActivity(intent)
                            result.success(true)
                        } else {
                            result.success(true)
                        }
                    }
                    "openAppSettings" -> {
                        val intent = Intent(
                            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                            Uri.parse("package:$packageName")
                        )
                        startActivity(intent)
                        result.success(true)
                    }
                    "startNativeMotionMonitoring" -> {
                        val thresholdKmh = call.argument<Double>("thresholdKmh") ?: 1.0
                        val lang = call.argument<String>("lang") ?: "en"
                        startNativeMotionMonitoring(thresholdKmh, lang)
                        result.success(true)
                    }
                    "stopNativeMotionMonitoring" -> {
                        stopNativeMotionMonitoring()
                        result.success(true)
                    }
                    "showNativeOverlay" -> {
                        val speedKmh = call.argument<Double>("speedKmh") ?: 0.0
                        val lang = call.argument<String>("lang") ?: currentLanguage
                        currentSpeedKmhDouble = speedKmh
                        currentLanguage = lang
                        isExpanded = true
                        if (isAppInBackground) {
                            renderCapsuleOverlay()
                        }
                        result.success(true)
                    }
                    "updateNativeMeterOverlay" -> {
                        currentFareStr = call.argument<String>("fareTotal") ?: "৳ 10.00"
                        currentDistanceStr = call.argument<String>("distanceKm") ?: "0.00"
                        currentSpeedStr = call.argument<String>("speedKmh") ?: "0"
                        currentLanguage = call.argument<String>("lang") ?: currentLanguage
                        isTripActive = true
                        if (isAppInBackground) {
                            renderCapsuleOverlay()
                        }
                        result.success(true)
                    }
                    "dismissNativeOverlay" -> {
                        isTripActive = false
                        popupTriggered = false
                        dismissNativeFloatingOverlay()
                        result.success(true)
                    }
                    "showNotification" -> {
                        val title = call.argument<String>("title") ?: "Vehicle Motion Detected"
                        val body = call.argument<String>("body") ?: "Tap to start trip meter"
                        val lang = call.argument<String>("lang") ?: currentLanguage
                        showHeadsUpNotification(title, body, lang)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onResume() {
        super.onResume()
        isAppInBackground = false
        // Dismiss native floating overlay whenever app is open in foreground!
        dismissNativeFloatingOverlay()
    }

    override fun onPause() {
        super.onPause()
        isAppInBackground = true
        // Show floating live capsule ONLY if a journey is actively running!
        if (isTripActive) {
            isExpanded = false
            renderCapsuleOverlay()
        } else {
            dismissNativeFloatingOverlay()
        }
    }

    private fun startNativeMotionMonitoring(thresholdKmh: Double, lang: String) {
        detectThresholdKmh = thresholdKmh
        currentLanguage = lang
        popupTriggered = false
        startupTimeMs = System.currentTimeMillis()
        if (isMonitoringMotion) return

        try {
            locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
            if (locationManager?.isProviderEnabled(LocationManager.GPS_PROVIDER) == true) {
                locationManager?.requestLocationUpdates(
                    LocationManager.GPS_PROVIDER,
                    1000L,
                    0f,
                    this
                )
            }
            if (locationManager?.isProviderEnabled(LocationManager.NETWORK_PROVIDER) == true) {
                locationManager?.requestLocationUpdates(
                    LocationManager.NETWORK_PROVIDER,
                    1000L,
                    0f,
                    this
                )
            }
            isMonitoringMotion = true
        } catch (e: SecurityException) {
            e.printStackTrace()
        }
    }

    private fun stopNativeMotionMonitoring() {
        try {
            locationManager?.removeUpdates(this)
            isMonitoringMotion = false
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onLocationChanged(location: Location) {
        if (System.currentTimeMillis() - startupTimeMs < 5000L) return
        if (popupTriggered || isTripActive || !isAppInBackground) return

        // Reject inaccurate GPS fixes (> 35m accuracy)
        if (location.hasAccuracy() && location.accuracy > 35f) return

        var speedKmh = (location.speed * 3.6f).toDouble()
        val last = lastMotionLocation
        if (speedKmh <= 0 && last != null) {
            val timeSec = (location.time - last.time) / 1000f
            // Only compute distance-based speed for valid time deltas between 0.5s and 10.0s
            if (timeSec in 0.5f..10.0f) {
                val distMeters = location.distanceTo(last)
                if (distMeters >= 1.0f) {
                    speedKmh = ((distMeters / timeSec) * 3.6f).toDouble()
                }
            }
        }
        lastMotionLocation = location

        // Filter out impossible speed spikes (> 140 km/h)
        if (speedKmh > 140.0) return

        if (speedKmh >= detectThresholdKmh && speedKmh > 0) {
            popupTriggered = true
            currentSpeedKmhDouble = speedKmh
            isExpanded = true
            renderCapsuleOverlay()

            val isBn = currentLanguage == "bn"
            val notifTitle = if (isBn) "🚌 যানবাহনে গতি শনাক্ত!" else "🚌 Vehicle Movement Detected!"
            val notifBody = if (isBn)
                "আপনার বর্তমান গতি: ${String.format("%.1f", speedKmh)} km/h। স্পর্শ করে ভাড়া গণনা শুরু করুন।"
            else
                "Speed: ${String.format("%.1f", speedKmh)} km/h. Tap to start fare meter."

            showHeadsUpNotification(notifTitle, notifBody, currentLanguage)
        }
    }

    override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
    override fun onProviderEnabled(provider: String) {}
    override fun onProviderDisabled(provider: String) {}

    private fun renderCapsuleOverlay() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) return

        runOnUiThread {
            try {
                if (overlayView != null && windowManager != null) {
                    try { windowManager?.removeView(overlayView) } catch (e: Exception) {}
                    overlayView = null
                }

                windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager

                val isBn = currentLanguage == "bn"

                if (isExpanded) {
                    // EXPANDED ULTRA-PREMIUM CAPSULE CARD: Centered horizontally just below status bar
                    val params = WindowManager.LayoutParams(
                        WindowManager.LayoutParams.MATCH_PARENT,
                        WindowManager.LayoutParams.WRAP_CONTENT,
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                        else
                            @Suppress("DEPRECATION") WindowManager.LayoutParams.TYPE_PHONE,
                        WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
                        PixelFormat.TRANSLUCENT
                    ).apply {
                        gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
                        x = 0
                        y = 100 // Cleanly below status bar
                    }
                    layoutParams = params

                    val card = LinearLayout(this).apply {
                        orientation = LinearLayout.VERTICAL
                        setPadding(38, 30, 38, 30)
                        val shape = GradientDrawable().apply {
                            setColor(Color.parseColor("#0F121E"))
                            cornerRadius = 36f
                            setStroke(3, Color.parseColor("#10B981"))
                        }
                        background = shape
                    }

                    // Header badge row
                    val headerRow = LinearLayout(this).apply {
                        orientation = LinearLayout.HORIZONTAL
                        gravity = Gravity.CENTER_VERTICAL
                    }

                    val badgeContainer = LinearLayout(this).apply {
                        orientation = LinearLayout.HORIZONTAL
                        setPadding(20, 8, 20, 8)
                        val shape = GradientDrawable().apply {
                            setColor(Color.parseColor("#1A2E26"))
                            cornerRadius = 100f
                        }
                        background = shape
                    }

                    val titleText = TextView(this).apply {
                        text = if (isTripActive)
                            (if (isBn) "🟢 বিআরটিএ সচল মিটার" else "🟢 LIVE FARE METER")
                        else
                            (if (isBn) "🚌 গতি শনাক্ত হয়েছে!" else "🚌 VEHICLE MOTION DETECTED")
                        textSize = 12f
                        setTextColor(Color.parseColor("#10B981"))
                    }
                    badgeContainer.addView(titleText)

                    card.setOnClickListener {
                        isExpanded = false
                        renderCapsuleOverlay()
                    }

                    headerRow.addView(badgeContainer, LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f))

                    // Value
                    val valueText = TextView(this).apply {
                        text = if (isTripActive) currentFareStr else "${String.format("%.1f", currentSpeedKmhDouble)} km/h"
                        textSize = 28f
                        setTextColor(Color.WHITE)
                        gravity = Gravity.CENTER
                        setPadding(0, 12, 0, 4)
                    }

                    val subText = TextView(this).apply {
                        text = if (isTripActive)
                            "📍 $currentDistanceStr km  •  ⚡ $currentSpeedStr km/h"
                        else
                            (if (isBn) "গতি শনাক্ত হয়েছে • ভাড়া গণনা শুরু করতে চান?" else "Vehicle movement detected • Start fare meter?")
                        textSize = 12.5f
                        setTextColor(Color.parseColor("#9CA3AF"))
                        gravity = Gravity.CENTER
                        setPadding(0, 0, 0, 18)
                    }

                    // Action Buttons Row
                    val btnRow = LinearLayout(this).apply {
                        orientation = LinearLayout.HORIZONTAL
                        gravity = Gravity.CENTER
                    }

                    val openAppBtn = Button(this).apply {
                        text = if (isBn) "↗ অ্যাপ" else "↗ Open App"
                        setTextColor(Color.parseColor("#9CA3AF"))
                        textSize = 12.5f
                        background = null
                        setOnClickListener {
                            val intent = Intent(context, MainActivity::class.java).apply {
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                            }
                            startActivity(intent)
                        }
                    }

                    if (!isTripActive) {
                        val dismissBtn = Button(this).apply {
                            text = if (isBn) "বাতিল" else "Dismiss"
                            setTextColor(Color.parseColor("#9CA3AF"))
                            textSize = 12.5f
                            background = null
                            setOnClickListener {
                                dismissNativeFloatingOverlay()
                            }
                        }

                        val startBtn = Button(this).apply {
                            text = if (isBn) "ভাড়া শুরু" else "Start Journey"
                            setTextColor(Color.WHITE)
                            textSize = 13f
                            val btnBg = GradientDrawable().apply {
                                setColor(Color.parseColor("#10B981"))
                                cornerRadius = 24f
                            }
                            background = btnBg
                            setOnClickListener {
                                isTripActive = true
                                isExpanded = false // Collapse into mini capsule while trip is running!
                                stopNativeMotionMonitoring()
                                methodChannel?.invokeMethod("onNativeStartTrip", null)
                                renderCapsuleOverlay()
                            }
                        }

                        btnRow.addView(dismissBtn)
                        btnRow.addView(openAppBtn)
                        btnRow.addView(startBtn)
                    } else {
                        val stopBtn = Button(this).apply {
                            text = if (isBn) "⏹️ ভ্রমণ শেষ" else "⏹️ End Journey"
                            setTextColor(Color.WHITE)
                            textSize = 12.5f
                            val btnBg = GradientDrawable().apply {
                                setColor(Color.parseColor("#EF4444"))
                                cornerRadius = 24f
                            }
                            background = btnBg
                            setOnClickListener {
                                isTripActive = false
                                popupTriggered = false
                                dismissNativeFloatingOverlay()
                                methodChannel?.invokeMethod("onNativeStopTrip", null)
                            }
                        }

                        btnRow.addView(stopBtn)
                        btnRow.addView(openAppBtn)
                    }

                    card.addView(headerRow)
                    card.addView(valueText)
                    card.addView(subText)
                    card.addView(btnRow)

                    windowManager?.addView(card, params)
                    overlayView = card

                } else {
                    // MINI MOVABLE CAPSULE: Top-Right placement with FREE drag motion (FLAG_LAYOUT_NO_LIMITS)
                    val params = WindowManager.LayoutParams(
                        WindowManager.LayoutParams.WRAP_CONTENT,
                        WindowManager.LayoutParams.WRAP_CONTENT,
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                        else
                            @Suppress("DEPRECATION") WindowManager.LayoutParams.TYPE_PHONE,
                        WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
                        PixelFormat.TRANSLUCENT
                    ).apply {
                        gravity = Gravity.TOP or Gravity.END
                        x = overlayX
                        y = overlayY
                    }
                    layoutParams = params

                    val pill = LinearLayout(this).apply {
                        orientation = LinearLayout.HORIZONTAL
                        gravity = Gravity.CENTER_VERTICAL
                        setPadding(32, 14, 32, 14)
                        val shape = GradientDrawable().apply {
                            setColor(Color.parseColor("#0D0F17"))
                            cornerRadius = 100f
                            setStroke(3, Color.parseColor("#10B981"))
                        }
                        background = shape
                    }

                    val iconText = TextView(this).apply {
                        text = "🚌 "
                        textSize = 13f
                    }

                    val infoText = TextView(this).apply {
                        text = if (isTripActive) currentFareStr else "${String.format("%.1f", currentSpeedKmhDouble)} km/h"
                        textSize = 14f
                        setTextColor(Color.WHITE)
                        setPadding(4, 0, 8, 0)
                    }

                    val dotText = TextView(this).apply {
                        text = "🟢"
                        textSize = 9f
                    }

                    pill.addView(iconText)
                    pill.addView(infoText)
                    pill.addView(dotText)

                    // Touch Drag & Tap Listener (Allows moving capsule freely everywhere, including beyond screen edges!)
                    var initialX = 0
                    var initialY = 0
                    var initialTouchX = 0f
                    var initialTouchY = 0f
                    var isDragging = false

                    pill.setOnTouchListener { _, event ->
                        when (event.action) {
                            MotionEvent.ACTION_DOWN -> {
                                initialX = params.x
                                initialY = params.y
                                initialTouchX = event.rawX
                                initialTouchY = event.rawY
                                isDragging = false
                                true
                            }
                            MotionEvent.ACTION_MOVE -> {
                                val deltaX = (initialTouchX - event.rawX).toInt()
                                val deltaY = (event.rawY - initialTouchY).toInt()

                                if (abs(deltaX) > 8 || abs(deltaY) > 8) {
                                    isDragging = true
                                }

                                params.x = initialX + deltaX
                                params.y = initialY + deltaY
                                overlayX = params.x
                                overlayY = params.y
                                windowManager?.updateViewLayout(overlayView, params)
                                true
                            }
                            MotionEvent.ACTION_UP -> {
                                if (!isDragging) {
                                    // Single tap expands the capsule back to centered card view!
                                    isExpanded = true
                                    renderCapsuleOverlay()
                                }
                                true
                            }
                            else -> false
                        }
                    }

                    windowManager?.addView(pill, params)
                    overlayView = pill
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private fun dismissNativeFloatingOverlay() {
        runOnUiThread {
            try {
                if (overlayView != null && windowManager != null) {
                    windowManager?.removeView(overlayView)
                    overlayView = null
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private fun showHeadsUpNotification(title: String, body: String, lang: String = "en") {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channelId = "motion_alert_channel"

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Motion Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Alerts when vehicle movement is detected"
                enableVibration(true)
            }
            notificationManager.createNotificationChannel(channel)
        }

        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra("start_trip", true)
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val btnLabel = if (lang == "bn") "যাত্রা শুরু করুন" else "Start Journey"

        val builder = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .addAction(android.R.drawable.ic_media_play, btnLabel, pendingIntent)

        notificationManager.notify(2001, builder.build())
    }
}
