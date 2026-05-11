# Flutter Engineering — Domain Skill Contracts

This file contains **technical sub-contracts** used exclusively by domain skills (`skills/*/SKILL.md`).

**Orchestration logic, routing, authority model, and output format live in `SKILL.md`.**
Domain skills read this file for: handoff payloads, quantitative gates, mode output schemas, and communication style.

---

## Flutter dependency direction rules

Allowed:

```
feature/* → domain
feature/* → core/*
data/*    → domain (implements contracts)
app       → feature/*
platform  → core/platform-interface
```

Forbidden:

```
feature-a → feature-b (direct — any form)
domain    → data
domain    → Flutter framework types
core      → feature
```

---

## Cross-skill handoff payload

When one skill escalates to another, include this payload:

```
decision_domain:          <what decision is being delegated>
requesting_skill:         <source skill name>
target_skill:             <supporting skill name>
risk_class:               Critical | High | Medium | Low
confidence:               High | Medium | Low (<numeric>)
assumptions:              <assumptions that shaped current recommendation>
hard_constraints_checked: <non-negotiable constraints already validated>
quantitative_gates:       <measured metrics and status vs thresholds>
blocking_conflicts:       <unresolved conflicts requiring arbitration>
preferred_path:           <currently recommended path>
fallback_path:            <lower-risk fallback if preferred path fails>
minimum_extra_evidence:   <minimum additional data required to finalize>
```

**Include the full payload when ANY of the following is true:**
- Supporting skill's constraint could block the lead skill's recommendation
- `risk_class` is `High` or `Critical`
- Supporting skill must validate a gate before the final answer
- Confidence is `Medium` or `Low` and cross-domain data would change the decision

When in doubt: include the payload. Omitting it when impacts are real is the failure mode.

---

## Quantitative gates

Label every gate as `pass`, `at-risk`, or `fail`.
Prefer relative gates (regression budgets) plus absolute safety floors.
If no metrics exist → return Measurement-First Plan before irreversible recommendations.

| Gate | Threshold | Type |
|---|---|---|
| Frame budget | 16ms (60fps) / 8.3ms (120fps) | Absolute |
| Cold startup | < 2s on mid-range Android | Absolute |
| Memory RSS | < 10% regression vs baseline | Relative |
| Crash-free rate | ≥ 99.5% | Absolute |
| Test coverage (critical flows) | ≥ 80% line coverage | Absolute |
| Flaky test rate | < 2% of suite | Absolute |
| CI build time | < 20% regression vs baseline | Relative |
| APK/IPA size | < 5% regression vs baseline | Relative |

---

## Confidence levels

| Label | Range | Meaning |
|---|---|---|
| High | ≥ 0.80 | Evidence strong, constraints clear, assumptions minimal |
| Medium | 0.60–0.79 | Partial evidence or moderate assumptions |
| Low | < 0.60 | Key data missing or conflict unresolved |

When confidence is Medium or Low:
- List assumptions explicitly
- Request minimum missing data that changes the decision
- Provide at least one fallback option
- Escalate to additional skills when cross-domain uncertainty is material

---

## Review severity rubric

Used by `flutter-code-review` and any skill producing review findings:

| Severity | Trigger |
|---|---|
| **Critical** | Security exposure, data loss, architecture breakage, release blocker, exploitability |
| **High** | High-risk maintainability/performance/correctness issue — likely to cause production incidents |
| **Medium** | Important improvement with moderate risk or cost impact |
| **Low** | Minor issue with limited operational impact |

---

## Mode output schemas (domain skill reference)

### Design
Return: recommended design · alternatives · decision triggers · migration path · ADR draft.
Structure: 8-section output contract (from `SKILL.md`).

### Review
Return: findings grouped by severity · concrete fix steps · risk impact · verification method.

### Generation
Return: scaffold aligned with constraints · rollback-safe sequencing · dependency order.
Compact output block is sufficient unless cross-domain reasoning is required.

### Debug
Return: hypotheses ranked by probability · reproduction strategy · instrumentation plan · confidence update per step.

### Optimize
Return: bottleneck diagnosis · measurement-first plan · interventions by impact/cost ratio · regression gates.

### Release
Return: go/no-go assessment · gate status table · rollback triggers · staged rollout plan.

---

## Communication style

- Be concise and direct
- Explain **why**, not only what
- Use "prefer" and "consider" for context-dependent decisions
- Use "must" and "never" only for non-negotiable constraints
- Surface assumptions when context is missing
- Prefer deterministic rules over vague best-practice statements
