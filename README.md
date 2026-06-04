# KLE HOMECARE — Flutter App

Cross-platform Flutter frontend for the KLE HOMECARE home-healthcare platform.  
Supports **Android**, **iOS**, **Web**, and **Windows/macOS/Linux** desktop.

---

## Tech Stack

| Concern | Package |
|---------|---------|
| State management | flutter_riverpod ^2.5.0 |
| Navigation | go_router ^13.0.0 |
| HTTP client | dio ^5.4.0 |
| Secure token storage | flutter_secure_storage ^9.0.0 |
| Persistent settings | shared_preferences ^2.2.0 |
| Fonts | google_fonts ^6.2.1 |
| Animations | flutter_animate ^4.5.0 |
| Push notifications | firebase_messaging ^15.1.3 + flutter_local_notifications |
| Internationalisation | intl ^0.19.0 |

---

## Project Structure

```
kle_homecare_flutter/
└── lib/
    ├── main.dart                          # App entry point — initialises DioClient, ApiConstants, Firebase
    │
    ├── core/
    │   ├── constants/
    │   │   ├── api_constants.dart         # All endpoint paths + base-URL management (SharedPreferences)
    │   │   ├── app_colors.dart            # Brand palette, role colours, gradients, shadows
    │   │   └── app_strings.dart           # Centralised string constants
    │   ├── errors/
    │   │   ├── exceptions.dart            # Typed exception classes
    │   │   └── failure.dart               # Failure sealed class
    │   ├── network/
    │   │   ├── dio_client.dart            # Singleton Dio instance — auth interceptor, token refresh
    │   │   └── api_service.dart           # Generic get/post/patch/delete wrappers
    │   └── utils/
    │       ├── helpers.py                 # AppHelpers — statusLabel, urgencyLabel, friendlyError
    │       └── validators.dart            # Email, phone, password validators
    │
    ├── features/
    │   │
    │   ├── auth/
    │   │   ├── data/
    │   │   │   ├── models/user_model.dart
    │   │   │   └── repositories/auth_repository_impl.dart   # Dio calls to /auth/*
    │   │   ├── domain/
    │   │   │   ├── entities/user_entity.dart
    │   │   │   └── repositories/auth_repository.dart        # Interface
    │   │   └── presentation/
    │   │       ├── providers/auth_provider.dart             # AuthNotifier (AsyncNotifier)
    │   │       ├── screens/
    │   │       │   ├── login_screen.dart        # Patient-only login (allowedRole: patient)
    │   │       │   ├── nurse_login_screen.dart  # Nurse-only login  (allowedRole: nurse)
    │   │       │   ├── admin_login_screen.dart  # Admin-only login  (allowedRole: admin)
    │   │       │   └── register_screen.dart     # Patient self-registration
    │   │       └── widgets/                     # Reusable auth form widgets
    │   │
    │   ├── admin/
    │   │   ├── data/models/service_model.dart
    │   │   └── presentation/
    │   │       ├── providers/
    │   │       │   ├── admin_provider.dart                  # AdminNotifier — requests, nurses, stats
    │   │       │   ├── nurses_provider.dart                 # NursesNotifier — resource CRUD
    │   │       │   ├── services_provider.dart               # ServicesNotifier — catalogue CRUD
    │   │       │   └── resource_categories_provider.dart    # ResourceCategoriesNotifier — category CRUD
    │   │       └── screens/
    │   │           ├── admin_shell.dart         # Responsive shell: sidebar (desktop) / bottom nav (mobile)
    │   │           ├── admin_home_tab.dart      # Dashboard — requests table/cards + assign sheet
    │   │           ├── admin_nurses_tab.dart    # Resources tab — CRUD + categories management
    │   │           ├── admin_services_tab.dart  # Service catalogue — CRUD
    │   │           ├── admin_profile_tab.dart   # Admin profile + settings
    │   │           └── assign_nurse_screen.dart # Standalone assign screen (legacy)
    │   │
    │   ├── nurse/
    │   │   └── presentation/
    │   │       ├── providers/nurse_provider.dart            # NurseNotifier — jobs, alerts
    │   │       └── screens/
    │   │           ├── nurse_shell.dart         # Nurse bottom nav shell
    │   │           ├── nurse_alerts_tab.dart    # Pending job alerts
    │   │           ├── nurse_jobs_tab.dart      # Active + history jobs
    │   │           └── job_detail_screen.dart   # Full job detail + status update
    │   │
    │   └── patient/
    │       ├── data/
    │       │   ├── models/service_request_model.dart
    │       │   └── repositories/patient_repository_impl.dart
    │       ├── domain/repositories/patient_repository.dart
    │       └── presentation/
    │           ├── providers/
    │           │   ├── patient_provider.dart                # PatientNotifier — requests, notifications
    │           │   └── catalogue_provider.dart              # CatalogueNotifier — service catalogue
    │           ├── screens/
    │           │   ├── patient_shell.dart       # Patient bottom nav shell
    │           │   ├── patient_dashboard.dart   # Request list + status overview
    │           │   └── request_service_screen.dart  # New service request form
    │           └── widgets/                     # Request card, status chip, etc.
    │
    ├── routes/
    │   └── app_router.dart                      # GoRouter — role-based redirect guards
    │
    ├── services/
    │   └── notification_service.dart            # FCM + local notification setup
    │
    └── shared/
        ├── screens/
        │   └── server_settings_screen.dart      # Runtime base-URL configuration
        ├── storage/
        │   └── secure_storage.dart              # flutter_secure_storage wrapper
        └── widgets/
            ├── kle_app_bar.dart                 # Branded app bar with role colour
            ├── custom_button.dart
            ├── custom_text_field.dart
            └── loading_overlay.dart
```

