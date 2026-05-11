---
name: flutter-platform-integration
description: >
  Lead authority for Flutter platform integration. Use when implementing platform
  channels, Method/Event channels, Dart FFI, AndroidView/UiKitView, federated plugins,
  native permissions, background execution, or bridging native SDKs to Flutter.
---

# Flutter Platform Integration Skill

## Purpose

Design and implement reliable, type-safe bridges between Flutter and native platforms —
Android (Kotlin/Java) and iOS (Swift/ObjC) — using the appropriate channel or FFI
mechanism for each use case.

## Scope and authority

Lead authority for:

- MethodChannel and EventChannel design
- Dart FFI for native C/C++ libraries
- AndroidView / UiKitView (platform views)
- federated plugin architecture
- background execution (Android WorkManager, iOS BGTaskScheduler)
- native permission handling
- native SDK integration (Maps, Camera, Bluetooth, etc.)
- plugin packaging and publishing

Supporting interactions:

- `flutter-monorepo` for federated plugin package structure
- `flutter-security` for permissions and secure native storage
- `flutter-build-release` for native build configuration

---

## When to use

- Accessing platform APIs not exposed by existing packages
- Integrating a native SDK (e.g., a vendor analytics SDK, hardware SDK)
- Implementing high-performance native code via FFI
- Embedding native views (Maps, WebView, camera preview)
- Building a plugin (internal or public)
- Background task scheduling (download, sync, notification delivery)
- Requesting and handling native permissions

---

## Channel mechanism selection

| Need | Mechanism | When |
|---|---|---|
| Call native → return result | MethodChannel | One-shot native calls (GPS, camera, file) |
| Native → Dart continuous stream | EventChannel | Sensor data, connectivity changes, Bluetooth |
| High-performance native C/C++ | Dart FFI | Image processing, crypto, ML inference |
| Embed native Android view | AndroidView | Maps, WebView (Hybrid Composition) |
| Embed native iOS view | UiKitView | Maps, WebView |
| Binary data streaming | BasicMessageChannel | Large payloads, custom codecs |
| Plugin with platform variants | Federated plugin | Distributable, multi-platform plugin |

---

## MethodChannel — standard pattern

### Dart side

```dart
// core/platform/camera_channel.dart
class CameraChannel {
  static const _channel = MethodChannel('com.example.app/camera');

  Future<String?> capturePhoto() async {
    try {
      final path = await _channel.invokeMethod<String>('capturePhoto');
      return path;
    } on PlatformException catch (e) {
      // Map platform errors to domain exceptions
      throw CameraException(
        code: e.code,
        message: e.message ?? 'Unknown camera error',
      );
    }
  }

  Future<void> requestCameraPermission() async {
    final granted = await _channel.invokeMethod<bool>('requestPermission');
    if (granted != true) throw const CameraPermissionDeniedException();
  }
}
```

### Android side (Kotlin)

```kotlin
// android/app/src/main/kotlin/.../CameraPlugin.kt
class CameraPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var activity: Activity

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(
            binding.binaryMessenger,
            "com.example.app/camera"
        )
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "capturePhoto" -> capturePhoto(result)
            "requestPermission" -> requestPermission(result)
            else -> result.notImplemented()
        }
    }

    private fun capturePhoto(result: MethodChannel.Result) {
        try {
            // Native implementation
            val path = takePhoto()
            result.success(path)
        } catch (e: Exception) {
            result.error("CAMERA_ERROR", e.message, null)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
```

### iOS side (Swift)

```swift
// ios/Classes/CameraPlugin.swift
public class CameraPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.example.app/camera",
            binaryMessenger: registrar.messenger()
        )
        let instance = CameraPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "capturePhoto":
            capturePhoto(result: result)
        case "requestPermission":
            requestPermission(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func capturePhoto(result: @escaping FlutterResult) {
        // Native implementation
        result("/path/to/photo.jpg")
    }
}
```

---

## EventChannel — streaming data pattern

### Dart side

```dart
// Connectivity stream example
class ConnectivityChannel {
  static const _channel = EventChannel('com.example.app/connectivity');

  Stream<bool> get onConnectivityChanged =>
      _channel.receiveBroadcastStream().map(
        (event) => event as bool,
      );
}

// Usage with Riverpod:
@riverpod
Stream<bool> networkConnectivity(Ref ref) {
  return ConnectivityChannel().onConnectivityChanged;
}
```

### Android side (Kotlin)

```kotlin
class ConnectivityStreamHandler(private val context: Context) : EventChannel.StreamHandler {
    private var networkCallback: ConnectivityManager.NetworkCallback? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE)
                as ConnectivityManager
        networkCallback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                events.success(true)
            }
            override fun onLost(network: Network) {
                events.success(false)
            }
        }
        cm.registerDefaultNetworkCallback(networkCallback!!)
    }

    override fun onCancel(arguments: Any?) {
        // Unregister callback to prevent leaks
        val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE)
                as ConnectivityManager
        networkCallback?.let { cm.unregisterNetworkCallback(it) }
        networkCallback = null
    }
}
```

---

## Dart FFI — native C/C++ integration

