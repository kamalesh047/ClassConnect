# Class Connect 🎓

An advanced, cohort-focused academic management and productivity application built with Flutter, Cloud Firestore, and Material 3. Designed specifically to streamline academic scheduling, attendance compliance, assignment tracking, and cohort collaboration for engineering students.

---

## 📌 Problem Statement
University students and class representatives often struggle with fragmented academic communication:
- Important announcements and study materials get buried in informal messaging chats.
- Students lack visibility into their attendance thresholds and cannot easily compute how many classes they can skip or need to attend to stay above mandatory institutional minimums (e.g., 75%).
- Daily timetable changes, assignment deadlines, and faculty cabin locations are distributed across slow web portals and physical notice boards.

**Class Connect** consolidates all essential academic operations into a single, intuitive, mobile-first dashboard tailored for a specific classroom cohort.

---

## 👥 Target Users
- **Undergraduate Engineering Students:** To track daily lecture schedules, predict attendance safety margins, manage assignment deadlines, and compute GPAs.
- **Class Representatives (CRs) & Faculty Advisors:** To broadcast announcements, manage attendance records, post assignments, and update timetable sessions.

---

## ✨ Features Actually Implemented

### 1. Intelligent Attendance Engine & Predictor
- **Subject-by-Subject Tracking:** Real-time visibility into classes attended, total conducted, and current percentage.
- **Bunk & Catch-up Mathematical Predictor:**
  - *Safe Zone:* Calculates the exact number of future lectures a student can skip while remaining at or above 75%.
  - *Catch-up Goal:* Determines the exact number of consecutive classes required to restore attendance above 75%.
- **Admin Management Portal:** Dedicated administrative view with real-time student search and attendance editing per subject.

### 2. Time-Aware Academic Dashboard
- **Dynamic Lecture Banner:** Automatically queries the current day's timetable and displays the ongoing ("Happening Now") or upcoming ("Up Next") class based on the system clock.
- **Semester Exam Countdown:** Live widget displaying days remaining until upcoming examinations, with an admin edit modal.
- **Smart Insights:** Instant overview of attendance status (*Safe*, *Warning*, *Critical*) and pending assignment counts.

### 3. Academic Toolkit
- **Anna University GPA / CGPA Calculator:** Implements the official 10-point Anna University regulation scale (`O:10`, `A+:9`, `A:8`, `B+:7`, `B:6`, `C:5`, `U:0`) for course-wise GPA calculation and cumulative multi-semester CGPA tracking.
- **Pomodoro Study Timer:** Dedicated timer supporting 25-minute work, 5-minute short break, and 15-minute long break intervals.
- **Faculty Directory:** Searchable directory detailing professor cabins, designations, and one-tap `mailto:` communication links.

### 4. Collaboration & Organization
- **Cohort Group Chat:** Real-time messaging backed by Cloud Firestore with soft deletion, message pinning, online presence indicators, and administrative badges.
- **Priority-Sorted Assignment Tracker:** Categorizes tasks by priority (`Urgent` > `Medium` > `Low`) combined with due date chronological ordering.
- **Note Vault:** Curated study materials library categorized by media type (`PDF`, `Docs`, `PPT`, `Images`, `Link`) with view counts and like toggles.
- **Weekly Timetable:** Tabbed Monday–Saturday schedule with dynamic class list mode and static photo view mode.
- **Digital Student ID:** Stylized in-app student identification card displaying student registration number, role, batch, and status.

### 5. Automated Background Notifications
- Scheduled 9:00 AM local birthday reminders for cohort peers using local notifications and timezone management.
- Foreground notification channels powered by Firebase Cloud Messaging.

---

## 🛠️ Technology Stack
- **Framework:** [Flutter](https://flutter.dev) (SDK `^3.9.2`)
- **Language:** [Dart](https://dart.dev)
- **State Management:** [Provider](https://pub.dev/packages/provider) (`MultiProvider`, `StreamProvider`)
- **Backend as a Service (BaaS):** 
  - Firebase Authentication (Email/Password & Google OAuth)
  - Cloud Firestore (Real-time snapshots & reactive streams)
  - Firebase Cloud Messaging (Push notifications)
- **UI & UX:** Google Fonts (Outfit), Material 3, Custom Glassmorphism (`BackdropFilter`), Flutter Staggered Animations.
- **System Utilities:** `intl`, `url_launcher`, `flutter_local_notifications`, `timezone`, `permission_handler`.

---

## 🏛️ Application Architecture

```
lib/
├── core/                  # Core constants and shared configurations
├── data/                  # Master cohort data and whitelist configurations
├── models/                # Data models with Firestore serialization
│   ├── announcement_model.dart
│   ├── assignment_model.dart
│   ├── faculty_model.dart
│   ├── message_model.dart
│   ├── timetable_model.dart
│   └── user_model.dart
├── screens/               # Feature-specific UI screens
│   ├── announcements/     # Campus broadcast feed
│   ├── assignments/       # Priority assignment management
│   ├── attendance/        # Attendance tracker & prediction views
│   ├── auth/              # Login, registration & activation
│   ├── chat/              # Real-time cohort chatroom
│   ├── dashboard/         # Main home screen & smart timetable widget
│   ├── notes/             # Study materials link vault
│   ├── profile/           # Profile details & Digital ID Card
│   ├── timetable/         # Daily schedule & timetable viewer
│   └── tools/             # GPA calculator, Pomodoro timer, Faculty directory
├── services/              # Business logic & Firebase data providers
│   ├── assignment_service.dart
│   ├── auth_service.dart
│   ├── chat_service.dart
│   ├── database_service.dart
│   ├── notification_service.dart
│   ├── storage_service.dart
│   └── timetable_service.dart
├── theme/                 # AppTheme design tokens & Material 3 styling
├── widgets/               # Reusable UI components (GlassContainer, etc.)
├── firebase_options.dart  # Firebase platform initialization
└── main.dart              # Application entry point & Provider setup
```

---

## 🚀 Setup & Installation

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`3.24.0` or higher)
- Android Studio / VS Code with Flutter extensions
- Android SDK (API Level 34/35) and Java 11/17 JDK
- A registered [Firebase project](https://console.firebase.google.com/)

### Installation Steps
1. **Clone the repository:**
   ```bash
   git clone https://github.com/YOUR-USERNAME/ClassConnect.git
   cd ClassConnect
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase:**
   - Install the FlutterFire CLI:
     ```bash
     dart pub global activate flutterfire_cli
     ```
   - Connect your own Firebase project:
     ```bash
     flutterfire configure
     ```
   - Place your `google-services.json` inside `android/app/`.

4. **Verify static analysis:**
   ```bash
   flutter analyze
   ```

5. **Run the application:**
   ```bash
   flutter run
   ```

---

## ⚠️ Current Limitations
- **External Resource Links:** Study notes and documents are shared via external cloud URLs (e.g., Google Drive, Dropbox) to keep the backend lightweight and free-tier compliant.
- **Cohort Whitelist:** Roster authorization is evaluated against a pre-authorized schema in `lib/data/student_list.dart`.

---

## 🔒 Security & Privacy Notice
This repository contains sample student records in `lib/data/student_list.dart` for demonstration purposes. No real student personal information, phone numbers, or private credentials are included.

---

## 👨‍💻 Author
- **Developer:** Third-Year B.E. Artificial Intelligence & Machine Learning Student
- **Project:** Class Connect (Academic Portfolio Project)

