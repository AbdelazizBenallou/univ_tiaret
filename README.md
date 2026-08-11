# Univ Tiaret

A Flutter-based student application for **Universite de Tiaret** that enables students to browse academic content, manage downloads, track favorites, schedule reminders, and view lesson files across seasons, semesters, modules, and activities.

![Flutter](https://img.shields.io/badge/Flutter-3.12+-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.12+-0175C2?logo=dart)
![License](https://img.shields.io/badge/license-MIT-green)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-lightgrey)

---

## Features

### Authentication & Security
- Student registration with program, level, and speciality selection
- Secure token storage with `flutter_secure_storage`
- JWT access + refresh token flow with automatic refresh deduplication
- Device fingerprinting for enhanced security
- Forgot password with email verification and reset code flow

### Academic Navigation
- **Seasons** — Browse academic years with "current" indicator
- **Semesters** — Navigate semesters within a level
- **Modules** — Search, sort (by name/coefficient), and switch between list/grid views
  - Automatic endpoint switching for License vs Master programs
- **Activities** — Filter by type (Lesson, TD, TP, Exam)

### File Management
- **Paginated lesson files** with infinite scroll and subscription guard
- **Concurrent downloads** — Max 3 simultaneous downloads with progress tracking
- **Download queue** — Persistent downloads across sessions via SharedPreferences
- **Favorites** — Bookmark files with local SQLite storage and filtering by module/activity/season
- **In-app file viewer** — PDF, images, text/code, Office documents (docx, pptx, xlsx), and video/audio playback

### Calendar & Reminders
- **Calendar view** with event tracking
- **Local reminders** — Create, edit, and delete reminders stored in SQLite

### Profile & Subscription
- **Profile management** — View and edit personal and academic information, with an offline cache that keeps showing saved data when the server is unreachable
- **Social media links** — Add/edit social profiles from the edit profile screen
- **About Us & team** — Team member list with full member detail pages (bio + social links)
- **Subscription status** — View current subscription, demand history, and create new demands
- **Password management** — Change password and forgot password flows

### Localization
- **English, French, Arabic** — Full RTL support
- Dynamic font switching (Plus Jakarta / Cairo)
- 300+ translation keys per language

### Theme
- Light and Dark mode with system preference option
- Material 2 design with custom theming
- Consistent icon colors that adapt in dark mode (Lucide icon set)

### Settings
- **About Us** — Team members list opening into full member detail pages
- **Terms & Conditions** — Dedicated page (content-ready scaffold)
- **Security** — Change password and subscription management

### Server Configuration
- Runtime-configurable backend server IP/port
- Built-in health check to verify connectivity

---

## Architecture

```
lib/
├── main.dart                    # Entry point, ProviderScope, MediaKit init
├── entry_point.dart             # Main shell: 5-tab bottom nav (Home/Favorites/Downloads/Calendar/Settings)
├── constants.dart               # App-wide constants, colors, validators
├── l10n/                        # Localization system (EN/FR/AR)
│   ├── app_localizations.dart   #   300+ keys per language
│   ├── localizations_delegate.dart
│   └── locale_preferences.dart  #   Locale persistence
├── preferences/
│   └── theme_preferences.dart   # Theme mode persistence
├── theme/                       # AppTheme, ButtonTheme, InputDecoration
├── models/                      # Data classes with fromJson/toJson
│   ├── user_model.dart          #   UserModel (roles, level, speciality)
│   ├── auth_response_model.dart #   AuthResponseModel
│   ├── server_config_model.dart #   ServerConfigModel
│   ├── season.dart              #   Season
│   ├── semester.dart            #   Semester
│   ├── module.dart              #   Module
│   ├── activity.dart            #   Activity
│   ├── lesson_file.dart         #   LessonFile
│   ├── academic_level.dart      #   AcademicLevel
│   ├── academic_program.dart    #   AcademicProgram
│   ├── academic_speciality.dart #   AcademicSpeciality
│   ├── favorite_file.dart       #   FavoriteFile (with fromDb/toDb)
│   ├── reminder.dart            #   Reminder (with fromDb/toDb)
│   ├── current_subscription.dart
│   └── subscription_demand.dart
├── db/                          # Local SQLite database layer
│   ├── db_helper.dart           #   7 cached tables + favorites + reminders + user_profile
│   └── repositories/            #   Repository pattern for each entity
├── services/                    # Network and platform services
│   ├── api_service.dart         #   HTTP client with JWT refresh, retry, dedup
│   ├── auth_service.dart        #   Secure storage, device fingerprint
│   ├── download_service.dart    #   Concurrent download queue (max 3)
│   ├── server_config_service.dart
│   └── notification_service.dart
├── logic/                       # Riverpod ChangeNotifierProviders
│   ├── auth_provider.dart       #   Login/register/logout state
│   ├── seasons_provider.dart    #   Academic seasons (cache-first)
│   ├── semesters_provider.dart  #   Semesters (cache-first)
│   ├── modules_provider.dart    #   Modules (License/Master aware)
│   ├── activities_provider.dart #   Activity types
│   ├── lesson_files_provider.dart # Paginated files (cache-first)
│   ├── download_provider.dart   #   Download queue bridge
│   ├── favorite_provider.dart   #   Favorites CRUD
│   ├── reminder_provider.dart   #   Reminders CRUD
│   ├── profile_provider.dart    #   Profile load/update/sync
│   ├── password_provider.dart   #   Forgot/reset/change password
│   ├── verification_provider.dart # Email verification
│   └── subscription_provider.dart # Subscription status + demands
├── providers/
│   └── navigation_provider.dart # Bottom nav index state
├── route/                       # Named route definitions & router
├── screens/                     # Feature screens
│   ├── splash/                  #   Splash screen (auth check)
│   ├── auth/                    #   Login, Register, Forgot Password, OTP, Reset
│   ├── home/                    #   Seasons, Semesters, Modules, Activities,
│   │                            #   LessonFiles, Downloads, Favorites, Calendar
│   ├── settings/                #   Settings, Change Password
│   ├── profile/                 #   Profile view/edit
│   ├── file_viewer/             #   PDF, Image, Text, Office, Video/Audio
│   └── subscription/            #   Subscribe screen
├── widgets/                     # Reusable UI widgets
│   ├── app_bottom_nav.dart      #   5-tab bottom nav with download badge
│   └── sort_bottom_sheet.dart   #   Sort options picker
├── components/                  # Reusable UI components
│   ├── floating_snackbar.dart   #   Colored notifications
│   ├── server_config_dialog.dart
│   ├── modern_list_tile.dart    #   Gradient icon tiles
│   ├── breadcrumb_bar.dart      #   Hierarchy breadcrumbs
│   ├── subscription_guard.dart  #   Subscription gate
│   ├── skeleton_tile.dart       #   Shimmer loading
│   ├── bottom_sheet_selector.dart
│   └── list_tile/
└── utils/
    └── file_utils.dart          # File categories, icons, colors, sizes
```

### State Management

| Provider | Purpose |
|----------|---------|
| `authProvider` | Authentication state, login/register/logout, programs |
| `seasonsProvider` | Academic year listing (cache-first) |
| `semestersProvider` | Semester listing per level (cache-first) |
| `modulesProvider` | Module listing (License/Master aware) |
| `activitiesProvider` | Activity type listing per module |
| `lessonFilesProvider` | Paginated file listing (cache-first, subscription-gated) |
| `downloadProvider` | Download queue UI bridge |
| `favoriteProvider` | Favorites CRUD with filtering |
| `reminderProvider` | Reminders CRUD |
| `profileProvider` | Profile load/update/sync |
| `passwordProvider` | Forgot/reset/change password |
| `verificationProvider` | Email verification |
| `subscriptionProvider` | Subscription status + demands |

### Navigation Flow

```
Splash Screen (animated app icon + branding)
    │
    ├─ [Authenticated] ──→ EntryPoint (5 tabs)
    │     ├── Home ──→ Seasons ──→ Semesters ──→ Modules ──→ Activities ──→ Lesson Files
    │     │                                                                        │
    │     │                                                                     File Viewer / Download
    │     ├── Favorites (filter by module/activity/season)
    │     ├── Downloads (active + completed)
    │     ├── Calendar (reminders)
    │     └── Settings ──→ Profile / Security / Subscription / About Us / Terms & Conditions
    │
    └─ [Unauthenticated] ──→ Login Screen
                               ├── Register (Personal Info → Account)
                               └── Forgot Password → OTP → Reset
```

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Framework | Flutter 3.12+ |
| State Management | Flutter Riverpod v2 (ChangeNotifierProvider) |
| Local Database | sqflite (7 cached tables + favorites + reminders + user_profile) |
| Networking | `http` package |
| Secure Storage | `flutter_secure_storage` |
| Preferences | `shared_preferences` |
| PDF Viewing | `pdfrx` |
| Video/Audio | `media_kit` |
| Office Docs | `docx_file_viewer` |
| File Opening | `open_filex` |
| Loading Effects | `shimmer` |
| Device Info | `device_info_plus` + `crypto` (fingerprinting) |
| Form Validation | `form_field_validator` |
| Icons | `lucide_icons_flutter` (Lucide icon set) |
| Notifications | `flutter_local_notifications` |
| Calendar | `table_calendar` |
| Fonts | Plus Jakarta, Cairo (Arabic), Grandis Extended |

---

## Getting Started

### Prerequisites

- **Flutter SDK** 3.12.2 or higher
- **Dart SDK** 3.12.2 or higher
- A running backend server (default: `http://localhost:3000`)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/univ_tiaret.git
   cd univ_tiaret
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure the server:
   - Launch the app and tap the **settings icon** on the login screen
   - Enter the backend server IP and port
   - Use the **health check** button to verify connectivity

4. Run the app:
   ```bash
   flutter run
   ```

### Build

```bash
# Android APK
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release

# Desktop (Linux/macOS/Windows)
flutter build linux --release
flutter build macos --release
flutter build windows --release
```

---

## API Endpoints

The app communicates with a REST API at the configured server base URL:

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/v1/auth/login` | User login |
| `POST` | `/v1/auth/register` | User registration |
| `POST` | `/v1/auth/logout` | User logout |
| `POST` | `/v1/auth/refresh-token` | Refresh access token |
| `POST` | `/v1/auth/forgot-password` | Send reset code |
| `POST` | `/v1/auth/verify-code` | Verify reset code |
| `POST` | `/v1/auth/reset-password` | Reset password |
| `GET` | `/health` | Server health check |
| `GET` | `/v1/seasons` | List academic seasons |
| `GET` | `/v1/semesters?level_id=X` | List semesters |
| `GET` | `/v1/modules/license?semester_id=X` | List license modules |
| `GET` | `/v1/modules/master?semester_id=X&speciality_id=X` | List master modules |
| `GET` | `/v1/activities?module_id=X` | List activity types |
| `GET` | `/v1/lesson-files?module_id=X&activity_type_id=X&season_id=X&page=X` | Paginated files |
| `GET` | `/v1/programs` | List academic programs |
| `PATCH` | `/v1/users/profile` | Update profile |
| `POST` | `/v1/subscriptions/demand` | Create subscription demand |
| `GET` | `/v1/subscriptions/current` | Get current subscription |

---

## Configuration

### Server Settings
Server IP and port are stored in `SharedPreferences` and configurable at runtime via the settings dialog. No `.env` files needed.

### Theme & Locale
Both theme mode (System/Light/Dark) and locale (EN/FR/AR) are persisted in `SharedPreferences` and survive app restarts.

---

## Database Schema (v6)

| Table | Purpose |
|-------|---------|
| `cached_seasons` | Academic years |
| `cached_semesters` | Semesters per level |
| `cached_modules` | Modules per semester (with level_name + speciality_id for Master filtering) |
| `cached_activities` | Activity types per module |
| `cached_lesson_files` | Files per module/activity/season (composite primary key) |
| `favorites` | Bookmarked files with full metadata |
| `reminders` | Calendar reminders |
| `user_profile` | Local user profile cache (synced from auth + API) |

---

## Project Structure Highlights

- **Cache-first loading** — Every data provider checks SQLite before hitting the API
- **Static service architecture** — `ApiService`, `AuthService`, `DownloadService` are static utility classes
- **Named route navigation** — All routes defined in `route_constants.dart` with slide-from-right + fade transitions
- **RTL support** — Breadcrumbs, chevrons, and text direction adapt for Arabic
- **Concurrent download management** — Max 3 simultaneous downloads with progress throttling
- **Token refresh deduplication** — Concurrent 401 responses trigger only one refresh request using `Completer`
- **Subscription gating** — Lesson files are wrapped in `SubscriptionGuard` to enforce active subscription

---

## Testing

```bash
flutter test
```

> **Note:** Currently only the default Flutter widget test exists. Contributions for unit, widget, and integration tests are welcome.

---

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

## Acknowledgments

- [Flutter](https://flutter.dev) — UI framework
- [Riverpod](https://riverpod.dev) — State management
- [pdfrx](https://pub.dev/packages/pdfrx) — PDF rendering
- [media_kit](https://pub.dev/packages/media_kit) — Video/audio playback
- Universite de Tiaret — Academic institution