```dart
// lib/src/ffi/image_processor.dart
import 'dart:ffi';
import 'package:ffi/ffi.dart';

// Load native library
final _lib = DynamicLibrary.open('libimage_processor.so'); // Android
// DynamicLibrary.process() for iOS (static linking)

// Bind native function
typedef _ProcessImageNative = Pointer<Uint8> Function(
  Pointer<Uint8> data,
  Int32 width,
  Int32 height,
);
typedef _ProcessImageDart = Pointer<Uint8> Function(
  Pointer<Uint8> data,
  int width,
  int height,
);

final _processImage = _lib
    .lookupFunction<_ProcessImageNative, _ProcessImageDart>('process_image');

// Dart wrapper
Future<Uint8List> processImageFfi(Uint8List imageData, int width, int height) {
  return Isolate.run(() {
    final pointer = calloc<Uint8>(imageData.length);
    try {
      pointer.asTypedList(imageData.length).setAll(0, imageData);
      final result = _processImage(pointer, width, height);
      return result.asTypedList(width * height * 4);
    } finally {
      calloc.free(pointer);
    }
  });
}
```

---

## Platform views (AndroidView / UiKitView)

```dart
// Embedding a native map view
class NativeMapView extends StatelessWidget {
  const NativeMapView({super.key, required this.initialLatLng});
  final LatLng initialLatLng;

  @override
  Widget build(BuildContext context) {
    // Always wrap in RepaintBoundary — platform views are expensive
    return RepaintBoundary(
      child: Platform.isAndroid
          ? AndroidView(
              viewType: 'com.example/native_map',
              creationParams: {
                'lat': initialLatLng.latitude,
                'lng': initialLatLng.longitude,
              },
              creationParamsCodec: const StandardMessageCodec(),
              layoutDirection: TextDirection.ltr,
            )
          : UiKitView(
              viewType: 'com.example/native_map',
              creationParams: {
                'lat': initialLatLng.latitude,
                'lng': initialLatLng.longitude,
              },
              creationParamsCodec: const StandardMessageCodec(),
            ),
    );
  }
}
```

---

## Permission handling

```dart
// Use permission_handler package — DO NOT write raw permission channels
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<PermissionResult> requestCamera() async {
    final status = await Permission.camera.request();
    return switch (status) {
      PermissionStatus.granted => PermissionResult.granted,
      PermissionStatus.denied => PermissionResult.denied,
      PermissionStatus.permanentlyDenied => PermissionResult.permanentlyDenied,
      _ => PermissionResult.denied,
    };
  }

  Future<void> openSettings() => openAppSettings();
}
```

---

## Background execution

### Android (WorkManager via workmanager package)

```dart
// Register background task
await Workmanager().initialize(callbackDispatcher, isInDebugMode: kDebugMode);
await Workmanager().registerPeriodicTask(
  'sync-task',
  'backgroundSync',
  frequency: const Duration(hours: 1),
  constraints: Constraints(networkType: NetworkType.connected),
);

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Background work — no BuildContext, no UI
    await SyncService().syncPendingQueue();
    return Future.value(true);
  });
}
```

### iOS (BGTaskScheduler)

Requires `flutter_background_fetch` or `background_fetch` package.
Register in `AppDelegate` + `Info.plist` with `BGTaskSchedulerPermittedIdentifiers`.

---

## Federated plugin checklist

When creating a plugin for reuse (internal or public):

```
□ Create package structure: interface + app-facing + android + ios
□ Platform interface extends PlatformInterface (prevents direct instantiation)
□ App-facing package only imports platform interface (not implementations)
□ Each platform implementation registers itself via registerWith()
□ Dart API is pure Dart (no platform imports)
□ Comprehensive dartdoc on all public API
□ Example app demonstrates all features
□ Tests for Dart logic (mock platform implementations)
□ README includes platform setup instructions
```

---

## Channel naming convention

```
com.{company}.{app_or_plugin}/{feature}

Examples:
com.example.app/camera
com.example.app/connectivity
com.example.myPlugin/bluetooth
```

Always use reverse domain notation. Never use generic names like `flutter/channel`.

---

## Anti-pattern detection

- MethodChannel name collisions (generic strings) → use reverse domain
- Native code called on main thread for long operations → use background thread/coroutine
- EventChannel without `onCancel` cleanup → memory/battery leak
- Platform view without RepaintBoundary → performance degradation
- Permission check without rationale flow (permanently denied case not handled)
- FFI pointer not freed → memory leak
- Background task accessing BuildContext → crashes in background
- `@pragma('vm:entry-point')` missing on background entry point → tree-shaken in release

---

## Uncertainty protocol

- `High` (≥ 0.80): platform requirements and native SDK docs available
- `Medium` (0.60–0.79): native API unclear or SDK undocumented
- `Low` (< 0.60): no native experience or unknown hardware constraints

---

## Cross-skill handoff payload

Use the standard payload from `../../AGENTS.md`.
Set `requesting_skill` to `flutter-platform-integration`.

---

## Output contract

Follow global section order from `../../AGENTS.md`. Also include:

- `Channel mechanism selection rationale`
- `Dart + Android (Kotlin) + iOS (Swift) implementation`
- `Error mapping from platform exceptions to domain exceptions`
- `Memory/resource cleanup strategy`
- `Test strategy for platform code`

---

## Related resources

- `references/method-channel-guide.md`
- `references/event-channel-guide.md`
- `references/ffi-guide.md`
- `references/platform-views-guide.md`
- `references/background-execution.md`
- `templates/method-channel.dart`
- `templates/method-channel-android.kt`
- `templates/method-channel-ios.swift`
- `templates/event-channel.dart`
- `templates/ffi-binding.dart`
