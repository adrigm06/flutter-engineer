// Debugging checklist — hypothesis-driven investigation guide
// Fill in as you narrow down the root cause

// ===========================================================================
// STEP 1: EVIDENCE COLLECTION
// ===========================================================================

/*
Bug description: [What is the observed behavior?]
Expected behavior: [What should happen?]
First occurrence: [When did this start? After which release/change?]
Reproduction rate: [Always / Sometimes / Rarely / Once]
Affected users: [All / % / Specific device/OS/region]
Platforms: [ ] Android  [ ] iOS  [ ] Web  [ ] Desktop

Available evidence:
[ ] Stack trace (paste below)
[ ] DevTools timeline screenshot
[ ] DevTools memory snapshot
[ ] Crashlytics report URL
[ ] Reproduction steps (deterministic)
[ ] Affected Flutter/Dart version
[ ] Affected device models/OS versions

--- Stack trace (deobfuscated) ---
[paste here]
---
*/

// ===========================================================================
// STEP 2: BUG DOMAIN CLASSIFICATION
// ===========================================================================

/*
Primary domain (circle one):
  [ ] Dart crash (null, range error, state error)
  [ ] Native crash (tombstone, Xcode crash log)
  [ ] Jank / dropped frames
  [ ] Memory leak / OOM
  [ ] Layout overflow
  [ ] Async hang / infinite loading
  [ ] Platform channel failure
  [ ] Release-only bug
  [ ] Flaky (non-deterministic)
*/

// ===========================================================================
// STEP 3: HYPOTHESES (ranked by confidence)
// ===========================================================================

/*
Hypothesis 1 (confidence: 0.XX): [Description]
  Evidence FOR:    [What supports this hypothesis?]
  Evidence AGAINST: [What contradicts this?]
  Validation step: [How to confirm or reject?]
  Validated: [ ] Confirmed  [ ] Rejected  [ ] Pending

Hypothesis 2 (confidence: 0.XX): [Description]
  Evidence FOR:
  Evidence AGAINST:
  Validation step:
  Validated: [ ] Confirmed  [ ] Rejected  [ ] Pending

Hypothesis 3 (confidence: 0.XX): [Description]
  Evidence FOR:
  Evidence AGAINST:
  Validation step:
  Validated: [ ] Confirmed  [ ] Rejected  [ ] Pending

→ Start with: Hypothesis [X] (highest confidence × impact)
*/

// ===========================================================================
// STEP 4: INSTRUMENTATION ADDITIONS
// ===========================================================================

/*
Add these to narrow down root cause:
[ ] Log entry/exit of [method] to confirm code path
[ ] Add timeout() to [async operation] to surface hang
[ ] Add mounted check after [await] to check for disposal race
[ ] Enable DevTools → Widget Rebuild Tracker for [screen]
[ ] Take heap snapshot before and after [operation]
[ ] Add Timeline markers around [suspected bottleneck]
*/

// Useful snippets for debugging
import 'dart:developer';

// Add timeout to surface hung futures
Future<T> withTimeout<T>(Future<T> future, {String? label}) =>
    future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException(
        label != null ? '$label timed out' : 'Operation timed out',
      ),
    );

// mounted check pattern (ALWAYS after await when using context)
Future<void> loadAndNavigate(BuildContext context) async {
  final result = await someAsyncOperation();
  if (!context.mounted) return; // ← ALWAYS check after await
  context.go('/result');
}

// Log breadcrumb (survives even if app crashes shortly after)
void logBreadcrumb(String step) {
  FirebaseCrashlytics.instance.log('[DEBUG] $step at ${DateTime.now()}');
  Timeline.instantSync('DEBUG: $step'); // Also appears in DevTools timeline
}

// ===========================================================================
// STEP 5: ROOT CAUSE AND FIX
// ===========================================================================

/*
Root cause confirmed: [Description of confirmed root cause]
Evidence that confirms it: [Specific evidence]

Fix:
  Before:
    [old code]
  After:
    [new code]

Why this fixes it: [Explanation]

Regression test:
  [ ] Unit test added for the failure case
  [ ] Widget test covers the symptom
  [ ] E2E test for the user journey (if critical)
*/

// ===========================================================================
// STEP 6: PREVENTION
// ===========================================================================

/*
How to prevent recurrence:
[ ] Add lint rule to catch similar pattern
[ ] Add unit test for this code path
[ ] Add E2E test for this user journey
[ ] Update code review checklist with this pattern
[ ] Create tech debt ticket for related fragility
[ ] Update runbook/playbook with this investigation approach
*/
