# student_management

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
lib/
│
├── core/
│   ├── constants/
│   ├── utils/
│   ├── services/
│   ├── widgets/
│   └── config/
│       ├── themes/
│       └── router.dart
│
├── models/
│   ├── user_model.dart
│   ├── announcement_model.dart
│   └── schedule_model.dart
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   ├── presentation/
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   └── widgets/
│   │   └── provider/
│   │       └── auth_provider.dart
│   │
│   ├── student/
│   │   ├── data/
│   │   ├── domain/
│   │   ├── presentation/
│   │   │   └── student_home.dart
│   │   └── provider/
│
│   ├── lecturer/
│   │   ├── data/
│   │   ├── domain/
│   │   ├── presentation/
│   │   └── provider/
│
│   ├── admin/
│   │   ├── data/
│   │   ├── domain/
│   │   ├── presentation/
│   │   └── provider/
│
│   ├── notifications/
│   │   ├── services/
│   │   ├── provider/
│   │   └── widgets/
│
│   ├── messages/
│   │   ├── chat/
│   │   └── bulletin/
│
│   └── profile/
│       ├── screens/
│       ├── provider/
│       └── widgets/
│
└── main.dart
