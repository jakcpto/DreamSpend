# План: Flutter-порт DreamSpend (X2 Financial Game)

## Контекст

Flutter-версия (`X2FinancialGameFlutter`) содержит корректную игровую механику (удвоение лимита, стрики, достижения, мультивалютность), но это MVP-скелет (~1 000 строк). Swift-оригинал — полноценный продукт с богатым UI, анимациями и интеграциями. Задача: довести Flutter-версию до полного паритета с оригиналом для iOS и Android, включая планшеты.

## Критические файлы для изменения

| Файл | Изменения |
|------|-----------|
| `lib/models/game_models.dart` | Добавить `SpendItem.id/isDemo`, `DayStatus.open` (миграция `pending`→`open`), `CategoryPalette`, computed поля `DayEntry` |
| `lib/state/game_store.dart` | +10 полей/методов: drafts, категории, `showCelebration`, `isPausedAfterMaximum`, `onboardingShown`, midnight-watcher |
| `lib/services/persistence_service.dart` | Новые ключи, try/catch |
| `lib/screens/today_screen.dart` | Полный переписать: календарная сетка + панель деталей, адаптив |
| `lib/screens/day_spends_screen.dart` | Автосохранение (3 с debounce), chips категорий, режим редактирования, `dayIndex` параметр |
| `lib/screens/settings_screen.dart` | Полный переписать: лимиты, FX, нотификации, onboarding replay, danger zone |
| `lib/screens/home_screen.dart` | `NavigationRail` на планшете / `BottomNavigationBar` на телефоне |
| `lib/l10n/app_strings.dart` | ~40 новых строк × 3 языка |
| `pubspec.yaml` | +4 зависимости |
| `android/app/src/main/AndroidManifest.xml` | Права уведомлений + ресивер |

## Новые файлы

```
lib/navigation/app_router.dart          — go_router + ShellRoute
lib/theme/app_theme.dart                — цветовая схема, карточки, типографика
lib/widgets/panel_card.dart             — glassmorphism-карточка (обе платформы)
lib/widgets/empty_state_view.dart       — иконка + текст для пустых состояний
lib/widgets/error_banner.dart           — ошибки персистентности
lib/widgets/category_chip.dart          — таб категории (tap=выбор, double-tap=редактирование)
lib/widgets/calendar/day_tile.dart      — тайл дня (92×92, liquid fill, жесты)
lib/widgets/calendar/liquid_fill_painter.dart  — CustomPainter: волна + пузыри
lib/widgets/calendar/calendar_grid.dart — сетка месяцев, scroll to last
lib/widgets/day_detail_panel.dart       — панель деталей (потрачено/остаток/статус + список)
lib/screens/onboarding_screen.dart      — 3-слайд PageView, glassmorphism
lib/screens/celebration_screen.dart     — конфетти, трофей, кнопка Restart
lib/services/fx_service.dart            — HTTP-запрос к frankfurter.app
lib/services/notification_service.dart  — flutter_local_notifications, tz
test/persistence_service_test.dart
test/widgets/day_tile_test.dart
```

---

## Фазы реализации

### Фаза 1 — Фундамент (модели, стор, зависимости)

**pubspec.yaml** добавить:
```yaml
go_router: ^14.0.0
flutter_local_notifications: ^18.0.0
timezone: ^0.9.4
http: ^1.2.0
confetti: ^0.7.0
uuid: ^4.4.0
```

**`game_models.dart`:**
- `SpendItem`: добавить `id` (UUID), `isDemo` (bool)
- `DayStatus`: переименовать `pending` → `open`; `fromJson` обрабатывает оба значения
- `DayEntry`: добавить `int get remainingMinor`, `int get allowedTotalMinor` (limit × 1.05)
- Новый класс `CategoryPalette` — 12 цветовых токенов (`blue/green/orange/pink/teal/indigo/yellow/mint/cyan/red/brown/gray`), методы `color(token)`, `nextToken(token)`, `fallbackToken(name)`

**`game_store.dart`** новые поля и методы:
- `bool showCelebration`, `bool isPausedAfterMaximum`, `bool onboardingShown`
- `Map<int, List<SpendItem>> draftItemsByDayIndex`
- `List<String> customCategories`, `Map<String, String> customCategoryColors`
- `DayEntry? get todayEntry` — поиск по calendar date (не `days.last`)
- `ensureTodayEntry()` — помечает пропущенные дни, создаёт сегодняшний
- `_startMidnightWatcher()` — `Future.delayed` до следующей полуночи
- `saveSpends(items, dayIndex)` — редактирование исторических дней
- `updateDraftItems(items, dayIndex)` / `draftItems(dayIndex)`
- `addCustomCategory`, `renameCustomCategory`, `cycleCustomCategoryColor`
- `List<String> get categorySuggestions` — дефолт 8/языка + кастомные
- `restartGame()`, `dismissCelebration()`
- `_saveAll()` с try/catch + поле `String? persistenceError`
- Статическая карта `defaultCategoriesByLanguage` (8 × 3 языка)

