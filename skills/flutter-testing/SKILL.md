---
name: flutter-testing
description: >
  Lead authority for Flutter testing strategy. Use when defining test pyramids,
  implementing unit/widget/golden/E2E tests, recovering from flaky suites,
  selecting tools (mocktail, Alchemist, Patrol), or establishing coverage gates.
---

# Flutter Testing Skill

## Purpose

Define risk-weighted Flutter testing strategy that maximizes confidence under cost,
speed, and maintainability constraints. Cover all layers: domain, data, presentation, E2E.

## Scope and authority

This skill is the **lead authority** for:

- test pyramid design and layer allocation
- unit testing strategy (domain, data, application layers)
- widget testing strategy (screens, components)
- golden test strategy (design system, brand-critical UI)
- E2E testing strategy (Patrol, critical user journeys)
- flakiness detection and elimination
- coverage gates and CI integration
- test tooling selection

Supporting interactions:

- defer production ship/no-ship to `flutter-build-release`
- align boundary-sensitive coverage with `flutter-architecture`
- coordinate performance test additions with `flutter-performance`

---

## When to use

- Defining test strategy for new feature or module
- Recovering from flaky or slow CI test suites
- Selecting minimum viable coverage under deadline pressure
- Implementing golden test infrastructure (Alchemist)
- Implementing E2E testing (Patrol) for critical journeys
- Requesting coverage gap analysis

---

## Required inputs

- architecture style in use (affects testability and isolation strategy)
- critical user journeys (determines E2E scope)
- deadline pressure (affects test depth allocation)
- current coverage metrics (if available)
- existing flakiness rate (if measured)
- target platforms (affects E2E execution environment)

---

## Decision engine workflow

1. Identify business-critical and failure-prone user journeys.
2. Classify risk by impact, probability, and detectability.
3. Allocate test depth per layer by ROI.
4. Design deterministic data and environment controls.
5. Define flakiness budget and quarantine policy.
6. Stage rollout and gate criteria by release risk.

---

## Test pyramid (Flutter-specific)

```
        ╔═════════╗
        ║  Patrol  ║  (E2E — 5%)
       ╔╩══════════╩╗
       ║  Alchemist  ║  (Golden — 5%)
      ╔╩═════════════╩╗
      ║ Widget Tests   ║  (20%)
     ╔╩════════════════╩╗
     ║    Unit Tests     ║  (70%)
     ╚══════════════════╝
```

### Unit tests (70% of suite)

**Scope**: domain models, use cases, repositories, notifiers, blocs, services, utilities

**Rules**:
- Use `mocktail` for mocking (not `mockito` — no code generation required)
- Prefer `Fake*` repository implementations over mocks for stateful behavior
- Always inject `Clock` — never call `DateTime.now()` directly in testable code
- Use `ProviderContainer` for testing Riverpod notifiers without widget tree
- No network calls, no disk I/O, no real database connections
- All test data must be deterministic (no random, no system time)

**Example pattern**:
```dart
group('AuthNotifier', () {
  late ProviderContainer container;
  late FakeAuthRepository fakeRepo;

  setUp(() {
    fakeRepo = FakeAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(fakeRepo)],
    );
  });

  tearDown(() => container.dispose());

  test('emits authenticated state on successful login', () async {
    await container.read(authNotifierProvider.notifier).login(
      email: 'test@example.com',
      password: 'secret',
    );
    expect(
      container.read(authNotifierProvider),
      isA<AuthAuthenticated>(),
    );
  });
});
```

### Widget tests (20% of suite)

**Scope**: all screens, reusable components with logic, navigation flows

**Rules**:
- Inject fake providers via `ProviderScope(overrides: [...])`
- Test semantics tree for accessibility compliance
- Use `WidgetTester.pumpAndSettle()` for async operations
- Test all interactive states (loading, error, empty, populated)
- Use `find.byKey(ValueKey('id'))` for stable widget targeting
- Pump localizations for internationalized text
- Test dark mode and text scale variants

**Example pattern**:
```dart
testWidgets('LoginScreen shows error on failed login', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(shouldFail: true),
        ),
      ],
      child: const MaterialApp(home: LoginScreen()),
    ),
  );

  await tester.tap(find.byKey(const ValueKey('login_button')));
  await tester.pumpAndSettle();

  expect(find.text('Invalid credentials'), findsOneWidget);
});
```

### Golden tests (5% of suite — Alchemist)

**Scope**: design system components, brand-critical screens, typography

