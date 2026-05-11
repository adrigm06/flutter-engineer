---
name: flutter-code-review
description: >
  Lead authority for Flutter code review and tech debt assessment. Use when reviewing
  PRs, auditing codebases, prioritizing refactoring, or synthesizing findings across
  architecture, security, performance, and testing domains.
---

# Flutter Code Review Skill

## Purpose

Synthesize findings from across all Flutter engineering domains into a prioritized,
actionable review with clear severity classification — not a list of style nits.

## Scope and authority

This skill is the **lead authority** for:

- PR review and code quality assessment
- tech debt severity classification
- cross-domain finding synthesis
- review finding prioritization
- refactoring sequencing recommendations
- standards enforcement reporting

This skill **activates domain skills** for deep-domain findings:
- Security violations → escalate to `flutter-security` (may trigger override)
- Architecture violations → `flutter-architecture`
- Performance anti-patterns → `flutter-performance`
- Test gaps → `flutter-testing`

---

## Review severity rubric

| Severity | Definition | Action |
|---|---|---|
| **Critical** | Security exposure, data loss risk, architecture breakage, exploitability, release blocker | Block merge |
| **High** | Likely production incident, major performance degradation, significant maintainability risk | Must fix before merge |
| **Medium** | Important improvement, moderate risk, non-trivial technical debt | Fix this sprint |
| **Low** | Style, minor naming, small improvement | Fix at convenience |
| **Nitpick** | Subjective preference, no risk impact | Author discretion |

---

## Review checklist (systematic, per domain)

### 1. Architecture and layering

```
□ No business logic in widget build() methods
□ No repositories or data sources accessed from UI layer
□ Feature-first structure maintained (no global screens/models/services)
□ No circular dependencies between packages/features
□ No feature-to-feature direct imports
□ Domain models are pure Dart (no Flutter framework imports)
□ DI wiring via Riverpod providers (no manual instantiation in widgets)
□ No GetX usage
```

### 2. State management

```
□ ref.watch() only in build() — not in callbacks
□ ref.read() used in event handlers / onPressed
□ select() used when only part of state is needed
□ No setState() for shared/app state
□ Providers defined in provider files (not inside widgets)
□ AsyncNotifier used for async operations (not manual isLoading bool)
□ No global mutable singletons
□ Providers properly overridden in tests
```

### 3. Flutter-specific

```
□ const constructors used wherever applicable
□ ListView.builder used for all lists (not Column + map + toList)
□ FutureBuilder not recreated in build() — future assigned in initState or state notifier
□ mounted check after every async operation using BuildContext
□ dispose() implemented for all controllers (animation, text, scroll, stream subscriptions)
□ No print() statements in production code
□ RepaintBoundary used for expensive, independently-repainting subtrees
□ No IntrinsicHeight/Width in scroll hot paths
□ No Opacity widget for decoration (use withOpacity on Color)
□ No ClipRRect used decoratively (use BoxDecoration.borderRadius)
```

### 4. Security

```
□ No tokens/PII in SharedPreferences → flutter_secure_storage only
□ No API keys or secrets in source code
□ No sensitive data in log statements (even debug logs)
□ Dio interceptors do not log Authorization headers
□ No HTTP cleartext in production config
□ --obfuscate flag documented in release instructions
□ No dynamic that could mask type safety violations
```

### 5. Networking

```
□ All HTTP calls go through repository → remote data source (not directly in UI)
□ Auth interceptor handles token refresh transparently
□ Retry interceptor with backoff in place
□ CancelToken used for search/type-ahead requests
□ Timeout configured on Dio (not unbounded)
□ Logging interceptor disabled in release mode
□ No raw dynamic parsing of API responses (use fromJson with typed models)
```

### 6. Async safety

```
□ No BuildContext used after await without mounted check
□ No unawaited futures silently discarded (use unawaited() explicitly or await)
□ No async void methods except for top-level event handlers
□ Timer.periodic cancelled in dispose()
□ StreamSubscription.cancel() called in dispose()
□ No isolate spawned without error handler
```

### 7. Testing

```
□ New features have unit tests for domain/application layer
□ New screens have widget tests
□ FakeRepository used (not mocked repository) for stateful test scenarios
□ No DateTime.now() in testable code (inject Clock)
□ No network calls in unit/widget tests
□ Golden tests updated when design changes
□ Patrol test added for new critical journey (or tech debt tracked)
```

### 8. Performance

```
□ No MediaQuery.of(context) in leaf widgets (causes unnecessary parent rebuilds)
□ No ItemBuilder recreating expensive widgets without caching
□ Isolate.run() used for heavy computation (JSON decode, image processing)
□ Image loading uses cached_network_image or ResizeImage
□ No unnecessary AnimationController created without disposal
```

---

## Review output format

```markdown
## Code Review Summary

### Critical (block merge)
[findings]

### High (must fix before merge)
[findings]

### Medium (fix this sprint)
[findings]

### Low / Nitpick (author discretion)
[findings]

### Positive findings (reinforce good patterns)
[findings]

### Suggested refactoring sequence
[prioritized next steps beyond this PR]
```

---

## Anti-pattern detection across review

Automatically flag any of the global anti-patterns from `../../PROJECT_RULES.md`.

Additionally:

- Test coverage reduction in critical flows (compared to baseline)
- PR scope creep (mixing unrelated concerns — suggest splitting)
- Temporary compromises without comments, TODOs, or tracking tickets
- Inconsistent naming patterns breaking codebase conventions
- Missing error handling on user-visible async operations

---

## Cross-domain escalation rules

| Finding type | Escalate to |
|---|---|
| Security vulnerability | `flutter-security` (may trigger release block) |
| Architecture boundary violation | `flutter-architecture` |
| Performance regression suspected | `flutter-performance` |
| Test coverage gap on critical path | `flutter-testing` |
| Build/CI breakage | `flutter-ci-cd` |

---

## Uncertainty protocol

- `High` (≥ 0.80): full code context available, requirements known
- `Medium` (0.60–0.79): partial context or unclear requirements
- `Low` (< 0.60): reviewing code without understanding domain

---

## Cross-skill handoff payload

Use the standard payload from `../../AGENTS.md`.
Set `requesting_skill` to `flutter-code-review`.

---

## Output contract

Return findings in severity order. Also include:

- `Summary: severity counts`
- `Findings by severity with code location + evidence + fix`
- `Cross-skill escalations`
- `Positive patterns to reinforce`
- `Suggested refactoring sequence`

---

## Related resources

- `references/review-checklist.md`
- `references/anti-patterns.md`
- `templates/review-report.md`
