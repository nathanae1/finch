package dev.starling.starling

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.SurfaceTexture
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.View
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import com.google.zxing.BarcodeFormat
import com.google.zxing.BinaryBitmap
import com.google.zxing.DecodeHintType
import com.google.zxing.MultiFormatReader
import com.google.zxing.PlanarYUVLuminanceSource
import com.google.zxing.common.HybridBinarizer
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import io.flutter.plugin.common.StandardMessageCodec
import java.util.concurrent.Executors

class QrScannerPlugin : FlutterPlugin, MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler, ActivityAware,
    PluginRegistry.RequestPermissionsResultListener {

    companion object {
        private const val METHOD_CHANNEL = "dev.starling.qr_scanner"
        private const val EVENT_CHANNEL = "dev.starling.qr_scanner/scans"
        private const val VIEW_TYPE = "dev.starling.qr_scanner_view"
        private const val PERMISSION_REQUEST_CODE = 8081
        private const val TAG = "QrScannerPlugin"
    }

    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    private var pendingPermissionResult: MethodChannel.Result? = null

    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var appContext: Context? = null

    private var cameraProvider: ProcessCameraProvider? = null
    private val analyzerExecutor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private val multiFormatReader = MultiFormatReader().apply {
        setHints(mapOf(DecodeHintType.POSSIBLE_FORMATS to listOf(BarcodeFormat.QR_CODE)))
    }

    private var lastEmitted: String? = null
    private var lastEmittedAt: Long = 0
    private val viewFactory = PreviewViewFactory()

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL).also {
            it.setMethodCallHandler(this)
        }
        eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL).also {
            it.setStreamHandler(this)
        }
        binding.platformViewRegistry.registerViewFactory(VIEW_TYPE, viewFactory)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel?.setMethodCallHandler(null)
        eventChannel?.setStreamHandler(null)
        methodChannel = null
        eventChannel = null
        appContext = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "start" -> requestPermissionAndStart(result)
            "stop" -> {
                stopCamera()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun requestPermissionAndStart(result: MethodChannel.Result) {
        val ctx = appContext ?: return result.error(
            "camera-unavailable", "no application context", null
        )
        val granted = ContextCompat.checkSelfPermission(
            ctx, Manifest.permission.CAMERA
        ) == PackageManager.PERMISSION_GRANTED
        if (granted) {
            startCamera(result)
            return
        }
        val act = activity
        if (act == null) {
            result.error("camera-unavailable", "no activity available", null)
            return
        }
        if (pendingPermissionResult != null) {
            result.error("permission-denied", "permission request already in flight", null)
            return
        }
        pendingPermissionResult = result
        ActivityCompat.requestPermissions(
            act, arrayOf(Manifest.permission.CAMERA), PERMISSION_REQUEST_CODE
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode != PERMISSION_REQUEST_CODE) return false
        val pending = pendingPermissionResult ?: return true
        pendingPermissionResult = null
        if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            startCamera(pending)
        } else {
            pending.error("permission-denied", "Camera permission denied", null)
        }
        return true
    }

    private fun startCamera(result: MethodChannel.Result) {
        val ctx = appContext ?: return result.error(
            "camera-unavailable", "no application context", null
        )
        val act = activity ?: return result.error(
            "camera-unavailable", "no activity available", null
        )
        val providerFuture = ProcessCameraProvider.getInstance(ctx)
        providerFuture.addListener({
            try {
                val provider = providerFuture.get()
                cameraProvider = provider
                provider.unbindAll()

                val previewUseCase = Preview.Builder().build().also { p ->
                    viewFactory.activeView?.previewView?.let { pv ->
                        p.setSurfaceProvider(pv.surfaceProvider)
                    }
                }
                val analysis = ImageAnalysis.Builder()
                    .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                    .build()
                analysis.setAnalyzer(analyzerExecutor) { proxy ->
                    decodeImageProxy(proxy)
                }
                provider.bindToLifecycle(
                    act as LifecycleOwner,
                    CameraSelector.DEFAULT_BACK_CAMERA,
                    previewUseCase,
                    analysis,
                )
                viewFactory.previewBound = true
                result.success(null)
            } catch (t: Throwable) {
                Log.w(TAG, "camera start failed", t)
                result.error(
                    "camera-unavailable",
                    "Failed to start camera: ${t.message}",
                    null,
                )
            }
        }, ContextCompat.getMainExecutor(ctx))
    }

    private fun stopCamera() {
        cameraProvider?.unbindAll()
        cameraProvider = null
        viewFactory.previewBound = false
    }

    private fun decodeImageProxy(proxy: ImageProxy) {
        try {
            val plane = proxy.planes[0]
            val buffer = plane.buffer
            val data = ByteArray(buffer.remaining())
            buffer.get(data)
            val source = PlanarYUVLuminanceSource(
                data,
                proxy.width,
                proxy.height,
                0,
                0,
                proxy.width,
                proxy.height,
                false,
            )
            val bitmap = BinaryBitmap(HybridBinarizer(source))
            val result = try {
                multiFormatReader.decodeWithState(bitmap)
            } catch (_: Throwable) {
                null
            }
            multiFormatReader.reset()
            if (result != null) {
                emit(result.text)
            }
        } catch (t: Throwable) {
            Log.v(TAG, "decode skipped: ${t.message}")
        } finally {
            proxy.close()
        }
    }

    private fun emit(payload: String) {
        val now = System.currentTimeMillis()
        if (payload == lastEmitted && now - lastEmittedAt < 500) return
        lastEmitted = payload
        lastEmittedAt = now
        mainHandler.post { eventSink?.success(payload) }
    }

    // EventChannel.StreamHandler
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    // ActivityAware
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activity = null
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activity = null
        activityBinding = null
    }

    // PlatformViewFactory exposes a single PreviewView; we keep a back-reference so
    // the camera bind code can attach the surface provider.
    private inner class PreviewViewFactory :
        PlatformViewFactory(StandardMessageCodec.INSTANCE) {
        var activeView: PreviewPlatformView? = null
        var previewBound: Boolean = false

        override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
            val view = PreviewPlatformView(context)
            activeView = view
            return view
        }
    }

    private class PreviewPlatformView(context: Context) : PlatformView {
        val previewView: PreviewView = PreviewView(context).also {
            it.scaleType = PreviewView.ScaleType.FILL_CENTER
        }

        override fun getView(): View = previewView
        override fun dispose() {
            // SurfaceTexture-backed PreviewView cleans up automatically.
            (previewView.parent as? android.view.ViewGroup)?.removeView(previewView)
            // Touch SurfaceTexture import to avoid kotlinc unused-import warning.
            SurfaceTexture::class.java
        }
    }
}
