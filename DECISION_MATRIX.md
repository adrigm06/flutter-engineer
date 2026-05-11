# Flutter Engineering Decision Matrix

This matrix enables context-aware, tradeoff-driven decisions.
Do NOT use this as a rigid prescriptive list — always reason about context first.

---

## 1. Architecture Decision Matrix

| Dimension | Clean Architecture | Vertical Slice | Modular Monolith | Package-First |
|---|---|---|---|---|
| Team size | 5+ engineers | 1–4 engineers | 3–8 engineers | 5+ engineers, multi-app |
| Domain complexity | High | Low–Medium | Medium | Medium–High |
| Setup cost | High | Low | Medium | High |
| Testability | Very High | Medium | High | Very High |
| Scalability | Very High | Low | High | Very High |
| Migration cost | High | Low | Medium | Very High |
| Best for | Enterprise SaaS | MVP, internal tools | Growth-stage | Monorepo, platform teams |

**Decision triggers:**
- > 3 feature teams → Package-First mandatory
- Regulated data (PCI, HIPAA) → Clean Architecture minimum
- < 3 months to ship → Vertical Slice with documented upgrade path
- Multiple apps sharing code → Package-First

---

## 2. State Management Decision Matrix

| Solution | Compile-time safety | Testability | Boilerplate | Rebuilds control | Learning curve | Use case |
|---|---|---|---|---|---|---|
| Riverpod 3 | ✅ Excellent | ✅ Excellent | Low | ✅ Granular (select) | Medium | Default for everything |
| flutter_bloc | ✅ Good | ✅ Excellent | Medium–High | ✅ Good | High | Event-driven, enterprise |
| Signals | ✅ Good | ⚠️ Medium | Very Low | ✅ Excellent | Low | High-frequency UI |
| flutter_hooks | ✅ Good | ⚠️ Medium | Very Low | ⚠️ Limited | Medium | Ephemeral local state |
| Provider | ⚠️ Partial | ✅ Good | Medium | ⚠️ Limited | Low | Legacy only (migrate to Riverpod) |
| GetX | ❌ None | ❌ Poor | Very Low | ❌ Poor | Very Low | **PROHIBITED** |

---

## 3. Persistence Decision Matrix

| Use case | Solution | Notes |
|---|---|---|
| Simple key-value preferences | shared_preferences | Never for sensitive data |
| Tokens, credentials, keys | flutter_secure_storage | Keychain/Keystore backed |
| Relational offline-first data | Drift (SQLite) | Type-safe, migration support |
| Document/JSON heavy data | Isar (community) | Fast, no migrations needed |
| High-perf key-value store | Hive CE | Lightweight, no SQL |
| Encrypted relational | Drift + SQLCipher | Regulated data |
| File storage | path_provider + dart:io | Media, documents |
| Remote cache | Dio cache interceptor | HTTP-level caching |

---

## 4. Navigation Decision Matrix

| Need | Solution | Notes |
|---|---|---|
| Standard app navigation | go_router | Universal choice |
| Deep links (mobile) | go_router | Native deep link support |
| Web URL routing | go_router | URL-based routing |
| Auth guards | go_router redirect | Per-route or global |
| Nested navigation | go_router ShellRoute | Persistent UI shells |
| Bottom nav persistence | ShellRoute | Keeps subtrees alive |
| Modal flows | go_router push + pop | Returns typed result |
| Dynamic route generation | onGenerateRoute override | For plugin/dynamic routes |

---

## 5. Networking Decision Matrix

| Need | Solution | Notes |
|---|---|---|
| HTTP client | Dio | Interceptors, cancellation, retry |
| REST caching | dio_cache_interceptor | ETag, stale-while-revalidate |
| GraphQL | ferry or artemis | Type-safe schema |
| WebSockets | web_socket_channel | Realtime bidirectional |
| Server-Sent Events | dart:async Stream + Dio | Streaming responses |
| Offline sync | repository layer + Drift | Custom sync engine |
| Auth token refresh | Dio interceptor | Transparent refresh |
| SSL pinning | SecurityContext + Dio | Financial/health apps |

---

## 6. Testing Strategy Decision Matrix

