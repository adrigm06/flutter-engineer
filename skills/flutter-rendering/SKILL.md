---
name: flutter-rendering
description: >
  Lead authority for Flutter rendering pipeline internals. Use when diagnosing
  shader jank, raster thread overload, Impeller migration, layer tree optimization,
  complex animation performance, or understanding the Flutter engine render path.
---

# Flutter Rendering Skill

## Purpose

Diagnose and optimize the Flutter rendering pipeline — from widget tree to pixels.
Understand Impeller, the raster thread, layer trees, and rendering bottlenecks.

## Scope and authority

This skill is the **lead authority** for:

- Impeller rendering engine (iOS, Android, macOS, Linux)
- SkSL shader warmup (legacy Skia)
- raster thread and UI thread separation
- layer tree composition and optimization
- RepaintBoundary placement strategy
- custom painting (CustomPainter, Canvas)
- platform view rendering (AndroidView, UiKitView)
- shader compilation jank detection and elimination
- animation rendering pipeline

Supporting interactions:

- coordinate frame-budget violations with `flutter-performance`
- coordinate platform view decisions with `flutter-platform-integration`

---

## When to use

- Diagnosing shader compilation jank (legacy Skia builds)
- Understanding Impeller rendering vs Skia differences
- Debugging raster thread overload
- Optimizing complex custom paintings
- Diagnosing platform view jank
- Designing animation architectures for smooth 120fps
- Understanding layer tree composition costs

---

## Flutter rendering pipeline overview

```
Widget Tree
    ↓ build()
Element Tree (reconciliation / diffing)
    ↓ layout + paint
RenderObject Tree
    ↓ compositing
Layer Tree
    ↓ rasterization
GPU / Skia (legacy) / Impeller (modern)
    ↓
Display
```

### Two threads that matter

| Thread | Responsibility | Jank if blocked? |
|---|---|---|
| UI Thread (main isolate) | widget build(), layout, paint → layer tree | Yes — frame skipped |
| Raster Thread | layer tree → GPU draw calls | Yes — frame skipped |

Both must complete within 16ms (60fps) or 8.3ms (120fps).

---

## Impeller (2026 status)

Impeller is the **default renderer** on:
- iOS (since Flutter 3.10)
- Android (since Flutter 3.19, enabled by default Flutter 3.27+)
- macOS (in progress)
- Linux (in progress)

### Key Impeller advantages

- **Eliminates shader compilation jank**: pre-compiles all shaders at engine build time
- Faster first-frame rendering
- Better baseline performance on complex scenes
- No SkSL cache file needed for new projects

### Impeller migration (from Skia)

```yaml
# pubspec.yaml — enable Impeller on Android explicitly if not default
# (no action needed on iOS — enabled by default)
```

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<meta-data
    android:name="io.flutter.embedding.android.EnableImpeller"
    android:value="true" />
```

### Impeller known limitations (2026)

- Some advanced `CustomPainter` operations may differ visually from Skia
- Platform views (Hybrid Composition) have different compositing behavior
- Some gradient types render differently — validate with golden tests

---

## Legacy Skia: SkSL warmup (pre-Impeller apps)

For apps still on Skia renderer:

```bash
# 1. Capture SkSL shaders from a test run
flutter run --cache-sksl --purge-persistent-cache

# 2. Bundle the captured SkSL file
flutter build apk --bundle-sksl-path flutter_01.sksl.json

# 3. Include in CI build pipeline
```

---

## Layer tree optimization

### RepaintBoundary placement

RepaintBoundary creates a new compositing layer. Use it to isolate expensive subtrees:

```dart
// ✅ Use for subtrees that repaint frequently and independently
RepaintBoundary(
  child: LiveChart(data: stream), // repaints every frame
)

// ✅ Use for subtrees that rarely change but are expensive to repaint
RepaintBoundary(
  child: ComplexBackgroundWidget(), // expensive, but static
)

