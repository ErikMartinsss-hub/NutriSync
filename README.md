# NutriSync

Aplicativo de jejum intermitente com registro de calorias e exercicios.

Stack: Flutter 3.47 + Dart 3.13 · Arquitetura: Clean + Riverpod · Persistencia: Hive · Auth: Firebase Auth (email/senha + Google) · Notificacoes: flutter_local_notifications · Dados de alimentos: API TACO · Analytics/Crashlytics: Firebase · Feature flags: locais via Hive (hibernaveis remotamente)

---

## Como rodar

### Pre-requisitos
- Flutter 3.22+ (`flutter doctor` deve passar no Android toolchain)
- Android SDK 34+ / emulador ou device fisico
- `google-services.json` do Firebase (projeto `nutrisync-18da1`) em `android/app/` (nao versionado — fica no `.gitignore`, gere o seu no Firebase console)

### CI (GitHub Actions)
O workflow roda `analyze` + `test` e, se o secret `GOOGLE_SERVICES_JSON` estiver cadastrado no repo (base64 do arquivo `google-services.json`), tambem gera os APKs release split-per-abi como artefato. Sem o secret, o job de build e simplesmente pulado. Para configurar:
```bash
# local
base64 -w0 android/app/google-services.json   # imprime a string
```
Depois: Settings > Secrets > Actions > novo secret `GOOGLE_SERVICES_JSON` com o valor impresso.

### Rodar em debug
```bash
git clone https://github.com/ErikMartinsss-hub/NutriSync
cd NutriSync
flutter pub get
flutter run
```

### Build Android
```bash
flutter build apk --debug
flutter build apk --release --target-platform android-arm64   # APK release
flutter build appbundle --release --target-platform android-arm64   # AAB para Play Store
```
Saida: `build/app/outputs/flutter-apk/app-release.apk` e `build/app/outputs/bundle/release/app-release.aab`

### Assinatura para Play Store
- Gere o keystore uma vez e nunca committe: `android/app/upload-keystore.jks` (local) + `android/key.properties` (senha). Ambos estao no `.gitignore`.
- Com o `android/key.properties` presente, todo build release assina com essa chave (`alias upload`). Sem o arquivo (ex.: CI), o build cai no debug signing automaticamente.
- Backups recomendados: `Desktop/NUTRISYNC/upload-keystore.jks` e `key.properties`.
- Play App Signing: ao subir o primeiro AAB, o Play Console cuida. Apos isso, registre o certificado de assinatura do Play no Firebase (Google Sign-In usa SHA-1).

Nota sobre o build release nesta maquina: o AOT snapshotter do Flutter crasha ao compilar a ABI 32-bit (limitacao de memoria no Windows). O build com `--target-platform android-arm64` gera um APK/AAB funcional para a grande maioria dos celulares Android atuais (64-bit).

### Testes
```bash
flutter test
```

---

## Arquitetura

Clean Architecture simplificada com Riverpod (StateNotifier/StateNotifierProvider).

```
lib/
├── core/
│   ├── theme/app_theme.dart          # ThemeData light/dark (Material 3)
│   └── services/
│       ├── notification_service.dart # Wrapper flutter_local_notifications + timezone
│       └── storage_service.dart      # Wrapper Hive
├── design/
│   └── tokens.dart                   # Design System (cores, raio, sombras, textos)
├── widgets/                          # Cards reutilizaveis (calorie, macros, diary, exercise, weight)
├── features/
│   ├── auth/
│   │   └── presentation/auth_provider.dart   # Firebase Auth + Google + fallback SharedPreferences
│   ├── fasting/
│   │   ├── data/
│   │   │   ├── fasting_protocol.dart          # 12:12, 16:8, 18:6 + custom
│   │   │   ├── fasting_session.dart           # Modelo com elapsed/remaining/progress
│   │   │   └── fasting_repository.dart        # Hive por usuario
│   │   └── presentation/fasting_provider.dart # Ticker + pause/resume/background
│   ├── meals/
│   │   ├── data/
│   │   │   ├── meal.dart                      # Modelo (name, calories, dateKey, mealType)
│   │   │   ├── meal_repository.dart           # Hive por usuario
│   │   │   └── taco_service.dart              # API TACO + cache + fallback offline
│   │   └── presentation/meal_provider.dart
│   ├── profile/
│   │   ├── data/user_profile.dart, profile_repository.dart
│   │   └── presentation/profile_provider.dart
│   ├── exercise/
│   │   ├── data/exercise_entry.dart, exercise_repository.dart
│   │   └── presentation/exercise_provider.dart
│   └── history/presentation/history_page.dart
├── screens/                          # TodayScreen (home), Login, Register, Nutrition, FastingHistory, AddMeal, ExerciseLog, Onboarding
├── app.dart                          # MaterialApp + roteamento por auth state
└── main.dart                         # Firebase + Hive + Notifications init + ProviderScope
```