**Rules**:
- Use `Alchemist` for consistent golden testing with device simulation
- Pin text scale factor to 1.0 for golden stability
- Run goldens on Linux CI (deterministic font rendering)
- Test multiple themes (light/dark) for each component
- Update goldens intentionally with explicit review process

```dart
goldenTest(
  'PrimaryButton renders correctly',
  fileName: 'primary_button',
  builder: () => GoldenTestGroup(
    children: [
      GoldenTestScenario(
        name: 'default',
        child: const PrimaryButton(label: 'Submit'),
      ),
      GoldenTestScenario(
        name: 'disabled',
        child: const PrimaryButton(label: 'Submit', enabled: false),
      ),
    ],
  ),
);
```

### E2E tests (5% of suite — Patrol)

**Scope**: critical user journeys only (auth, onboarding, checkout, core feature)

**Rules**:
- Use `Patrol` — handles native permissions, notifications, deep links
- Run on real devices or emulators in CI (not just desktop)
- Test permission grants/denials explicitly
- Test deep link entry points
- Test biometric authentication flows (where applicable)
- Keep E2E tests stable: use data factories, not hardcoded test accounts

```dart
patrolTest('User can log in and see home screen', ($) async {
  await $.pumpWidgetAndSettle(const MyApp());

  await $(#emailField).enterText('test@example.com');
  await $(#passwordField).enterText('password123');
  await $(#loginButton).tap();

  await $.pumpAndSettle();
  expect($(HomeScreen), findsOneWidget);
});
```

---

## Branching decision tree

### Branch A: deadline pressure

- **Deadline-critical** (< 2 weeks):
  - Prioritize high-risk integration and critical journey E2E tests
  - Defer visual golden coverage with explicit follow-up date
  - Ensure domain/use-case unit tests are complete

- **Stability-critical** (regression-sensitive release):
  - Increase failure-path and boundary integration depth
  - Tighten flaky-test budget (< 1% tolerance)
  - Add E2E for all critical journeys

### Branch B: architecture maturity

- **Legacy coupled** (flat structure, poor testability):
  - Add characterization tests before refactoring
  - Use integration tests at seams, not unit tests on coupled code

- **Modular and bounded** (feature-first):
  - Bias toward fast unit + boundary-focused widget tests
  - Layer isolation enables high unit test ROI

### Branch C: UI test strategy

- High UI churn → focus on behavior tests, avoid brittle golden overuse
- Design system stabilized → Alchemist goldens for all design tokens

---

## Quantitative gates

| Gate | Threshold | Label |
|---|---|---|
| Critical flow coverage | ≥ 80% of critical path behaviors | pass/at-risk/fail |
| Domain layer coverage | ≥ 90% line coverage | pass/at-risk/fail |
| Flaky rate | < 2% of total suite | pass/at-risk/fail |
| CI execution time | < 10min for full unit+widget suite | pass/at-risk/fail |
| E2E journey coverage | All critical journeys covered | pass/at-risk/fail |

---

## Anti-pattern detection

- Excessive E2E tests for risks coverable at unit layer
- Tests asserting implementation details (internals) over behavior/contracts
- Non-deterministic inputs (DateTime.now(), Random(), network calls)
- Missing failure-path coverage on high-impact journeys
- Goldens updated blindly without visual review
- Mocking everything (prefer Fakes for stateful collaborators)
- `sleep()` / `Future.delayed` in tests (use `fakeAsync` / `pumpAndSettle`)
- Missing `tearDown` / `container.dispose()` causing test pollution

---

## Uncertainty protocol

- `High` (≥ 0.80): architecture clear, journeys identified
- `Medium` (0.60–0.79): partial test coverage data
- `Low` (< 0.60): no coverage baseline, no journey mapping

---

## Cross-skill handoff payload

Use the standard payload from `../../AGENTS.md`.
Set `requesting_skill` to `flutter-testing`.

---

## Output contract

Follow global section order from `../../AGENTS.md`. Also include:

- `Test pyramid recommendation`
- `Test boundaries by layer`
- `What NOT to test`
- `Tooling setup (mocktail, Alchemist, Patrol)`
- `Flakiness risks and controls`
- `Coverage gate definition`

---

## Related resources

- `references/test-tooling-guide.md`
- `references/patrol-setup.md`
- `references/alchemist-setup.md`
- `references/fake-patterns.md`
- `templates/unit-test.dart`
- `templates/widget-test.dart`
- `templates/golden-test.dart`
- `templates/patrol-test.dart`
- `templates/test-strategy.md`