**`persistence_service.dart`:** новые ключи, try/catch везде

**`go_router` скелет** в `app_router.dart`:
- `/onboarding` → OnboardingScreen
- ShellRoute → HomeScreen
  - `/today` → TodayScreen
  - `/today/day/:dayIndex` → DaySpendsScreen
  - `/history` → HistoryScreen
  - `/achievements` → AchievementsScreen
  - `/settings` → SettingsScreen
- redirect: если `!onboardingShown` → `/onboarding`

---

### Фаза 2 — Календарная сетка и Liquid Fill

**`liquid_fill_painter.dart`:**
- Волна: `steps = max(24, width/6)` точек, `y = fillTop + sin((x/width)·2π + phase) · amplitude`
- Амплитуда: `clamp(height*0.05, 2, 8)`; скорость фазы: 1.2 рад/с
- Пузыри: `SeededRandom` (xorshift64, константа `0x9E3779B97F4A7C15`), 10 штук
- Цвет прогресса: 0–45% → красный, 46–90% → оранжевый, 91–101% → зелёный, >101% → бургундский `#990033`
- `shouldRepaint`: только при изменении `phase` или `progress`

**`day_tile.dart`:**
- `StatefulWidget`, `AnimationController.repeat()` для `phase`
- Размер 92×92, `BorderRadius.circular(11)`
- Стекло: `Colors.white.withOpacity(selected ? 0.18 : 0.12)`, border `accentColor` при выборе
- Пропущенный день: оранжевый тинт
- `onTap` → `onSelected`, `onLongPress` → `onEditRequested`
- Если `liquidEffectEnabled == false` — простой `FractionallySizedBox` вместо painter

**`calendar_grid.dart`:**
- Группировка по месяцам → `SingleChildScrollView` → `Column` секций
- Каждая секция: метка месяца `DateFormat('LLL', locale)` + `Row` тайлов, spacing 12
- `WidgetsBinding.addPostFrameCallback` → scroll to last tile

**`day_detail_panel.dart`:**
- Три stat-карточки: Потрачено (синий), Остаток (зелёный/красный), Статус
- Список трат с `Dismissible` (swipe-to-delete)
- Glassmorphism: `ClipRRect` → `BackdropFilter(blur 10)` → `Container(white 0.15)`
- Кнопка "Добавить траты"

**`today_screen.dart`** — полный переписать:
- `LayoutBuilder` → ширина ≥ 720: `Row(CalendarPanel 44% + DayDetailPanel)`; уже: `Column(CalendarPanel fixed 260 + DayDetailPanel expanded)`
- Фоновый градиент: `LinearGradient([#F5F7FD, #EBF2FA])`
- Слушатель `store.showCelebration` → `showGeneralDialog(CelebrationScreen)`

---

### Фаза 3 — Редактор трат (DaySpendsScreen)

- Параметр `int dayIndex` (не только сегодня)
- Автосохранение: `Timer` 3 с debounce → `store.updateDraftItems()`; в `dispose` — немедленный flush
- `_editingItemId` для in-place редактирования
- `Wrap` категорий: `CategoryChip` виджеты (tap=выбор, double-tap=`CategoryEditorSheet`)
- `CategoryEditorSheet`: `TextField` переименования + цветовой цикл
- Shake-валидация: `TweenAnimationBuilder<double>` → `Transform.translate(sin(t·π·4)·8, 0)` 400 мс
- `HapticFeedback.lightImpact()` при превышении лимита
- Подпись "можно до +5%"
- Загрузка драфтов из `store.draftItems(dayIndex)` при init

---

### Фаза 4 — Экран Celebration

**`celebration_screen.dart`:**
- `ConfettiWidget` (пакет `confetti`) сверху, `BlastDirectionality.explosive`
- Трофей `Text('🏆', style: fontSize 80)`
- Локализованный заголовок "Максимум достигнут!" / "Maximum reached!" / "Maximum erreicht!"
- `FilledButton` → `store.restartGame()` + `context.pop()`
- `TextButton` → `store.dismissCelebration()` + `context.pop()`
- Вызов из `TodayScreen` через `showGeneralDialog`

---

### Фаза 5 — Онбординг

**`onboarding_screen.dart`:**
- `PageController`, 3 страницы
- Каждая страница: иконка (`Icons.calendar_month / list_alt / touch_app`, size 42) + заголовок + текст
- Glassmorphism карточка: `ClipRRect` → `BackdropFilter` → `Container(white 0.3, border white 0.35, radius 32)`
- Градиент фона: `LinearGradient([#F2EEE0, #D6E3D6])`
- Кнопки: Next (стр 0–1), "Начать демо" (стр 2), Skip (всегда)
- Планшет: ширина карточки `min(maxWidth, 760)`
- "Начать демо": `store.settings = settings.copyWith(onboardingShown: true)` + `context.go('/today')`

---

### Фаза 6 — Settings полная версия