### Por que essas escolhas

- **Riverpod** em vez de Bloc: menos boilerplate, testavel, sem streams complexos, providers que se recriam automaticamente quando o estado de autenticacao muda.
- **Hive CE** em vez de SQLite/Drift: mais leve, 100% offline-first e sincrono; agregacao por `dateKey` com `getAll + filter` e suficiente para o volume de um MVP (menos de 10 mil registros).
- **Firebase Auth** (email/senha + Google Sign-In) para autenticacao real, com fallback local via SharedPreferences para uso off-line. A sessao fica persistida pelo `authStateChanges`.
- **Dados por usuario**: todas as chaves do Hive sao prefixadas com o `userId` (UID do Firebase ou email), e os providers sao `autoDispose`. Trocar de conta nunca vaza refeicoes, exercicios ou peso de outro usuario.
- **StateNotifier com calculo por timestamp absoluto** (`startTimeMs`) garante a robustez do timer.

---

## Timer — por que não quebra em background

Essa é a parte mais importante do desafio: um timer frágil reprovaria o teste. A ideia é simples — **o app não confia no objeto `Timer`**. Tratei o Hive como a fonte da verdade:

1. Ao **iniciar** o jejum, gravo `startTimeMs` (epoch time) no Hive.
2. O tempo decorrido é sempre recalculado (`elapsedSeconds(now) = now - startTimeMs`). Se o app for fechado e reaberto — ou voltar do background — o `FastingNotifier` lê o valor do Hive e o progresso já está correto.
3. Ao **pausar**, salvo `elapsedSecondsOnPause` e `status = paused`, e cancelo a notificação agendada. Ao **retomar**, recalculo `newStart = now - elapsedOnPause` e reagendo a notificação com o tempo restante.
4. O `Timer.periodic(1s)` existe só para atualizar o relógio na tela e detectar a conclusão, movendo o jejum para o histórico automaticamente.
5. **Notificações**: `showInstant` ao iniciar/encerrar e `zonedSchedule` para o término (`exactAllowWhileIdle`, toca até em modo Doze). Pausar ou cancelar cancela a notificação.

```dart
// elapsed real — sobrevive ao kill do processo
int elapsedSeconds(DateTime now) {
  if (status == paused) return elapsedSecondsOnPause;
  return (now.millisecondsSinceEpoch - startTimeMs) / 1000;
}
```

Como o Hive é a fonte da verdade, o estado nunca regride.

---

## Notificacoes

- `flutter_local_notifications` + `timezone`
- Canal `mamba_fast` (Android O+)
- Permissao `POST_NOTIFICATIONS` solicitada no init
- Agendamento `exactAllowWhileIdle` para tocar mesmo em Doze
- Fallback: se `SCHEDULE_EXACT_ALARM` for negado, ainda mostra `showInstant`

Permissoes no `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
```

---

## Refeicoes e calculo diario

- **Modelo** `Meal {id, name, calories, timestampMs, dateKey, mealType}` — `mealType`: cafe/almoco/jantar/lanche; `dateKey = yyyy-MM-dd` para agregacao.
- **Busca TACO** (`TacoService`): consulta a API `https://mamba-taco-api.onrender.com/api/alimentos/ibge`, que possui 1.971 alimentos. Tem cache de 10 minutos e fallback com lista mock quando off-line. O calculo de kcal pode ser por gramas ou por unidades.
- **TACO API** foi feita como deploy proprio (Render + Docker): Laravel + SQLite com a tabela TACO/IBGE. Repo: https://github.com/ErikMartinsss-hub/mamba-taco-api
- **Editar e excluir**: acontecem direto no diario do dia ou na tela AddMealScreen.
- **Meta diaria personalizada**: calculada do perfil com a formula Mifflin-St Jeor vezes fator de atividade, ajustada para a meta de perder ou ganhar peso.
- **Exercicio aumenta a cota**: as kcal queimadas (+MET) entram no orcamento — `disponivel = meta + queimadas`. O card mostra `Exercicio: +X kcal` e o total economizado no dia.

---

## Peso e exercicio

- **Onboarding (4 passos)**: sexo, idade, altura, peso atual, meta e nivel de atividade, salvos no Hive.
- **Peso**: card com progresso em direcao a meta, atualizado por bottom sheet.
- **Exercicio**: registro com tipo (cardio/musculacao/mobilidade), intensidade e duracao — `kcal = MET x peso(kg) x horas`. Aparece no dia e pode ser removido.

