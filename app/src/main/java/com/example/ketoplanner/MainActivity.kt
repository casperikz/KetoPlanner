package com.example.ketoplanner

import android.app.Activity
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.os.Bundle
import android.print.PrintAttributes
import android.print.PrintManager
import android.view.View
import android.view.ViewGroup
import android.webkit.JavascriptInterface
import android.webkit.ValueCallback
import android.webkit.WebChromeClient
import android.webkit.WebResourceRequest
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.LinearLayout
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.OnBackPressedCallback
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat

import android.provider.MediaStore
import androidx.core.content.FileProvider
import android.util.Base64
import java.io.File
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL

class MainActivity : ComponentActivity() {

    private lateinit var webView: WebView
    private lateinit var statusBarSpacer: View
    private lateinit var navBarSpacer: View
    private var fileUploadCallback: ValueCallback<Array<Uri>>? = null
    private var cameraImageUri: Uri? = null

    private val filePickerLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        if (result.resultCode == Activity.RESULT_OK) {
            val dataUri = result.data?.data
            val urisArray = if (dataUri != null) {
                arrayOf(dataUri)
            } else if (cameraImageUri != null) {
                // Photo taken via Camera Intent
                arrayOf(cameraImageUri!!)
            } else {
                null
            }
            fileUploadCallback?.onReceiveValue(urisArray)
        } else {
            fileUploadCallback?.onReceiveValue(null)
        }
        fileUploadCallback = null
        cameraImageUri = null
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val rootLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
            setBackgroundColor(Color.parseColor("#01696F"))
        }

        statusBarSpacer = View(this).apply {
            setBackgroundColor(Color.parseColor("#01696F"))
        }
        navBarSpacer = View(this).apply {
            setBackgroundColor(Color.parseColor("#FFFFFF"))
        }

        webView = WebView(this)

        rootLayout.addView(statusBarSpacer, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0))
        rootLayout.addView(webView, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1.0f))
        rootLayout.addView(navBarSpacer, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0))

        setContentView(rootLayout)

        val insetsController = WindowCompat.getInsetsController(window, window.decorView)
        insetsController.isAppearanceLightStatusBars = false
        insetsController.isAppearanceLightNavigationBars = true

        ViewCompat.setOnApplyWindowInsetsListener(rootLayout) { _, windowInsets ->
            val insets = windowInsets.getInsets(
                WindowInsetsCompat.Type.systemBars() or WindowInsetsCompat.Type.displayCutout()
            )
            statusBarSpacer.layoutParams.height = insets.top
            statusBarSpacer.requestLayout()

            navBarSpacer.layoutParams.height = insets.bottom
            navBarSpacer.requestLayout()

            windowInsets
        }

        configureWebView()

        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
            if (checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) != android.content.pm.PackageManager.PERMISSION_GRANTED) {
                requestPermissions(arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 101)
            }
        }
        FastingAlarmReceiver.createNotificationChannel(this)

        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                webView.evaluateJavascript("typeof window.onAndroidBack === 'function' ? window.onAndroidBack() : false") { result ->
                    val handled = result == "true" || result == "\"true\""
                    if (!handled) {
                        showExitConfirmationDialog()
                    }
                }
            }
        })

        webView.loadUrl("file:///android_asset/index.html")
    }

    private fun configureWebView() {
        webView.settings.apply {
            javaScriptEnabled = true
            domStorageEnabled = true
            databaseEnabled = true
            allowFileAccess = true
            allowContentAccess = true
            useWideViewPort = true
            loadWithOverviewMode = true
            cacheMode = WebSettings.LOAD_DEFAULT
            mixedContentMode = WebSettings.MIXED_CONTENT_ALWAYS_ALLOW
            setSupportZoom(false)
            displayZoomControls = false
            allowFileAccessFromFileURLs = true
            allowUniversalAccessFromFileURLs = true
        }

        webView.addJavascriptInterface(AndroidBridge(this, webView, navBarSpacer), "Android")

        webView.webViewClient = object : WebViewClient() {
            override fun shouldOverrideUrlLoading(view: WebView?, request: WebResourceRequest?): Boolean {
                val url = request?.url?.toString() ?: return false
                if (url.startsWith("file:///android_asset/")) {
                    return false
                }
                // Open external links (e.g. recipe search) in system browser
                return try {
                    val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                    startActivity(intent)
                    true
                } catch (e: Exception) {
                    Toast.makeText(this@MainActivity, "Cannot open link", Toast.LENGTH_SHORT).show()
                    false
                }
            }
        }

        webView.webChromeClient = object : WebChromeClient() {
            override fun onPermissionRequest(request: android.webkit.PermissionRequest?) {
                this@MainActivity.runOnUiThread {
                    val resources = request?.resources ?: return@runOnUiThread
                    val cameraRes = android.webkit.PermissionRequest.RESOURCE_VIDEO_CAPTURE
                    if (resources.contains(cameraRes)) {
                        request.grant(arrayOf(cameraRes))
                    } else {
                        request.grant(resources)
                    }
                }
            }

            override fun onShowFileChooser(
                view: WebView?,
                filePathCallback: ValueCallback<Array<Uri>>?,
                fileChooserParams: FileChooserParams?
            ): Boolean {
                fileUploadCallback?.onReceiveValue(null)
                fileUploadCallback = filePathCallback
                cameraImageUri = null

                val isImage = fileChooserParams?.acceptTypes?.any { it.contains("image") } == true

                var cameraIntent: Intent? = null
                if (isImage) {
                    try {
                        val imageFile = File(cacheDir, "camera_capture_${System.currentTimeMillis()}.jpg")
                        val uri = FileProvider.getUriForFile(
                            this@MainActivity,
                            "${applicationContext.packageName}.fileprovider",
                            imageFile
                        )
                        cameraImageUri = uri
                        cameraIntent = Intent(MediaStore.ACTION_IMAGE_CAPTURE).apply {
                            putExtra(MediaStore.EXTRA_OUTPUT, uri)
                            addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION or Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        }
                    } catch (e: Exception) {
                        cameraImageUri = null
                    }
                }

                val galleryIntent = Intent(Intent.ACTION_GET_CONTENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    type = if (isImage) "image/*" else "*/*"
                }

                val chooserIntent = Intent(Intent.ACTION_CHOOSER).apply {
                    putExtra(Intent.EXTRA_INTENT, galleryIntent)
                    putExtra(Intent.EXTRA_TITLE, if (isImage) "Take Photo or Select Image" else "Select File")
                    if (cameraIntent != null) {
                        putExtra(Intent.EXTRA_INITIAL_INTENTS, arrayOf(cameraIntent))
                    }
                }

                return try {
                    filePickerLauncher.launch(chooserIntent)
                    true
                } catch (e: Exception) {
                    fileUploadCallback?.onReceiveValue(null)
                    fileUploadCallback = null
                    cameraImageUri = null
                    false
                }
            }
        }
    }

    override fun onPause() {
        super.onPause()
        webView.evaluateJavascript("if (typeof saveState === 'function') saveState();", null)
    }

    private fun showExitConfirmationDialog() {
        android.app.AlertDialog.Builder(this)
            .setTitle("Exit Keto Planner")
            .setMessage("Are you sure you want to exit?")
            .setPositiveButton("Yes") { _, _ ->
                finish()
            }
            .setNegativeButton("No", null)
            .show()
    }

    override fun onDestroy() {
        (webView.parent as? ViewGroup)?.removeView(webView)
        webView.destroy()
        super.onDestroy()
    }

    fun installDownloadedApk(apkFile: File) {
        try {
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                if (!packageManager.canRequestPackageInstalls()) {
                    val intent = Intent(android.provider.Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                        data = Uri.parse("package:$packageName")
                    }
                    startActivity(intent)
                    Toast.makeText(this, "Activează 'Permite din această sursă', apoi apasă din nou pe actualizare", Toast.LENGTH_LONG).show()
                    return
                }
            }

            val apkUri: Uri = FileProvider.getUriForFile(
                this,
                "${applicationContext.packageName}.fileprovider",
                apkFile
            )
            val installIntent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(apkUri, "application/vnd.android.package-archive")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(installIntent)
        } catch (e: Exception) {
            Toast.makeText(this, "Eroare la deschiderea instalatorului: ${e.message}", Toast.LENGTH_LONG).show()
        }
    }

    class AndroidBridge(
        private val activity: Activity,
        private val webView: WebView,
        private val navBarSpacer: View
    ) {

        @JavascriptInterface
        fun setNavTheme(isDark: Boolean) {
            activity.runOnUiThread {
                val insetsController = WindowCompat.getInsetsController(activity.window, activity.window.decorView)
                if (isDark) {
                    navBarSpacer.setBackgroundColor(Color.parseColor("#1D1C19"))
                    insetsController.isAppearanceLightNavigationBars = false
                } else {
                    navBarSpacer.setBackgroundColor(Color.parseColor("#FFFFFF"))
                    insetsController.isAppearanceLightNavigationBars = true
                }
            }
        }

        @JavascriptInterface
        fun copyToClipboard(text: String) {
            activity.runOnUiThread {
                val clipboard = activity.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                val clip = ClipData.newPlainText("Keto Planner", text)
                clipboard.setPrimaryClip(clip)
                Toast.makeText(activity, "Copied to clipboard", Toast.LENGTH_SHORT).show()
            }
        }

        @JavascriptInterface
        fun print() {
            activity.runOnUiThread {
                try {
                    val printManager = activity.getSystemService(Context.PRINT_SERVICE) as PrintManager
                    val printAdapter = webView.createPrintDocumentAdapter("Keto Planner")
                    printManager.print("Keto Planner", printAdapter, PrintAttributes.Builder().build())
                } catch (e: Exception) {
                    Toast.makeText(activity, "Print not available", Toast.LENGTH_SHORT).show()
                }
            }
        }

        @JavascriptInterface
        fun shareOrSave(content: String, filename: String) {
            activity.runOnUiThread {
                try {
                    val sendIntent = Intent().apply {
                        action = Intent.ACTION_SEND
                        putExtra(Intent.EXTRA_TEXT, content)
                        putExtra(Intent.EXTRA_SUBJECT, filename)
                        type = "text/plain"
                    }
                    val shareIntent = Intent.createChooser(sendIntent, "Export Keto Planner Backup")
                    activity.startActivity(shareIntent)
                } catch (e: Exception) {
                    Toast.makeText(activity, "Export failed: ${e.message}", Toast.LENGTH_SHORT).show()
                }
            }
        }

        @JavascriptInterface
        fun updateWidget(
            dayName: String,
            kcal: Int,
            targetKcal: Int,
            protein: Int,
            targetProtein: Int,
            mealsJson: String
        ) {
            activity.runOnUiThread {
                try {
                    val prefs = activity.getSharedPreferences(KetoPlannerWidget.PREFS_NAME, Context.MODE_PRIVATE)
                    prefs.edit().apply {
                        putString(KetoPlannerWidget.KEY_DAY, dayName)
                        putInt(KetoPlannerWidget.KEY_KCAL, kcal)
                        putInt(KetoPlannerWidget.KEY_TARGET_KCAL, targetKcal)
                        putInt(KetoPlannerWidget.KEY_PROTEIN, protein)
                        putInt(KetoPlannerWidget.KEY_TARGET_PROTEIN, targetProtein)
                        putString(KetoPlannerWidget.KEY_MEALS_JSON, mealsJson)
                        apply()
                    }
                    KetoPlannerWidget.updateAllWidgets(activity)
                } catch (e: Exception) {
                    // Ignore widget update errors
                }
            }
        }

        @JavascriptInterface
        fun fetchUrl(targetUrl: String, callbackJs: String) {
            Thread {
                var conn: HttpURLConnection? = null
                try {
                    var currentUrl = targetUrl
                    var redirects = 0
                    var responseCode = 0
                    while (redirects < 5) {
                        val url = URL(currentUrl)
                        conn = url.openConnection() as HttpURLConnection
                        conn.requestMethod = "GET"
                        conn.connectTimeout = 10000
                        conn.readTimeout = 10000
                        conn.setRequestProperty("User-Agent", "Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36")
                        conn.instanceFollowRedirects = true
                        responseCode = conn.responseCode
                        if (responseCode in 301..308) {
                            val newLoc = conn.getHeaderField("Location")
                            if (!newLoc.isNullOrEmpty()) {
                                currentUrl = if (newLoc.startsWith("http")) newLoc else URL(url, newLoc).toString()
                                conn.disconnect()
                                redirects++
                                continue
                            }
                        }
                        break
                    }

                    val stream = if (responseCode in 200..299) conn?.inputStream else conn?.errorStream
                    val bytes = stream?.readBytes() ?: ByteArray(0)
                    val base64Text = Base64.encodeToString(bytes, Base64.NO_WRAP)

                    activity.runOnUiThread {
                        webView.evaluateJavascript("$callbackJs(true, \"$base64Text\", $responseCode, true)", null)
                    }
                } catch (e: Exception) {
                    val errMsg = (e.message ?: "Network error").replace("\\", "\\\\").replace("\"", "\\\"")
                    activity.runOnUiThread {
                        webView.evaluateJavascript("$callbackJs(false, \"$errMsg\", 0, false)", null)
                    }
                } finally {
                    conn?.disconnect()
                }
            }.start()
        }

        @JavascriptInterface
        fun scheduleFastingAlarm(type: String, title: String, message: String, triggerAtMillis: Long) {
            val alarmManager = activity.getSystemService(Context.ALARM_SERVICE) as? android.app.AlarmManager ?: return
            val intent = Intent(activity, FastingAlarmReceiver::class.java).apply {
                putExtra("type", type)
                putExtra("title", title)
                putExtra("message", message)
            }
            val reqCode = if (type == "start") 1001 else 1002
            val pendingIntent = android.app.PendingIntent.getBroadcast(
                activity,
                reqCode,
                intent,
                android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
            )
            if (triggerAtMillis > System.currentTimeMillis()) {
                try {
                    alarmManager.setExactAndAllowWhileIdle(android.app.AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
                } catch (e: Exception) {
                    try {
                        alarmManager.setAndAllowWhileIdle(android.app.AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
                    } catch (e2: Exception) {
                        // Ignore alarm errors
                    }
                }
            }
        }

        @JavascriptInterface
        fun cancelFastingAlarm(type: String) {
            val alarmManager = activity.getSystemService(Context.ALARM_SERVICE) as? android.app.AlarmManager ?: return
            val intent = Intent(activity, FastingAlarmReceiver::class.java)
            val reqCode = if (type == "start") 1001 else 1002
            val pendingIntent = android.app.PendingIntent.getBroadcast(
                activity,
                reqCode,
                intent,
                android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
            )
            alarmManager.cancel(pendingIntent)
        }

        @JavascriptInterface
        fun showNotification(title: String, message: String) {
            activity.runOnUiThread {
                try {
                    FastingAlarmReceiver.createNotificationChannel(activity)
                    val tapIntent = Intent(activity, MainActivity::class.java).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    }
                    val pendingTapIntent = android.app.PendingIntent.getActivity(
                        activity,
                        0,
                        tapIntent,
                        android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
                    )
                    val notification = androidx.core.app.NotificationCompat.Builder(activity, FastingAlarmReceiver.CHANNEL_ID)
                        .setSmallIcon(R.mipmap.ic_launcher)
                        .setContentTitle(title)
                        .setContentText(message)
                        .setStyle(androidx.core.app.NotificationCompat.BigTextStyle().bigText(message))
                        .setPriority(androidx.core.app.NotificationCompat.PRIORITY_HIGH)
                        .setAutoCancel(true)
                        .setContentIntent(pendingTapIntent)
                        .build()
                    androidx.core.app.NotificationManagerCompat.from(activity).notify(2003, notification)
                } catch (e: Exception) {
                    // Ignore notification errors
                }
            }
        }

        @JavascriptInterface
        fun requestNotificationPermission() {
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
                activity.runOnUiThread {
                    if (activity.checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) != android.content.pm.PackageManager.PERMISSION_GRANTED) {
                        activity.requestPermissions(arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 101)
                    }
                }
            }
        }

        @JavascriptInterface
        fun getAppVersion(): String {
            return try {
                val pInfo = activity.packageManager.getPackageInfo(activity.packageName, 0)
                pInfo.versionName ?: "1.0.0"
            } catch (e: Exception) {
                "1.0.0"
            }
        }

        @JavascriptInterface
        fun getAppVersionCode(): Int {
            return try {
                val pInfo = activity.packageManager.getPackageInfo(activity.packageName, 0)
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
                    pInfo.longVersionCode.toInt()
                } else {
                    @Suppress("DEPRECATION")
                    pInfo.versionCode
                }
            } catch (e: Exception) {
                1
            }
        }

        @JavascriptInterface
        fun downloadAndInstallApk(apkUrl: String) {
            activity.runOnUiThread {
                Toast.makeText(activity, "Descărcare actualizare în curs...", Toast.LENGTH_SHORT).show()
            }
            Thread {
                var conn: HttpURLConnection? = null
                try {
                    var currentUrl = apkUrl
                    var redirects = 0
                    while (redirects < 6) {
                        val url = URL(currentUrl)
                        conn = url.openConnection() as HttpURLConnection
                        conn.instanceFollowRedirects = true
                        conn.connectTimeout = 15000
                        conn.readTimeout = 40000
                        conn.setRequestProperty("User-Agent", "Mozilla/5.0 (Android; Mobile)")
                        val respCode = conn.responseCode
                        if (respCode in 301..308) {
                            val newLoc = conn.getHeaderField("Location")
                            if (!newLoc.isNullOrEmpty()) {
                                currentUrl = if (newLoc.startsWith("http")) newLoc else URL(url, newLoc).toString()
                                conn.disconnect()
                                redirects++
                                continue
                            }
                        }
                        break
                    }

                    val contentLength = conn?.contentLength?.toLong() ?: -1L
                    val updateDir = File(activity.cacheDir, "apk_updates")
                    if (!updateDir.exists()) updateDir.mkdirs()
                    val apkFile = File(updateDir, "KetoPlanner_update.apk")
                    if (apkFile.exists()) apkFile.delete()

                    val inputStream = conn?.inputStream ?: throw Exception("Nu s-a putut deschide fluxul de descărcare")
                    inputStream.use { input ->
                        apkFile.outputStream().use { output ->
                            val buffer = ByteArray(8192)
                            var bytesRead: Int
                            var totalRead = 0L
                            var lastPercent = -1
                            while (input.read(buffer).also { bytesRead = it } != -1) {
                                output.write(buffer, 0, bytesRead)
                                totalRead += bytesRead
                                if (contentLength > 0) {
                                    val percent = ((totalRead * 100) / contentLength).toInt()
                                    if (percent != lastPercent) {
                                        lastPercent = percent
                                        activity.runOnUiThread {
                                            webView.evaluateJavascript("if (typeof onApkDownloadProgress === 'function') onApkDownloadProgress($percent);", null)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    activity.runOnUiThread {
                        webView.evaluateJavascript("if (typeof onApkDownloadComplete === 'function') onApkDownloadComplete();", null)
                        if (activity is MainActivity) {
                            activity.installDownloadedApk(apkFile)
                        }
                    }
                } catch (e: Exception) {
                    val errMsg = (e.message ?: "Eroare descărcare").replace("\"", "\\\"").replace("\n", " ")
                    activity.runOnUiThread {
                        webView.evaluateJavascript("if (typeof onApkDownloadError === 'function') onApkDownloadError(\"$errMsg\");", null)
                        Toast.makeText(activity, "Eroare descărcare: $errMsg", Toast.LENGTH_LONG).show()
                    }
                } finally {
                    conn?.disconnect()
                }
            }.start()
        }
    }
}