---

## Setup & Running

### Prerequisites
- Flutter SDK ≥ 3.3.0
- Dart SDK ≥ 3.3.0
- A running instance of the KLE HOMECARE backend

### Steps

```bash
# 1. Get dependencies
flutter pub get

# 2. Run on your target platform
flutter run                          # default device
flutter run -d chrome                # web
flutter run -d windows               # Windows desktop
flutter run -d android               # Android (emulator or device)
```

### Setting the API Base URL

The app stores the backend URL in SharedPreferences so it can be changed at runtime — no rebuild needed.

**Default URLs (automatic):**
- Windows/macOS/Linux: `http://127.0.0.1:8000/api/v1`
- Android/iOS/Web: ngrok URL set in `ApiConstants._ngrokUrl`

**Changing at runtime (recommended for device testing):**  
Open the app → any login screen → tap the settings icon → enter your ngrok or server URL including `/api/v1`.

**Updating the ngrok default in code:**  
Edit `lib/core/constants/api_constants.dart`:
```dart
static const String _ngrokUrl = 'https://YOUR-NGROK-URL.ngrok-free.app/api/v1';
```

---

## Navigation & Routing

Routing is handled by `go_router` with role-based redirect guards.

| Path | Screen | Access |
|------|--------|--------|
| `/login` | Patient Login | Unauthenticated |
| `/nurse-login` | Nurse Login | Unauthenticated |
| `/admin-login` | Admin Login | Unauthenticated |
| `/register` | Registration | Unauthenticated |
| `/patient` | Patient Shell | `patient` role |
| `/patient/new-request` | New Request | `patient` role |
| `/nurse` | Nurse Shell | `nurse` role |
| `/nurse/jobs/:id` | Job Detail | `nurse` role |
| `/admin` | Admin Shell | `admin` role |
| `/settings/server` | Server Settings | Any authenticated |

After login the app automatically redirects to the role dashboard.  
Accessing a role's route with the wrong role redirects to the correct dashboard.

---

## Role-Gated Login Portals

Each portal enforces its own role at the `AuthNotifier` level — if the wrong role logs in, the session is cleared immediately and an error message is shown.

| Screen | File | Allowed |
|--------|------|---------|
| Patient Login | `login_screen.dart` | `patient` only |
| Nurse Login | `nurse_login_screen.dart` | `nurse` only |
| Admin Login | `admin_login_screen.dart` | `admin` only |

The patient login screen shows "Nurse Login" and "Admin Login" links at the bottom so users can navigate to the correct portal.

---

## State Management

All state is managed with **Riverpod AsyncNotifier / Notifier** providers.

| Provider | File | Responsibility |
|----------|------|----------------|
| `authProvider` | auth/providers/auth_provider.dart | Login, register, logout, current user |
| `adminProvider` | admin/providers/admin_provider.dart | Dashboard stats, requests, assign nurse; 15s auto-poll |
| `nursesProvider` | admin/providers/nurses_provider.dart | Resource CRUD (create, update, toggle, delete) |
| `servicesProvider` | admin/providers/services_provider.dart | Service catalogue CRUD |
| `resourceCategoriesProvider` | admin/providers/resource_categories_provider.dart | Category CRUD |
| `patientProvider` | patient/providers/patient_provider.dart | Patient requests + notifications |
| `catalogueProvider` | patient/providers/catalogue_provider.dart | Service catalogue for request form |
| `nurseProvider` | nurse/providers/nurse_provider.dart | Nurse jobs, alerts, status updates |

---

## Admin Panel Features

### Dashboard (Home Tab)
- Real-time KPI cards: Total Patients, Active Resources, Pending, Completed
- Auto-refreshes every 15 seconds (silent, no spinner)
- Search by patient name, city, service type
- Filter chips by status
- Desktop: data table with inline Assign/Reassign
- Mobile: request cards with bottom sheet detail + assign

### Resources Tab (formerly Nurses)
- Full CRUD for resource accounts
- **Category dropdown** on create and edit forms
- **Manage Categories** button — inline add/toggle/delete of resource categories
- Desktop: data table with View / Edit / Toggle / Delete actions
- Mobile: cards with 3-dot popup menu (View / Edit / Toggle / Remove)
- Detail sheet with Edit / Activate-Deactivate / Remove action buttons

### Services Tab
- Full CRUD for the service catalogue
- Group by category
- Desktop: sortable table; Mobile: grouped card list

### Assign Resource Sheet
- **Category filter chips** — tap a category to show only matching resources
- Shows resource category badge on each list item
- Admin notes field
- Confirm Assignment button

---

## Authentication Flow

1. User opens the appropriate login screen (Patient / Nurse / Admin)
2. Credentials submitted → `POST /api/v1/auth/login`
3. `access_token` stored in `flutter_secure_storage` (encrypted on-device)
4. All API calls attach `Authorization: Bearer <token>` via Dio interceptor
5. On 401 response, Dio interceptor automatically calls `POST /auth/refresh`
6. If refresh also fails, user is logged out and sent back to login
7. Logout calls `POST /auth/logout` then clears secure storage

---

## Push Notifications

Firebase Cloud Messaging (FCM) is configured in `notification_service.dart`.  
Nurses receive a local notification when assigned a new job.  
Foreground messages are handled via `flutter_local_notifications`.

> Firebase `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) must be placed in the correct platform directories before building for those targets.

---

## Build

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release

# Windows
flutter build windows --release
```

---

## Assets

```
assets/
├── images/
│   └── kle_logo.png    # KLE Society / KLES Hospital logo
└── icons/              # Additional icon assets
```
