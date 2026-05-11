// Performance audit template — fill in DevTools measurements before optimizing
// Establishes baseline before touching anything. Never optimize without data.

// ===========================================================================
// HOW TO CAPTURE BASELINE
// ===========================================================================
//
// 1. Open DevTools: flutter run --profile
// 2. Open DevTools → Performance tab
// 3. Record interaction (e.g., scroll, navigate, load data)
// 4. Fill in PerformanceBaseline below
// 5. Identify bottleneck (UI thread or Raster thread)
// 6. Apply targeted fix
// 7. Re-measure and compare

// ===========================================================================
// PERFORMANCE BASELINE
// ===========================================================================

/*
Capture date: YYYY-MM-DD
Flutter version: 3.XX.X
Device: [Model, Android/iOS version]
Build mode: profile

── Frame budget analysis ─────────────────────────────────────────────────────
Target: 60fps = 16ms per frame (UI + Raster combined)

Cold startup (time to first interactive frame): ___ms  [target: < 2000ms]
Warm startup: ___ms

Scroll jank (ProductList): 
  - UI thread p50: ___ms  [target: < 16ms]
  - UI thread p95: ___ms
  - Raster thread p50: ___ms
  - Raster thread p95: ___ms
  - Jank frames (> 32ms): ___

Navigation transition (Home → Detail):
  - Transition duration: ___ms
  - Max frame time: ___ms

── Memory analysis ────────────────────────────────────────────────────────────
Session start RSS: ___MB
After 10 min active use RSS: ___MB
After 30 min active use RSS: ___MB
Peak RSS: ___MB

Image cache size: ___MB  [default limit: 100MB]
Object allocation rate: ___ objects/sec (from DevTools Memory tab)

── Widget rebuild analysis ────────────────────────────────────────────────────
(DevTools → Widget Rebuild Count during scroll)
HomeScreen rebuild count per scroll tick: ___
ProductCard rebuild count per scroll tick: ___
Total widget rebuilds per interaction: ___
*/

// ===========================================================================
// BOTTLENECK IDENTIFICATION
// ===========================================================================

/*
Primary bottleneck: [ ] UI Thread  [ ] Raster Thread  [ ] Memory  [ ] Startup

Evidence:
- [Paste relevant DevTools timeline section or memory snapshot details]

Top rebuild offenders:
1. [Widget name]: X rebuilds/sec — cause: [e.g., watching too-broad provider]
2. [Widget name]: X rebuilds/sec — cause: [...]
*/

// ===========================================================================
// OPTIMIZATION PLAN
// ===========================================================================

/*
Priority | Optimization                     | Expected gain | Status
---------|----------------------------------|---------------|--------
1 (High) | Add select() to userProvider     | -40% rebuilds | TODO
2 (High) | Wrap AnimatedChart in RepaintBoundary | -30% raster | TODO  
3 (Med)  | Move JSON parsing to Isolate.run | -8ms UI spike | TODO
4 (Low)  | Add const to 12 SizedBox() calls | Minor         | TODO
*/

// ===========================================================================
// POST-OPTIMIZATION MEASUREMENT
// ===========================================================================

/*
Capture date: YYYY-MM-DD
Flutter version: 3.XX.X (same as baseline)
Device: [Same device as baseline]

Cold startup: ___ms  (delta: ___ms, __%)
Scroll jank UI thread p95: ___ms (delta: ___ms, __%)
Scroll jank Raster p95: ___ms (delta: ___ms, __%)
Jank frames: ___ (delta: ___)
Memory after 10 min: ___MB (delta: ___MB)
Widget rebuilds per interaction: ___ (delta: ___)

Verdict: [ ] Passed frame budget  [ ] At-risk  [ ] Failed — further work needed
*/

// ===========================================================================
// USEFUL DART CODE FOR PROFILING
// ===========================================================================

// Add custom timeline markers to DevTools timeline
void profileHeavyOperation() {
  Timeline.startSync('MyApp.heavy_operation');
  try {
    // ... the operation being measured
  } finally {
    Timeline.finishSync();
  }
}

// Measure widget rebuild count (debug mode only)
class RebuildTracker extends StatefulWidget {
  const RebuildTracker({super.key, required this.name, required this.child});
  final String name;
  final Widget child;

  @override
  State<RebuildTracker> createState() => _RebuildTrackerState();
}

class _RebuildTrackerState extends State<RebuildTracker> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    assert(() {
      _count++;
      debugPrint('${widget.name} rebuilt: $_count times');
      return true;
    }());
    return widget.child;
  }
}
