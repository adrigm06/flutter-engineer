---
name: flutter-performance
description: >
  Lead authority for Flutter runtime performance. Use when diagnosing jank, memory leaks,
  excessive rebuilds, slow startup, GC pressure, frame budget violations, or requesting
  performance optimization plans.
---

# Flutter Performance Skill

## Purpose

Improve Flutter runtime performance through evidence-driven diagnosis, targeted optimizations,
and regression-resistant controls. Optimize for frame budget, startup, memory, and
perceived responsiveness.

## Scope and authority

This skill is the **lead authority** for:

- frame-time stability and jank (UI thread + raster thread)
- cold/warm startup and time-to-first-frame
- memory pressure, GC storms, and leak detection
- excessive rebuild identification and containment
- battery and thermal efficiency
- isolate offloading strategy for CPU-heavy work

Supporting interactions:

- align structural changes with `flutter-architecture`
- align rendering pipeline interventions with `flutter-rendering`
- align release risk and rollback gates with `flutter-build-release`

---

## When to use

- App exhibits jank, dropped frames, or stuttering animations
- Memory usage grows unbounded or OOM crashes occur
- Cold startup is too slow for acceptable UX
- Rebuild profiling shows excessive widget reconstruction
- Performance regression detected in CI or production monitoring
- Requesting 30/60/90-day performance improvement plan

---

## Decision engine workflow

1. Define user-impact performance goals and frame budget.
2. Capture baseline metrics and reproducible traces (DevTools, Perfetto).
3. Rank bottlenecks by user impact vs fix cost.
4. Choose intervention branch and expected gain.
5. Validate with before/after evidence.
6. Install regression guardrails (CI benchmarks, budget gates).

---

## Branching decision tree

### Branch A: bottleneck domain classification

- **Rebuild-heavy** (widget layer):
  - Profile with Flutter DevTools → Widget Rebuild Count
  - Apply `select()`, `const`, `RepaintBoundary`, `Consumer` scoping
  - Replace `MediaQuery.of(context)` with `LayoutBuilder` in leaf widgets

- **Raster-heavy** (rendering):
  - Profile with DevTools → Timeline → GPU frame
  - Reduce layer count, avoid excessive Clip/Opacity
  - Add RepaintBoundary to isolate expensive subtrees
  - Escalate complex cases to `flutter-rendering`

- **Startup-heavy** (initialization):
  - Defer non-critical initialization after first frame
  - Use `FlutterNativeSplash` or native splash while initializing
  - Lazy-load heavy providers (Riverpod `keepAlive: false`)
  - Lazy imports with deferred loading (Dart deferred)

- **Memory/GC-heavy**:
  - Profile with DevTools → Memory → Allocation Tracker
  - Identify image cache leaks (`imageCache.maximumSizeBytes`)
  - Dispose controllers (animation, text, scroll) in `dispose()`
  - Check for closure captures holding large objects

- **CPU/Isolate-heavy**:
  - Move any computation > 4ms off UI thread using `Isolate.run()`
  - Use `compute()` for simple one-shot operations
  - Long-lived workers: `Isolate.spawn()` with port communication

### Branch B: intervention aggressiveness

- **Near release** (< 2 weeks to ship):
  - Prefer low-blast-radius fixes with measurable gain
  - Avoid architectural refactors
  - Quick wins: `const` everywhere, select() granularity, dispose() fixes

- **Post-release hardening window**:
  - Allow deeper refactors validated by benchmark/regression coverage
  - Structural rebuild optimizations, deferred loading, isolate offloading

### Branch C: broad optimization scope ("optimize the app")

Return a staged plan — never ad-hoc tips:

#### 30/60/90 plan

- **Day 0–30 (Baseline and containment)**:
  - Establish startup/jank/memory/GC baselines with DevTools
  - Instrument critical user journeys (auth, home, checkout)
  - Fix highest-severity regressions with low blast radius
  - Add `const` everywhere, fix dispose() leaks, add RepaintBoundary

- **Day 31–60 (Targeted optimization)**:
  - Optimize top 3 bottlenecks by measured user impact
  - Implement select() granularity, isolate offloading
  - Validate before/after deltas against regression budgets
  - Add DevTools performance timeline annotations

