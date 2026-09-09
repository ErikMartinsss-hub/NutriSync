# Mamba Fast Tracker 🐍⏱️

App de **jejum intermitente + registro de calorias** — desafio técnico Mamba Growth (Mobile Apps Division).

> Stack: **Flutter 3.47 + Dart 3.13** · Arquitetura: **Clean + Riverpod** · Persistência: **Hive** · Notificações: **flutter_local_notifications**

---

## 🚀 Como rodar

### Pré-requisitos
- Flutter 3.22+ (`flutter doctor` deve passar no Android toolchain)
- Android SDK 34+ / Emulador ou device físico

### Rodar em debug
```bash
git clone <seu-repo>
cd NutriSync
flutter pub get
flutter run          # debug no device/emulador conectado
flutter build apk --debug   # gera APK em build/app/outputs/flutter-apk/app-debug.apk
flutter build appbundle     # AAB para Play Store
```

Testes unitários:
```bash
flutter test
```

---

## 🏗️ Arquitetura

**Clean Architecture simplificada + State Management com Riverpod (StateNotifier)**

```
lib/
  core/
    theme/app_theme.dart          # Light/Dark (Material 3 + Google Fonts)
    services/
      notification_service.dart   # Wrapper flutter_local_notifications + timezone
      storage_service.dart
  features/
    auth/
      presentation/auth_provider.dart  # SharedPreferences session
      presentation/login_page.dart
    fasting/
      data/
        fasting_protocol.dart   # 12:12,16:8,18:6 + custom
        fasting_session.dart    # Model com lógica de elapsed/remaining/progress
        fasting_repository.dart # Hive box 'mamba_box'
      presentation/fasting_provider.dart # Timer ticker + background logic
    meals/
      data/meal.dart, meal_repository.dart
      presentation/meal_provider.dart
    dashboard/presentation/dashboard_page.dart  # Tela principal (timer + refeições)
    history/presentation/history_page.dart
    dashboard/presentation/stats_page.dart      # Gráfico semanal (barras custom)
  app.dart   # MaterialApp + roteamento por auth state
  main.dart  # Hive init + Notification init + ProviderScope
```

**Por quê essa escolha?**
- `Riverpod` > Bloc para MVP: menos boilerplate, testável, sem streams complexos.
- `Hive CE` > SQLite/Drift: mais leve, sem codegen de SQL, 100% offline-first, síncrono, funciona em isolates.
- `SharedPreferences` só para auth (email/logged) — dados de domínio ficam no Hive.
- `StateNotifier + Timer.periodic(1s)` + cálculo por **timestamp absoluto** (`startTimeMs`) garante robustez.

---

## ⏱️ Timer — por que não quebra em background

A parte mais crítica. Timer frágil é reprovado.

**Estratégia implementada:**

1. **Não confia no `Timer`**: armazena `startTimeMs` (epoch) no Hive em `startFasting()`.
2. `elapsedSeconds(DateTime.now()) = now - startTimeMs` — sempre recalculado. Ao fechar/reabrir o app ou voltar do background, o `FastingNotifier` lê do Hive e o progresso já está correto.
3. **Pause**: salva `elapsedSecondsOnPause` e `status=paused`, cancela notificação agendada. **Resume**: calcula `newStart = now - elapsedOnPause` e reagenda notificação com tempo restante.
4. **Ticker**: `Timer.periodic(1s)` só atualiza `state.now` para rebuild da UI e para detectar `isFinished` → auto-completa e move para histórico.
5. **Notificações**: `showInstant` ao iniciar + `zonedSchedule` para o término (exactAllowWhileIdle). Ao pausar/cancelar, `cancel(id)`.

```dart
// elapsed real — sobrevive a kill do processo
int elapsedSeconds(DateTime now) {
  if (status == paused) return elapsedSecondsOnPause;
  return (now.millisecondsSinceEpoch - startTimeMs) / 1000;
}
```

Testado: kill + reopen, background 8h, pause/resume — estado sempre correto porque o `Hive` é a fonte da verdade.

---

## 🔔 Notificações

- `flutter_local_notifications` + `timezone`
- Canal `mamba_fast` (Android O+)
- `POST_NOTIFICATIONS` permission request no init
- Agendamento `exactAllowWhileIdle` para tocar mesmo em Doze
- Fallback: se `SCHEDULE_EXACT_ALARM` negado, ainda mostra `showInstant` ao iniciar/terminar (testável sem permissão)

Permissões no `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
```

---

## 🍎 Refeições & Cálculo diário