| Test type | When mandatory | Tool | Speed | Cost |
|---|---|---|---|---|
| Unit (domain/app layer) | Always | flutter_test + mocktail | Fast | Low |
| Unit (data layer) | Always | flutter_test + mocktail | Fast | Low |
| Widget (screens) | All production screens | flutter_test | Medium | Medium |
| Widget (design system) | All reusable components | flutter_test | Medium | Medium |
| Golden (pixel-perfect) | Design system, brand-critical UI | Alchemist | Medium | Medium |
| E2E (critical journeys) | Auth, payment, onboarding | Patrol | Slow | High |
| Performance | Critical paths, release gates | flutter_driver | Slow | High |

**Test pyramid target:**
```
Unit: 70%
Widget: 20%
Golden: 5%
E2E: 5%
```

---

## 7. Rendering Optimization Decision Matrix

| Symptom | Root Cause | Solution |
|---|---|---|
| Jank on scroll | Heavy widget rebuild | RepaintBoundary + ListView.builder |
| Shader compilation jank | First-frame shader cache miss | SkSL warmup / Impeller (eliminates) |
| Slow first frame | Heavy main() initialization | Deferred initialization + splash screen |
| Memory bloat | Image cache growth | ImageCache.maximumSizeBytes limit |
| Excessive rebuilds | Over-broad provider listen | select() / Consumer wrapping |
| Raster thread overload | Complex layer tree | Reduce layers, use const widgets |
| Texture jank | Large image decode on UI thread | ResizeImage + Isolate.run() decode |

---

## 8. Build/Release Decision Matrix

| Question | Options | When to choose |
|---|---|---|
| Flavor strategy | dev/staging/prod flavors | Always for multi-environment apps |
| Obfuscation | --obfuscate + --split-debug-info | Always for release builds |
| CI platform | GitHub Actions | Default |
| Distribution | Firebase App Distribution | Internal testing |
| Store submission | Fastlane | Automated, reproducible |
| App size | Deferred components + --tree-shake | > 50MB base APK |

---

## 9. Observability Decision Matrix

| Signal type | When needed | Tool |
|---|---|---|
| Crash reporting | Always | Firebase Crashlytics |
| Non-fatal errors | Always | Crashlytics.recordError |
| Performance traces | Always | Firebase Performance |
| Custom traces | For critical user journeys | Firebase Performance custom traces |
| Analytics | When business requires it | Firebase Analytics |
| Structured logging | Always | `logging` + remote sink |
| Feature flags | Rollouts, A/B tests | Firebase Remote Config |
| Distributed tracing | Microservices integration | OpenTelemetry Dart |

---

## 10. AI Integration Decision Matrix

| Capability | Solution | Notes |
|---|---|---|
| LLM streaming chat UI | StreamBuilder + chunked response | Token-by-token rendering |
| Structured outputs | JSON schema validation | Schema-bound responses |
| Tool/function calling | Custom orchestration layer | State machine for tool calls |
| Edge inference | tflite_flutter + ONNX | On-device model inference |
| Local embeddings | on_device_ml packages | Privacy-safe similarity search |
| AI response caching | Semantic cache layer | Avoid duplicate LLM calls |
| Token budgeting | Count before request | Truncate + summarize context |
| Prompt versioning | Remote Config or hardcoded version constants | Track which prompt produced output |

---

## 11. Offline-First Decision Matrix

| Question | Option A | Option B | Choose when |
|---|---|---|---|
| Sync strategy | Event sourcing | State mirroring | A: audit trail needed; B: simple |
| Conflict resolution | Last-write-wins | Manual merge | A: simple; B: collaborative |
| Sync timing | Background + foreground | On-demand only | A: default; B: battery-critical |
| Queue | Retry queue (Drift table) | WorkManager | A: Dart-only; B: guaranteed delivery |
| CRDT | yes (automerge-dart) | no | yes: collaborative docs |

---

## 12. Security Controls Decision Matrix

| Asset | Threat | Control | Enforcement |
|---|---|---|---|
| Auth tokens | Theft from storage | flutter_secure_storage | Non-negotiable |
| API keys | Leakage in binary | Build-time injection (CI) | Non-negotiable |
| User PII | Data breach | Encrypted storage + secure transit | Non-negotiable |
| Payment data | Interception | Certificate pinning + encrypted channel | Required |
| App integrity | Tampering/repackaging | Root detection + Play Integrity | High-security apps |
| Debug symbols | Reverse engineering | split-debug-info on release | Non-negotiable |
| Log data | PII exposure | Sanitize before logging | Non-negotiable |