- **Day 61–90 (Scale and prevention)**:
  - Codify performance gates in CI (flutter_driver benchmarks)
  - Add regression alerts, ownership, and playbooks
  - Retire temporary workarounds with expiry criteria
  - Enable Impeller if not already (eliminates shader jank)

---

## Quantitative gates

Label each gate `pass | at-risk | fail`:

| Gate | Threshold | Priority |
|---|---|---|
| Frame budget | 16ms UI + 16ms raster (60fps) | Critical |
| Cold startup | < 2s on mid-range Android (P50) | High |
| Rebuild count per interaction | < 50 widget rebuilds for simple tap | Medium |
| Memory RSS growth | < 10% per session compared to baseline | High |
| GC pause frequency | < 1 major GC per 30s during active use | Medium |
| CI benchmark regression | < 5% slowdown vs baseline | High |

If no reliable baseline exists → return measurement-first plan before recommending optimizations.

---

## Flutter-specific optimization rules

### const everywhere
```dart
// ✅ Always use const where possible
const SizedBox(height: 16),
const Text('Hello', style: TextStyle(fontSize: 16)),

// ❌ Without const — rebuilds unnecessarily
SizedBox(height: 16), // not const
```

### RepaintBoundary for expensive subtrees
```dart
// ✅ Isolate frequently-updating subtrees
RepaintBoundary(
  child: AnimatedChart(data: chartData), // expensive, updates frequently
)
```

### select() for granular subscriptions
```dart
// ✅ Only rebuilds when name changes
final name = ref.watch(userProvider.select((u) => u.name));

// ❌ Rebuilds when anything in user changes
final user = ref.watch(userProvider);
```

### Isolate offloading
```dart
// ✅ Heavy computation off UI thread
final parsed = await Isolate.run(() => parseHeavyJson(rawJson));

// ❌ Blocks UI thread
final parsed = parseHeavyJson(rawJson); // synchronous
```

### Image memory management
```dart
// ✅ Limit image cache size
PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024; // 50MB

// ✅ Use ResizeImage to decode at display size
Image(image: ResizeImage(NetworkImage(url), width: 200, height: 200))
```

---

## Tradeoff realism

- A smaller guaranteed gain beats a risky large refactor near release.
- Defer low-impact tuning when top bottlenecks remain unresolved.
- `const` and `select()` are free wins — always apply first.
- Do not recommend optimization theater without measurable user impact.

---

## Anti-pattern detection

- Optimize without baseline evidence
- Broad refactor proposals for localized bottlenecks
- `MediaQuery.of(context)` in leaf widgets (causes unnecessary parent rebuilds)
- `IntrinsicHeight/Width` in scroll hot paths (expensive layout computation)
- `Opacity` widget for decoration (forces compositing layer)
- `ClipRRect` used decoratively (use `borderRadius` on decoration)
- Missing `dispose()` for animation controllers, text controllers, scroll controllers
- `Column(children: items.map(...).toList())` for long lists (use ListView.builder)
- Heavy JSON parsing on UI isolate
- Image cache uncapped growing unbounded

---

## Uncertainty protocol

- `High` (≥ 0.80): have DevTools traces, clear bottleneck
- `Medium` (0.60–0.79): symptoms clear but no trace evidence
- `Low` (< 0.60): reported complaint only, no reproduction

If Medium/Low: request DevTools timeline export, Flutter Observatory dump, or reproduction steps.

---

## Cross-skill handoff payload

Use the standard payload from `../../AGENTS.md`.
Set `requesting_skill` to `flutter-performance`.

---

## Output contract

Follow global section order from `../../AGENTS.md`. Also include:

- `Symptoms and probable bottlenecks`
- `Profiling/instrumentation plan`
- `Priority optimization plan (by impact/cost ratio)`
- `Expected delta and tradeoffs`
- `Verification metrics`
- `Regression prevention controls`

---

## Related resources

- `references/profiling-playbook.md`
- `references/devtools-guide.md`
- `references/impeller-migration.md`
- `templates/performance-audit.md`
- `templates/benchmark-test.dart`
