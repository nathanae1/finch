package dev.starling.starling

import android.content.Context
import android.net.nsd.NsdManager
import android.net.nsd.NsdServiceInfo
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Bespoke mDNS plugin (Plan 09). Advertises `_starling._tcp` via NsdManager
 * and resolves peers via NsdManager.discoverServices + resolveService.
 *
 * Native code is intentionally narrow: register a service, browse, emit
 * `peer-found` / `peer-lost` events. All policy lives in Dart.
 *
 * Acquires a WifiManager.MulticastLock at register and releases it at
 * deregister so multicast traffic isn't filtered by power-save.
 */
class MdnsPlugin : FlutterPlugin, MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {

    companion object {
        private const val METHOD_CHANNEL = "dev.starling.mdns"
        private const val EVENT_CHANNEL = "dev.starling.mdns/peers"
        private const val SERVICE_TYPE = "_starling._tcp."
        private const val MULTICAST_LOCK_TAG = "dev.starling.mdns.lock"
        private const val TAG = "MdnsPlugin"
    }

    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    private var appContext: Context? = null
    private var nsdManager: NsdManager? = null
    private var multicastLock: WifiManager.MulticastLock? = null

    private var advertisedPubkey: String? = null
    private var registrationListener: NsdManager.RegistrationListener? = null
    private var discoveryListener: NsdManager.DiscoveryListener? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL).also {
            it.setMethodCallHandler(this)
        }
        eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL).also {
            it.setStreamHandler(this)
        }
        nsdManager = appContext?.getSystemService(Context.NSD_SERVICE) as? NsdManager
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        tearDown(emitCleared = false)
        methodChannel?.setMethodCallHandler(null)
        eventChannel?.setStreamHandler(null)
        methodChannel = null
        eventChannel = null
        appContext = null
        nsdManager = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "register" -> {
                val pubkey = call.argument<String>("pubkey")
                val port = call.argument<Int>("port")
                if (pubkey == null || port == null) {
                    result.error("invalid-args", "register requires pubkey + port", null)
                    return
                }
                doRegister(pubkey, port, result)
            }
            "deregister" -> {
                tearDown(emitCleared = true)
                result.success(null)
            }
            "rescan" -> {
                restartDiscovery(result)
            }
            else -> result.notImplemented()
        }
    }

    private fun doRegister(pubkey: String, port: Int, result: MethodChannel.Result) {
        val nsd = nsdManager ?: return result.error(
            "advertise-failed", "NsdManager unavailable", null
        )
        tearDownInternal(emitCleared = false)
        advertisedPubkey = pubkey
        acquireMulticastLock()

        val info = NsdServiceInfo().apply {
            serviceName = pubkey
            serviceType = SERVICE_TYPE
            this.port = port
            // setAttribute is API 21+; we target 26+, so it's always present.
            setAttribute("pubkey", pubkey)
            setAttribute("port", port.toString())
        }
        registrationListener = object : NsdManager.RegistrationListener {
            override fun onServiceRegistered(s: NsdServiceInfo) {}
            override fun onRegistrationFailed(s: NsdServiceInfo, errorCode: Int) {
                Log.w(TAG, "register failed: $errorCode")
            }
            override fun onServiceUnregistered(s: NsdServiceInfo) {}
            override fun onUnregistrationFailed(s: NsdServiceInfo, errorCode: Int) {}
        }
        try {
            nsd.registerService(info, NsdManager.PROTOCOL_DNS_SD, registrationListener)
        } catch (t: Throwable) {
            Log.w(TAG, "registerService threw", t)
            result.error("advertise-failed", t.message ?: "unknown", null)
            return
        }

        startDiscovery()
        result.success(null)
    }

    private fun startDiscovery() {
        val nsd = nsdManager ?: return
        val listener = object : NsdManager.DiscoveryListener {
            override fun onDiscoveryStarted(serviceType: String) {}
            override fun onDiscoveryStopped(serviceType: String) {}
            override fun onStartDiscoveryFailed(serviceType: String, errorCode: Int) {
                Log.w(TAG, "start discovery failed: $errorCode")
            }
            override fun onStopDiscoveryFailed(serviceType: String, errorCode: Int) {}
            override fun onServiceFound(info: NsdServiceInfo) {
                if (info.serviceName == advertisedPubkey) return  // skip self
                resolveService(info)
            }
            override fun onServiceLost(info: NsdServiceInfo) {
                emit(
                    mapOf(
                        "event" to "peer-lost",
                        "pubkey" to (info.serviceName ?: ""),
                    )
                )
            }
        }
        discoveryListener = listener
        try {
            nsd.discoverServices(SERVICE_TYPE, NsdManager.PROTOCOL_DNS_SD, listener)
        } catch (t: Throwable) {
            Log.w(TAG, "discoverServices threw", t)
        }
    }

    private fun resolveService(info: NsdServiceInfo) {
        val nsd = nsdManager ?: return
        val resolveListener = object : NsdManager.ResolveListener {
            override fun onResolveFailed(s: NsdServiceInfo, errorCode: Int) {
                Log.v(TAG, "resolve failed: $errorCode")
            }
            override fun onServiceResolved(s: NsdServiceInfo) {
                val attrs = s.attributes
                val pubkeyBytes = attrs?.get("pubkey")
                val portBytes = attrs?.get("port")
                val pubkey = pubkeyBytes?.let { String(it) } ?: s.serviceName ?: return
                val port = portBytes?.let { String(it).toIntOrNull() } ?: s.port
                val host = s.host?.hostAddress ?: return
                emit(
                    mapOf(
                        "event" to "peer-found",
                        "pubkey" to pubkey,
                        "host" to host,
                        "port" to port,
                    )
                )
            }
        }
        try {
            nsd.resolveService(info, resolveListener)
        } catch (t: Throwable) {
            Log.v(TAG, "resolveService threw", t)
        }
    }

    private fun restartDiscovery(result: MethodChannel.Result) {
        val nsd = nsdManager
        val listener = discoveryListener
        if (nsd != null && listener != null) {
            try {
                nsd.stopServiceDiscovery(listener)
            } catch (_: Throwable) {
            }
        }
        discoveryListener = null
        emit(mapOf("event" to "cleared"))
        startDiscovery()
        result.success(null)
    }

    private fun acquireMulticastLock() {
        if (multicastLock?.isHeld == true) return
        val ctx = appContext ?: return
        val wifi = ctx.applicationContext.getSystemService(Context.WIFI_SERVICE)
            as? WifiManager ?: return
        val lock = wifi.createMulticastLock(MULTICAST_LOCK_TAG).apply {
            setReferenceCounted(false)
            acquire()
        }
        multicastLock = lock
    }

    private fun releaseMulticastLock() {
        multicastLock?.takeIf { it.isHeld }?.release()
        multicastLock = null
    }

    private fun tearDown(emitCleared: Boolean) {
        tearDownInternal(emitCleared = emitCleared)
    }

    private fun tearDownInternal(emitCleared: Boolean) {
        val nsd = nsdManager
        registrationListener?.let { listener ->
            try {
                nsd?.unregisterService(listener)
            } catch (_: Throwable) {
            }
        }
        registrationListener = null

        discoveryListener?.let { listener ->
            try {
                nsd?.stopServiceDiscovery(listener)
            } catch (_: Throwable) {
            }
        }
        discoveryListener = null

        advertisedPubkey = null
        releaseMulticastLock()

        if (emitCleared) {
            emit(mapOf("event" to "cleared"))
        }
    }

    private fun emit(payload: Map<String, Any>) {
        mainHandler.post { eventSink?.success(payload) }
    }

    // EventChannel.StreamHandler
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    @Suppress("unused")
    private fun touchBuildVersion() {
        // Keep Build import used; we may need version-gating later.
        Build.VERSION.SDK_INT
    }
}