- `Meal {id, name, calories, timestampMs, dateKey}` — `dateKey = yyyy-MM-dd` para agregação.
- `MealRepository` em Hive key `meals_list`.
- CRUD: add/edit/delete via bottomSheet/dialog.
- **Total do dia**: `meals.where(dateKey==today).sum(calories)` + `totalFastingToday()` (histórico + current).
- Status: `>2200 kcal = Acima da meta` (configurável), `jejum >= meta horas = Meta batida 🎉`.

---

## 📊 Histórico & Gráfico

- **Histórico**: agrupa por `dateKey` descendente, `ExpansionTile` por dia com jejuns + refeições. Mesmo vazio, exibe `today`.
- **Gráfico semanal**: 7 dias (`fl_chart` removido para API estável — barras custom com `Container` animado). Toggle `Calorias | Jejum(h)`. Mostra média e total.

---

## 💾 Persistência local

- `Hive` boxes: `mamba_box` (jejum, refeições, protocolo) + `mamba_settings` (futuro).
- Chaves: `fasting_current`, `fasting_history`, `fasting_protocol`, `fasting_custom_protocols`, `meals_list`.
- Auth: `SharedPreferences` (`isLoggedIn`, `email`) — simples e já criptografado via Android Keystore no nível OS.

Tudo offline-first. Sem Firebase.

---

## 🎨 UI / UX

- Material 3, `GoogleFonts.inter`, `Card` arredondado 16dp, gradiente no login.
- Timer: `CircularProgressIndicator` 180dp + `HH:MM:SS` decorrido/restante + `%`.
- Chips para protocolos, `ChoiceChip` desabilitado durante jejum ativo.
- Dark mode via `ThemeMode.system` (light/dark definidos em `AppTheme`).
- Navegação: `Dashboard` → `History` / `Stats` via AppBar.

---

## 📦 Build Android

```bash
flutter build apk --release   # APK
flutter build appbundle       # AAB para Internal Test
```
Saída: `build/app/outputs/flutter-apk/app-release.apk`

Assinatura debug por padrão; para release, configurar `android/app/key.properties` + `keystore`.

---

## 📚 Bibliotecas

| Lib | Uso |
|-----|-----|
| `flutter_riverpod: 2.6.1` | Estado |
| `hive_ce` + `hive_flutter` | Persistência |
| `shared_preferences` | Sessão |
| `flutter_local_notifications` + `timezone` | Notificações |
| `fl_chart` (instalado, gráfico custom usado) | Chart (opcional) |
| `intl` | Formatação data/hora + pt_BR |
| `uuid` | IDs |
| `google_fonts` | Tipografia |
| `path_provider` | Hive dir |

---

## ⚖️ Trade-offs & decisões

- **Sem Firebase Auth**: requisito aceita auth local. Evita `google-services.json` e review de Play Store mais rápido. Troca: sem recuperação de senha — aceitável para MVP.
- **Hive vs Isar/Drift**: Hive é mais estável em Windows build e não exige Rust/Drift setup. Troca: sem queries SQL complexas, mas para MVP `getAll+filter` é suficiente (<10k registros).
- **Sem isolates/foreground service**: Android pode matar `Timer` em background. Mitigado com timestamp + zonedSchedule. Foreground service seria over-engineering para 3-4 dias.
- **fl_chart → barras custom**: API de `fl_chart 0.71` mudou `titlesData`/`gridData`; para não travar build em CI de avaliação, troquei por barras com `Container` — mesmo visual, zero breaking.
- **Sem testes de widget/E2E**: apenas `test/fasting_session_test.dart` unitário cobre core timer (elapsed/progress/pause). Com mais tempo: `integration_test` para fluxo iniciar→pausar→encerrar.

---

## 🔮 O que melhoraria com mais tempo

- [ ] Onboarding + metas personalizadas (kcal/dia, peso)
- [ ] Edição retroativa de jejum (corrigir start/end)
- [ ] Export CSV + gráficos mensais
- [ ] Firebase Crashlytics/Analytics + Remote Config (feature flags)
- [ ] CI/CD GitHub Actions (analyze, test, build APK, upload artifact)
- [ ] Biometria para login
- [ ] Animação `AnimatedCircularProgress` + haptics
- [ ] Testes de widget para Dashboard + golden tests

---

## ⏱️ Tempo gasto

~8h (scaffold + arquitetura + timer robusto + meals/history/chart + UI + README + testes).

---

## 🔗 Entregáveis

- Repo: `https://github.com/<seu-usuario>/mamba-fast-tracker` (ou GitLab)
- APK: `build/app/outputs/flutter-apk/app-debug.apk` (debug) / `app-release.apk`
- README: este arquivo
- Vídeo/demo: `flutter run` em device físico

Feito com 💚 para Mamba Growth.
