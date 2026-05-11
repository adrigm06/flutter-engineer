# Glossary

Terms used throughout the `flutter-engineer` skill system.

---

## Core concepts

### Lead skill

The single domain skill that owns the primary decision for a given task.
Only one lead skill is active per task. It provides the primary recommendation.

**Selection**: Use the routing matrix in `SKILL.md` to select the lead skill based on the task domain.

---

### Supporting skill

A domain skill that contributes constraints or validation to the lead skill's recommendation,
without owning the final decision.

**Rule**: Include only skills whose constraints could materially change the lead skill's output.
Do not add supporting skills for completeness — add them only when their constraint is relevant.

---

### Decision domain

The primary dimension of a task that determines which skill leads.

Example decision domains:

| Task type | Decision domain |
|---|---|
| "How should I structure my modules?" | Architecture |
| "My app is janking during scroll" | Performance |
| "Should I release this build?" | Build & release |
| "Is this code secure?" | Security |

---

### Authority scope

The specific context in which a skill's decision overrides others.
Defined per skill in `AGENTS.md → Skill authority model`.

`flutter-security` has global critical override authority.
Other skills have scoped authority limited to their domain.

---

### Hard gate

A mandatory check that must complete before a final recommendation is given.

Format: explicit step sequence the agent must execute before responding.
If any step fails or yields insufficient evidence, the agent returns a measurement-first plan instead of a final answer.

---

### Gate status

The result of a quantitative gate check. Three possible values:

- `pass` — metric meets threshold; no action required
- `at-risk` — metric is within 10% of threshold; monitor closely
- `fail` — metric fails threshold; must be resolved before proceeding

---

### Confidence

A numeric estimate of how reliable a recommendation is given current evidence.

| Label | Range | Meaning |
|---|---|---|
| High | ≥ 0.80 | Evidence strong, constraints clear, assumptions minimal |
| Medium | 0.60–0.79 | Partial evidence or moderate assumptions present |
| Low | < 0.60 | Key data missing, conflict unresolved, assumptions dominate |

When confidence is Medium or Low:
- List assumptions explicitly
- Provide a fallback option
- Request minimum missing data

---

### Non-negotiable constraint

A rule that must never be violated under any circumstances.
Listed in `AGENTS.md → Non-negotiable constraints`.

Example: "No JWTs in SharedPreferences" is non-negotiable regardless of timeline, team size, or convenience.

---

### Measurement-first plan

A response returned when evidence is insufficient for a final recommendation.
Contains: what to measure, how to measure it, what thresholds to use, and what decision each measurement triggers.

Do not return a false-final recommendation. Return a measurement-first plan instead.

---

### Handoff payload

The structured data passed from one skill to another during cross-domain escalation.
Defined in `AGENTS.md → Cross-skill handoff contract`.

Required when: risk is High/Critical, supporting skill's constraint could block lead skill's recommendation.

---

### Project context

The sum of information about the app being worked on:
project type (Greenfield/Legacy/Enterprise/Startup), team size, target platforms, regulatory constraints, existing stack.

If no context is provided → apply the no-context fallback protocol from `assets/project-context-assessment.md`.

---

### Compact output block

The mandatory summary block included in all non-trivial responses:

```
Lead domain: <selected skill>
Supporting domains: <only materially relevant skills>
Mode: <Design | Review | Generation | Debug | Optimize | Release>
Top gates: <2-4 gates labeled pass | at-risk | fail>
Confidence: <High | Medium | Low + numeric estimate>
Minimum extra evidence: <smallest missing inputs that could change the decision>
```

---

### Full output contract

The detailed 8-section structure for comprehensive responses.
Defined in `AGENTS.md → Unified output contract`.

Use for: Design mode, Review mode, architecture proposals, multi-domain recommendations.
Use compact block for: Generation mode snippets, quick Debug/Optimize answers.

---

### Skill gap

An output annotation used when the lead or supporting skill referenced in the routing matrix
does not have an active SKILL.md file.

Format: `Skill gap: flutter-[domain] not available — reasoning from orchestrator directly.`
