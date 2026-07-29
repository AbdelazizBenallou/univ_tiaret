# univ_tiaret

A comprehensive Flutter application for university management, featuring authentication, local database (sqflite), internationalization, file handling, calendar scheduling, and extensive UI components.

## Features
- **Authentication**: Secure login/registration with flutter_secure_storage
- **Database**: Local SQLite storage with Riverpod state management
- **Internationalization**: Multi-language support with locale preferences
- **File Management**: PDF/Office document viewing and download capabilities
- **Scheduling**: Calendar functionality with event tracking
- **Theming**: Custom themes with Plus Jakarta, Cairo, and Grandis Extended fonts
- **Notifications**: Local push notifications and secure storage integration

## Getting Started
1. Clone the repository: `git clone <repo-url>`
2. Install dependencies: `flutter pub get`
3. Configure Android/iOS settings as needed
4. Run the app: `flutter run`

## Tech Stack
- **Flutter SDK**: ^3.12.2
- **State Management**: flutter_riverpod
- **Database**: sqflite
- **Networking**: http
- **Secure Storage**: flutter_secure_storage
- **UI Components**: Custom bottom navigation, skeleton tiles, floating snackbar
- **Internationalization**: Localization delegate and generated localization files

## Project Structure
```
lib/
├── models/          # Data models (user, semester, module, etc.)
├── screens/         # Application screens (auth, home, settings)
├── providers/       # Riverpod providers for state management
├── db/              # SQLite database helpers and repositories
├── theme/           # Theme configuration and assets
├── widgets/         # Reusable UI components
└── services/        # Business logic (authentication, notifications)
```

## Usage
- Authentication flows: `/lib/screens/auth/`
- Main application navigation: `/lib/screens/home/`
- Database operations: `/lib/db/`
- Theme customization: `/lib/theme/`

## Contributing
Contributions are welcome! Please open an issue to discuss major changes before implementing them.

## License
This project is licensed under the MIT License - see the LICENSE file for details.