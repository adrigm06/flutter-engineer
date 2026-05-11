---
name: flutter-debugging
description: >
  Lead authority for Flutter debugging and root-cause analysis. Use when investigating
  crashes, ANRs, jank, layout overflow, memory leaks, isolate failures, async deadlocks,
  plugin failures, or release-only bugs. Returns ranked hypotheses with reproduction plans.
---

# Flutter Debugging Skill

## Purpose

Diagnose and resolve Flutter bugs through systematic root-cause analysis — ranked hypotheses,
reproduction strategies, instrumentation plans, and confidence updates.

## Scope and authority

This skill is the **lead authority** for:

- root-cause triage for crashes, freezes, and jank
- hypothesis generation and confidence ranking
- reproduction plan design
- instrumentation and logging strategy for debugging
- async/isolate deadlock analysis
- plugin and platform channel failure diagnosis
- release-only bug investigation
- memory leak analysis
- layout overflow debugging

---

## When to use

- App crashes in production or during development
- Jank or ANR reported (app appears frozen)
- Bug that only appears in release builds
- Memory keeps growing (unbounded memory leak)
- Async operation hangs indefinitely
- Plugin or platform channel throws unexpectedly
- Layout overflow (RenderFlex overflowed error)
- Widget test or integration test fails intermittently

---

## Decision engine workflow

1. Collect available evidence (crash log, stacktrace, DevTools data, reproduction steps).
2. Classify bug domain (rendering / state / async / platform / memory).
3. Generate ranked hypotheses by probability and evidence fit.
4. Design minimal reproduction plan.
5. Define instrumentation additions needed to confirm/reject hypotheses.
6. Narrow hypotheses after each evidence update.
7. Return root cause + fix + regression prevention.

---

## Bug domain classification

| Domain | Signals | Lead investigation tool |
|---|---|---|
| Crash (Dart) | Stack trace in Crashlytics/console | Dart stack trace analysis |
| Crash (Native) | Native crash log, tombstone | Xcode/Android Studio crash |
| Jank / frame drop | Performance overlay, DevTools timeline | Flutter DevTools Performance |
| Memory leak | Growing memory profile, OOM | DevTools Memory tab |
| Layout overflow | RenderFlex overflowed assertion | Widget tree inspection |
| Async hang | Infinite loading, no response | Dart Observatory, logging |
| Isolate crash | Isolate died unexpectedly | Dart error_listener |
| Plugin failure | MissingPluginException | Plugin registration check |
| Platform channel crash | PlatformException | Native debug logs |
| Release-only bug | Only in `--release` mode | Deobfuscated symbols check |

---

## Hypothesis-driven debugging (mandatory)

Always generate ranked hypotheses before suggesting fixes:

```
Hypothesis 1 (confidence: 0.75): [description]
  Evidence for: [what supports this]
  Evidence against: [what contradicts this]
  Validation step: [how to confirm]

Hypothesis 2 (confidence: 0.60): [description]
  ...

Hypothesis 3 (confidence: 0.20): [description]
  ...

Recommended first validation: Hypothesis 1 (highest confidence × impact)
```

---

## Branching decision tree

### Branch A: Dart crash analysis

```
1. Obtain full stack trace (Crashlytics deobfuscated stack)
2. Identify top frame:
   - Null pointer → null safety violation or unchecked nullable
   - ConcurrentModificationException → List modified during iteration
   - RangeError → index out of bounds (empty list access)
   - StateError → FutureBuilder accessed after dispose
   - UnimplementedError → abstract method not implemented
3. Trace call chain back to first user code frame
4. Check for async gap (BuildContext used after await without mounted check)
```

### Branch B: memory leak analysis

```
1. Open DevTools → Memory tab
2. Take heap snapshot before and after suspected operation
3. Compare object counts between snapshots
4. Look for:
   - Growing GlobalKey count (orphaned widgets)
   - Growing StreamSubscription count (not cancelled)
   - Growing AnimationController count (not disposed)
   - Growing Timer count (not cancelled)
   - Image cache exceeding bounds
4. Find owner of leaked object via reference tree
5. Fix: ensure dispose() / cancel() / close() called in widget lifecycle
```

### Branch C: jank investigation