// ❌ Do NOT use RepaintBoundary for everything
// Every boundary has a memory cost (GPU texture allocation)
// Profile before adding
```

### Layer tree cost analysis

Use DevTools → Flutter Inspector → Render Object tree to identify:
- Layers with excessive children
- Compositing layers from unnecessary Opacity widgets
- Clip layers from ClipRRect used decoratively

### Reducing compositing layers

```dart
// ❌ Creates compositing layer unnecessarily
Opacity(
  opacity: 0.8,
  child: Container(color: Colors.blue),
)

// ✅ No extra layer needed
Container(color: Colors.blue.withOpacity(0.8))

// ❌ Creates Clip layer unnecessarily
ClipRRect(
  borderRadius: BorderRadius.circular(8),
  child: Container(color: Colors.blue),
)

// ✅ Use decoration instead
Container(
  decoration: BoxDecoration(
    color: Colors.blue,
    borderRadius: BorderRadius.circular(8),
  ),
)
```

---

## Custom painting optimization

```dart
// ✅ shouldRepaint — minimize repaints
class ChartPainter extends CustomPainter {
  const ChartPainter({required this.data});
  final List<double> data;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw chart
  }

  @override
  bool shouldRepaint(ChartPainter old) => old.data != data; // ✅ Value comparison

  // ❌ return true always — repaints every frame
  // @override bool shouldRepaint(_) => true;
}
```

---

## Animation rendering decisions

| Animation type | Solution | Notes |
|---|---|---|
| Simple transitions | `AnimationController` + `Tween` | Lowest cost |
| Implicit animations | `AnimatedContainer`, `AnimatedOpacity` | Convenient, slightly higher overhead |
| Physics-based | `SpringSimulation`, `FrictionSimulation` | Natural feel |
| Complex choreography | `AnimationController` + staggered | Manual but precise |
| Lottie/Rive | `rive` or `lottie` packages | GPU-heavy, use RepaintBoundary |
| Particle effects | Custom painter + isolate data | Keep off UI thread if heavy |

---

## Platform view rendering

Platform views (embedding native Android/iOS views) have performance implications:

| Mode | Android | iOS | GPU cost |
|---|---|---|---|
| Hybrid Composition | Default | Default | Higher — native view in Flutter layer |
| Virtual Display (Android) | Legacy | N/A | Lower — but input event issues |

```dart
// ✅ Wrap platform views in RepaintBoundary
RepaintBoundary(
  child: AndroidView(
    viewType: 'map_view',
    layoutDirection: TextDirection.ltr,
  ),
)
```

---

## Anti-pattern detection

- Using `Opacity` widget instead of `Color.withOpacity()` for static transparency
- Using `ClipRRect` for visual decoration (creates Clip layer)
- Missing `shouldRepaint` optimization in `CustomPainter`
- Excessive RepaintBoundary without profiling (memory waste)
- Heavy computation in `CustomPainter.paint()` (use isolate for data prep)
- Not migrating to Impeller (shipping shader jank that is preventable)
- Platform views without RepaintBoundary isolation

---

## Uncertainty protocol

- `High` (≥ 0.80): DevTools timeline trace available with clear raster/UI thread data
- `Medium` (0.60–0.79): jank reported but no trace
- `Low` (< 0.60): vague complaint, no reproduction

Request DevTools → Performance overlay screenshot or timeline export.

---

## Cross-skill handoff payload

Use the standard payload from `../../AGENTS.md`.
Set `requesting_skill` to `flutter-rendering`.

---

## Output contract

Follow global section order from `../../AGENTS.md`. Also include:

- `Rendering pipeline analysis`
- `Impeller status assessment`
- `Layer tree optimization plan`
- `RepaintBoundary placement rationale`
- `Verification via DevTools`

---

## Related resources

- `references/impeller-migration.md`
- `references/layer-tree-guide.md`
- `references/custom-painter-patterns.md`
- `templates/custom-painter.dart`
- `templates/animation-controller.dart`
