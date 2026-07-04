# LibLibe

A modern, cross-platform library and book management application built with Flutter and Firebase. LibLibe allows users to organize their book collections, discover new reads, track reading progress, and manage book shopping lists with a beautiful Glassmorphism-inspired UI.

## 📱 Features

- **Authentication:** Secure login and registration via Firebase Authentication (Email/Password, Google Sign-In).
- **Book Management:** Add, edit, and organize books in your personal or shared libraries.
- **Barcode Scanner:** Easily add books to your library by scanning their ISBN barcodes using the built-in scanner.
- **Custom Lists:** Create custom reading lists (e.g., Favorites, Currently Reading, To Read).
- **Shopping Lists:** Keep track of books you want to buy.
- **Excel Import/Export:** Seamlessly import existing book data from Excel files or export your library data.
- **Push Notifications:** Stay updated with FCM (Firebase Cloud Messaging) and local notifications.
- **Modern UI/UX:** A stunning interface featuring Glassmorphism, neon gradients, and fluid animations.
- **Multi-Platform:** Available on Android, iOS, and Web.

## 🛠 Tech Stack

- **Frontend:** [Flutter](https://flutter.dev/) (Dart)
- **Backend (BaaS):** [Firebase](https://firebase.google.com/)
  - Cloud Firestore (NoSQL Database)
  - Firebase Authentication
  - Firebase Cloud Storage (Cover images, media)
  - Firebase Cloud Functions
  - Firebase Cloud Messaging (FCM)
  - Firebase Crashlytics & App Check
- **State Management:** `provider`
- **Key Packages:**
  - `mobile_scanner`: Barcode and QR code scanning.
  - `excel`: Excel file parsing and generation.
  - `shared_preferences`: Local caching and settings.
  - `flutter_local_notifications`: On-device notifications.
  - `google_fonts` & `cupertino_icons` & `phosphor_flutter`: Typography and Icons.

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (^3.10.0)
- Dart SDK
- Firebase CLI (for backend configuration)
- Android Studio / Xcode (for mobile builds)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/okolyigit/liblibeapp.git
   cd liblibeapp
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase:**
   Make sure you have your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) in the respective directories, or configure using the `flutterfire` CLI:
   ```bash
   flutterfire configure
   ```

4. **Run the App:**
   ```bash
   flutter run
   ```

## 📁 Project Structure

```text
lib/
├── screens/        # UI Screens (Dashboard, Books, Lists, Profile, etc.)
├── widgets/        # Reusable UI components (Glassmorphism cards, buttons, etc.)
├── services/       # Business logic & API calls (Firebase, Auth, Excel, Books)
├── models/         # Data models
├── theme/          # App theme, colors, text styles
└── utils/          # Helper functions and constants
```

## 🎨 UI/UX Highlights

LibLibe uses a custom design system heavily inspired by modern web and app design trends:
- **Glassmorphism:** Frosted glass effects on sidebars, dialogs, and bottom sheets (`glass_card.dart`, `glass_dialog.dart`).
- **Neon Accents:** Glowing buttons and gradient elements (`neon_gradient_button.dart`).
- **Smooth Animations:** Fluid transitions using Hero animations and custom animated widgets.

## 🛡 Security

- Uses **Firebase App Check** to protect backend resources from abuse.
- Custom Firestore Security Rules ensuring users can only read/write their own library data unless explicitly shared.

## 📄 License

This project is proprietary and confidential. All rights reserved.
