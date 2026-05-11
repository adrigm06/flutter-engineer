# Flutter Performance Reference

## Frame Budget

```
60fps → 16.6ms total per frame
  UI Thread (Dart):    ≤ 8ms
  Raster Thread (GPU): ≤ 8ms

120fps → 8.3ms total per frame (Impeller on modern devices)
```

**Rule**: If either thread exceeds its budget → jank. Identify WHICH thread to apply the right fix.

---

## UI Thread vs Raster Thread problems

| Symptom in DevTools | Problem is in | Likely cause | Fix |
|---|---|---|---|
| UI thread spikes (tall blue bars) | Dart/UI | Heavy `build()`, sync compute | Move to Isolate, reduce rebuilds |
| Raster thread spikes (tall green bars) | GPU/Raster | Too many layers, shaders, SVG | RepaintBoundary, cache, simplify layers |
| Both spiking | Both | Complex animation + logic | Split concerns, reduce compositing |
| Memory grows unbounded | Memory | Leak, uncached images, too many objects | Identify with DevTools Memory |

---

## Rebuild optimization

### Use `select()` for granular subscriptions

```dart
// ❌ Rebuilds whenever any user property changes
final user = ref.watch(userProvider);
Text(user.displayName);

// ✅ Only rebuilds when displayName changes
final displayName = ref.watch(userProvider.select((u) => u.displayName));
Text(displayName);
```

### const constructors (free optimization)

```dart
// ✅ const — Flutter skips rebuilding this entirely
const SizedBox(height: 16)
const Icon(Icons.home)
const EdgeInsets.all(16)

// Rule: add const wherever possible — zero rebuild cost
```

### RepaintBoundary — isolate expensive widgets

```dart
// Prevents repaints from propagating into expensive children
RepaintBoundary(
  child: ComplexChartWidget(data: data),
)

// When to add RepaintBoundary:
// - Custom painters (CustomPaint)
// - Animated widgets that animate frequently
// - Platform views (AndroidView, UiKitView)
// - Lists where cells animate independently
```

### ListView.builder over Column

```dart
// ❌ Builds ALL items immediately
Column(children: products.map((p) => ProductCard(p)).toList())

// ✅ Builds only visible items (lazy)
ListView.builder(
  itemCount: products.length,
  itemBuilder: (_, i) => ProductCard(products[i]),
)

// ✅ For variable height items
ListView.builder(
  itemCount: items.length,
  itemBuilder: (_, i) => items[i],
)

// ✅ For known extent items (most performant — avoids layout calculation)
ListView.builder(
  itemExtent: 72, // Fixed row height
  itemCount: items.length,
  itemBuilder: (_, i) => FixedHeightCard(items[i]),
)
```

---

## Isolate patterns (CPU-intensive work)

```dart
// Compute: single async computation on separate isolate
Future<List<Product>> parseProducts(String json) =>
    Isolate.run(() {
      final data = jsonDecode(json) as List<dynamic>;
      return data.cast<Map<String, dynamic>>().map(Product.fromJson).toList();
    });

// When to use Isolate:
// - JSON parsing > 1MB
// - Image processing (resize, crop, compress)
// - Encryption/decryption
// - Heavy sorting/filtering
```

---

## Image optimization

```dart
// ✅ Cache network images
CachedNetworkImage(
  imageUrl: url,
  cacheManager: CustomCacheManager.instance,
  memCacheWidth: 400,  // Limit decode size to display size
  memCacheHeight: 400,
)

// ✅ Preload images before navigation (smooth transitions)
await precacheImage(NetworkImage(nextScreenImageUrl), context);

// ✅ Resize assets for correct density
// pubspec.yaml:
//   flutter:
//     assets:
//       - assets/images/hero.png
// Supply 1x, 2x, 3x variants: assets/images/hero.png,
//   assets/images/2.0x/hero.png, assets/images/3.0x/hero.png
```

---

## Startup performance

### Defer non-critical initialization

```dart
// bootstrap.dart — critical only before runApp()
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // CRITICAL (block startup)
  await Firebase.initializeApp();
  
  runApp(const MyApp());
  
  // NON-CRITICAL (run after first frame)
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await _initNonCritical();
  });
}

Future<void> _initNonCritical() async {
  await analytics.init();
  await NotificationService.instance.init();
  // etc.
}
```

---

## Shader warm-up (Impeller)

```dart
// With Impeller: shader pre-compilation happens automatically
// DO NOT use shaderWarmUp manually on Impeller

// With Skia (legacy): use if cold shader compilation causes jank
void main() {
  if (!Platform.isIOS) { // iOS uses Impeller
    FlutterView shaderWarmUp = CustomShaderWarmUp();
    // Uncomment only if profiling shows shader jank on Skia
  }
  runApp(const MyApp());
}
```

---

## Memory management rules

1. Always dispose `AnimationController`, `StreamSubscription`, `TextEditingController`
2. Never store `BuildContext` in long-lived objects
3. Scope `ProviderContainer` — always call `container.dispose()`
4. Use `ImageProvider.evict()` to free cached images when no longer needed
5. Monitor with DevTools Memory → Allocation Tracker during stress tests
6. Set `imageCache.maximumSizeBytes` if using many large images

```dart
// Dispose pattern in ConsumerStatefulWidget
@override
void dispose() {
  _animController.dispose();
  _textController.dispose();
  _scrollController.dispose();
  // _subscription?.cancel(); — if any
  super.dispose();
}
```