**`fx_service.dart`:** GET `https://api.frankfurter.app/latest?from=$from&to=$to`, вернуть `double?`

**`notification_service.dart`:**
- `requestPermission()`, `scheduleDailyReminder(hour, minute, title, body)` через `zonedSchedule`
- Канал Android `'daily-reminder'`

**`settings_screen.dart`** — полный переписать, секции:
1. Язык (существующий `SegmentedButton`)
2. Лимиты: Start Amount + Max Amount (TextFormField decimal) + Save
3. Max Behavior (существующий RadioListTile) + hint
4. FX Rate: ручное поле + "Обновить" (анимация ✓) + "Получить курс" (loading indicator)
5. Notifications: `SwitchListTile` + `TimePickerDialog`
6. Replay Onboarding: `TextButton`
7. Danger Zone: Reset All (`AlertDialog` confirmation) → `store.restartGame()`

---

### Фаза 7 — Полировка History и Achievements

**`history_screen.dart`:**
- Пустое состояние: `EmptyStateView(Icons.history_toggle_off)`
- Карточки: `Card(borderRadius: 16)`, badge статуса (`Chip`)
- Планшет: `GridView(crossAxisCount: 2)`

**`achievements_screen.dart`:**
- Добавить `streak30` (отсутствует во Flutter-версии)
- Иконки: `Icons.emoji_events` (earned) / `Icons.lock_outline` (locked)
- Прогресс хинт для незаработанных: "Стрик 3 — сейчас: 1"
- Пустое состояние

---

### Фаза 8 — Дизайн-система

**`app_theme.dart`:**
- `colorSchemeSeed: Color(0xFF2EC27E)` (зелёный из Swift)
- `useMaterial3: true`
- `CardTheme(elevation: 0, shape: RoundedRectangleBorder(radius: 20))`
- `InputDecorationTheme(border: OutlineInputBorder(radius: 14), filled: true)`
- `AppBarTheme(scrolledUnderElevation: 0, backgroundColor: transparent)`

**`home_screen.dart`:**
- LayoutBuilder: ≥720 → `NavigationRail` (extended если ≥900) + тело; <720 → `BottomNavigationBar`
- `_selectedIndex` shared state между обоими вариантами nav

**`panel_card.dart`:** переиспользуемый glassmorphism-контейнер

---

### Фаза 9 — Финализация go_router и навигации

- `MaterialApp.router(routerConfig: appRouter)` в `main.dart`
- `appRouter` создаётся в `State` с доступом к `store` для redirect-логики
- `ShellRoute` правильно сохраняет состояние вкладок
- `NavigationRail` использует `GoRouterState.fullPath` для подсветки активного пункта

---

### Фаза 10 — Обработка ошибок и тесты

**Ошибки:**
- `persistence_service.dart`: try/catch, логирование
- `GameStore.persistenceError` → `ErrorBanner` виджет

**Тесты:**
- `game_store_test.dart`: `ensureTodayEntry`, midnight watcher, drafts, categories
- `persistence_service_test.dart`: все новые ключи, корректная обработка битых данных
- `widgets/day_tile_test.dart`: golden tests (selected/normal/missed, 0%/50%/100%)

---

## Адаптивность (планшеты)

| Ширина | Навигация | Today Screen | History |
|--------|-----------|--------------|---------|
| < 720 | BottomNavigationBar | Column (calendar + detail) | Список |
| ≥ 720 | NavigationRail | Row (calendar 44% + detail) | Grid 2 col |
| ≥ 900 | NavigationRail extended | Row (calendar 44% + detail) | Grid 2 col |

Breakpoint-константа: `kTabletBreakpoint = 720.0` в `lib/theme/app_theme.dart`

## Проверка (verification)

1. `flutter run` на iPhone-симуляторе и iPad-симуляторе → проверить оба layout-варианта
2. `flutter run` на Android-эмуляторе (phone) и Android tablet (7" или 10")
3. Тесты: `flutter test` — все зелёные
4. Проверить: создание дня, добавление траты, сохранение, стрик, достижение streak3
5. Проверить: достижение максимума → Celebration экран → Restart → сброс
6. Проверить: онбординг при первом запуске, replay из Settings
7. Проверить: нотификации (дать разрешение, установить время, перезапустить)
8. Проверить: FX fetch (должен обновить курс в Settings)
9. Golden tests для `day_tile.dart`

## Порядок реализации с учётом зависимостей

```
Фаза 1 (модели + стор + pubspec)
    ↓
Фаза 2 (календарь)  ←→  Фаза 3 (редактор трат)   [параллельно]
    ↓
Фаза 4 (Celebration)     Фаза 5 (Onboarding)      [параллельно]
    ↓
Фаза 6 (Settings)
    ↓
Фаза 7 (History/Achievements)  Фаза 8 (Theme)      [параллельно]
    ↓
Фаза 9 (go_router финализация)
    ↓
Фаза 10 (ошибки + тесты)
```