```
1. Enable Performance Overlay (WidgetsApp.showPerformanceOverlay)
2. Identify: UI thread spike vs Raster thread spike
   
   UI thread spike:
   → Check rebuild count (DevTools → Widget Rebuild Tracker)
   → Profile with Timeline in DevTools
   → Look for: heavy build(), layout passes, synchronous I/O

   Raster thread spike:
   → Look for: complex CustomPainter, excessive layers, Clip/Opacity
   → Check: platform view compositing overhead
   → Escalate to flutter-rendering for deep analysis

3. Add tracing markers:
   Timeline.startSync('heavy_operation');
   // ... operation
   Timeline.finishSync();
```

### Branch D: release-only bugs

Most common causes:
1. **Missing deobfuscation**: stacktrace is garbled → upload debug symbols to Crashlytics
2. **Tree shaking removed code**: reflection-based code eliminated → add `@pragma('vm:entry-point')`
3. **Assert-guarded code**: logic in `assert()` blocks doesn't run in release → move to runtime checks
4. **Missing plugin registration**: some plugins require explicit registration in release
5. **Stricter null safety**: release mode removes some null checks that catch in debug

```dart
// ❌ Debug-only code accidentally relied upon
assert(doSomethingImportant()); // Not called in release!

// ✅ Production-safe
final result = doSomethingImportant();
assert(result); // Optional debug assertion
```

### Branch E: async deadlock / infinite loading

```
1. Add logging at every async step (entry, await, return)
2. Check for:
   - Circular awaiting (A awaits B, B awaits A)
   - FutureBuilder never completing (Future.delayed gone forever)
   - StreamController not closing
   - Riverpod provider circular dependency
3. Use timeout() wrapper to surface hangs:
   await someOperation().timeout(
     const Duration(seconds: 10),
     onTimeout: () => throw TimeoutException('Operation hung'),
   );
4. Check Riverpod provider lifecycle: is build() ever completing?
```

### Branch F: layout overflow

```
RenderFlex overflowed — systematic fix:

1. Identify overflowing widget from error message (Row/Column)
2. Is it a text that can wrap? → Wrap Text in Flexible/Expanded
3. Is it a fixed-size widget in flex? → Use Flexible(child: ...) or SizedBox.shrink()
4. Is it a Column inside a ListView? → Remove unconstrained Column
5. Is it a Row/Column without Flexible/Expanded? → Add Expanded to the growing child
6. Is it caused by font scaling? → Set maxLines + overflow: TextOverflow.ellipsis
7. Use LayoutBuilder to inspect available constraints
```

---

## Common Flutter-specific bugs

| Bug pattern | Root cause | Fix |
|---|---|---|
| `mounted` crash after await | BuildContext used post-dispose | Check `mounted` before using context after every await |
| Keyboard overlaps content | No `resizeToAvoidBottomInset` | Set `Scaffold.resizeToAvoidBottomInset: true` |
| initState async not completing | Cannot use async in initState | Use `addPostFrameCallback` or async factory pattern |
| setState after dispose | Timer/stream fires after widget disposed | Cancel subscriptions in dispose() |
| InkWell tap not working | Missing Material ancestor | Wrap in Material widget |
| Hero animation broken | Hero tags not unique | Ensure unique tags across route transitions |
| ListView.builder jumps | Missing `key` on list items | Add `ValueKey(item.id)` to list items |
| FutureBuilder flickering | Future recreated in build() | Move Future to state initialization |

---

## Anti-pattern detection

- Suggesting fixes before ranking hypotheses
- Fixing symptoms without understanding root cause
- `print()` debugging in production (use structured logging)
- Not deobfuscating release crash stacks before analysis
- Suggesting "try/catch everything" as a fix
- Fixing crash by suppressing error instead of resolving cause

---

## Uncertainty protocol

- `High` (≥ 0.80): full crash log + reproduction steps
- `Medium` (0.60–0.79): partial logs or inconsistent reproduction
- `Low` (< 0.60): "it sometimes crashes" with no evidence

Request minimum evidence: crash log OR DevTools snapshot OR minimal reproduction case.

---

## Cross-skill handoff payload

Use the standard payload from `../../AGENTS.md`.
Set `requesting_skill` to `flutter-debugging`.

---

## Output contract

Follow global section order from `../../AGENTS.md`. Also include:

- `Ranked hypotheses with confidence`
- `Reproduction strategy`
- `Instrumentation plan`
- `Evidence that would confirm/reject each hypothesis`
- `Root cause + fix + regression prevention`

---

## Related resources

- `references/crash-analysis-guide.md`
- `references/devtools-memory.md`
- `references/async-debugging.md`
- `references/release-debug-guide.md`
- `templates/debug-checklist.md`