---

## Historico e grafico

- **Historico**: agrupado por `dateKey` descendente, com `ExpansionTile` por dia mostrando jejuns e refeicoes.
- **Fasting History**: filtros (Hoje/7d/30d/Todos), estatisticas e grafico de barras da evolucao do jejum.
- **Nutricao**: abas Calorias / Nutrientes / Macros com grafico de rosca (fl_chart) e tabela de nutrientes.

---

## Persistencia local e multiusuario

- **Hive** box `mamba_box` (jejum, refeicoes, perfil, exercicios e protocolo).
- Chaves por usuario: `meals_list_<userId>`, `exercises_<userId>`, `profile_<userId>`, `fasting_*_<userId>`.
- **Auth**: Firebase (UID) ou fallback SharedPreferences (`isLoggedIn`, `email`). O `userId` usado nas chaves e o UID ou o email logado.
- 100% offline-first: sem Firebase o app continua funcionando no modo demo local.

---

## UI e UX

- Design System proprio em `design/tokens.dart` (fundo `#F5F6FA`, primaria `#0066FF`, macros com cor propria).
- Material 3, cards com raio 16dp, gradiente laranja/verde no login e cadastro.
- Timer com `CircularProgressIndicator`, `HH:MM:SS` decorrido/restante e percentual.
- Chips para os protocolos, desabilitados durante jejum ativo.
- Navegacao: TodayScreen com FloatingActionButton para adicionar refeicao e BottomNavigationBar (Hoje/Nutricao/Jejum/Mais).
- Dark mode: toggle Claro/Escuro/Sistema no topo da barra de titulo + seletor completo no menu "Mais", com preferencia persistida em Hive.

---

## Bibliotecas

| Lib | Uso |
|-----|-----|
| `flutter_riverpod` | Estado (StateNotifier/Provider) |
| `hive_ce` + `hive_flutter` | Persistencia local |
| `firebase_core`, `firebase_auth`, `google_sign_in` | Autenticacao |
| `firebase_analytics`, `firebase_crashlytics` | Analytics, crash reports |
| `shared_preferences` | Sessao (fallback demo) |
| `flutter_local_notifications` + `timezone` | Notificacoes agendadas |
| `fl_chart` | Graficos (rosca/barras) |
| `intl` | Formatacao de data/hora + pt_BR |
| `uuid` | IDs |
| `http` | Cliente da API TACO |

Icone do app gerado com `flutter_launcher_icons` a partir de `assets/icon_foreground.png` (adaptive icon).

---

## Trade-offs e decisoes

- **Firebase Auth com fallback local**: autenticacao real com Google Sign-In; se o aparelho estiver offline, o login demo via SharedPreferences evita travar o app. Em contra partida, nao ha recuperacao de senha no modo demo — aceitavel para o desafio.
- **Hive em vez de Isar/Drift**: nivel de estabilidade alto no Windows e sem toolchain extra; as queries simples por `dateKey` cobrem o MVP.
- **Timestamp absoluto + zonedSchedule**: sem foreground service (seria over-engineering para 3-4 dias); o timer continua correto mesmo com o processo encerrado pelo sistema.
- **Build release arm64**: contorno para o crash do AOT snapshotter na ABI 32-bit no Windows. Equivale ao `--split-per-abi` de uma ABI. Para distribuicao ampla, o AAB da Play Store compila por dispositivo e nao tem esse problema.
- **Sem testes de widget/E2E**: a cobertura unitaria foca no core (timer e repositorios). Com mais tempo, o proximo passo e `integration_test` para o fluxo iniciar, pausar, encerrar e reabrir.

---

## O que melhoraria com mais tempo

- Firebase Remote Config como fonte centralizada das feature flags
- Edicao retroativa de jejum (corrigir data de inicio e fim)
- Sincronizacao em nuvem (Firestore) com merge offline para online
- Exportacao CSV e graficos mensais
- Biometria para login
- Testes de widget/golden e `integration_test`
- Publicacao na Play Store (internal test / open beta)

---

## Tempo gasto

Cerca de 12 horas distribuídas: scaffold, arquitetura, timer robusto, Firebase Auth, API TACO, refeicoes/peso/exercicio, historico/grafico, UI/design system, README, testes e build.

---

## Entregaveis

- Repo: https://github.com/ErikMartinsss-hub/NutriSync
- TACO API: https://github.com/ErikMartinsss-hub/mamba-taco-api (deploy: https://mamba-taco-api.onrender.com)
- APK: `build/app/outputs/flutter-apk/app-release.apk`


