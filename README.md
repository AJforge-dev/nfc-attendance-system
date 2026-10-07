# Smart NFC Attendance System (Multi-College & Multi-Role)

[![Flutter](https://img.shields.io/badge/Flutter-3.47+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Functions%20%7C%20Firestore-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![ESP32](https://img.shields.io/badge/Hardware-ESP32%20%2B%20MFRC522-E7352C?logo=espressif&logoColor=white)](https://espressif.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

An enterprise-grade, edge-to-cloud campus attendance ecosystem designed for engineering colleges and universities.

```
+-------------------------------------------------------------+
|                          Classroom                          |
|  [Student NFC Card] ---> [ESP32 + MFRC522 Edge Reader]     |
|                              | (HTTPS + LittleFS Queue)     |
+------------------------------|------------------------------+
                               v
+-------------------------------------------------------------+
|                     Firebase Cloud Backend                  |
|  - Cloud Functions (recordScan, heartbeat, leave/OD, risk)  |
|  - Multi-tenant Firestore (orgs/{orgId})                    |
|  - Gemini AI Assistant (Tamil + English tool-calling)       |
+-------------------------------------------------------------+
                               v
+-------------------------------------------------------------+
|             Flutter Multi-Role Client Application           |
|  - Student Portal (Radial gauge, calendar, leave, chatbot)  |
|  - Faculty Portal (Live scan stream, marks entry)           |
|  - Advisor Portal (Leave/OD approvals, student risk tags)   |
|  - HOD Console (Condonations, anomaly feeds, analytics)     |
|  - Admin Console (NFC enrollment, device status, settings)  |
|  - Emergency Tap to Scan (Protected by Admin Access Code)   |
+-------------------------------------------------------------+
```

---

## 📲 Download Android App

You can download the pre-compiled Android release APK directly:
👉 **[Download NFC Attendance v1.0.0 APK](https://github.com/AJforge-dev/nfc-attendance-system/releases/latest/download/NFC_Attendance_v1.0.0.apk)**

---

## 🌟 Key Features

### 1. Hardware Edge Reader (ESP32 + MFRC522)
- **POSIX NTP Timestamping**: Synchronizes accurate epoch timestamps with fallback servers.
- **LittleFS Flash Queue**: When campus WiFi drops, scans are safely retained on SPIFFS/LittleFS flash and automatically synchronized when connectivity is restored.
- **60-Second Hardware Health Heartbeats**: Reports WiFi RSSI, free heap, uptime, and offline queue depth.
- **Acoustic & LED Feedback**:
  - Green LED + Double beep: Present
  - Yellow LED + Single tone: Late arrival (> 10m)
  - Red LED + Error tone: Duplicate tap or unregistered tag
  - Blue LED: WiFi / flash queue sync activity

### 2. Core Attendance Rule Engine
- **Present**: Scanned within 10 minutes of session start.
- **Late**: Scanned after 10 minutes of session start.
- **Late Conversion**: Every 3 late arrivals count as 1 absence!
- **Excused**: Approved Leave / OD removes the session from the total count (`attended / (total - excused) * 100`).
- **Absent**: No valid scan and unexcused.

### 3. Multi-Role Portals
- **Student Portal**:
  - Light theme by default with simplified, modern layout.
  - Dedicated **Right-Side Category Panel** for 1-tap access:
    - 📊 Attendance Overview (Animated radial gauge score, attended/late/total metrics)
    - 📝 Apply Leave / On-Duty (OD)
    - 📅 Monthly Attendance Checks (Interactive calendar heatmap + day-by-day scan inspection)
    - 📚 Subject-wise Attendance Breakdown
    - 🤖 Campus AI Assistant (Bilingual English + தமிழ் chat)
    - ⚠️ Condonation Appeal (Appears automatically when attendance < 75%)
  - Student authentication with Register Number + Password & email OTP password reset.
- **Faculty Portal**: Live class session reader feed, manual attendance overrides, internal marks entry.
- **Advisor Portal**: Review and approve/reject Leave & OD, monitor student academic risk (Low, Medium, High).
- **HOD Console**: Approve/reject low-attendance Condonation requests, inspect attached medical certificates, security anomaly feed.
- **Admin Console**: Student/Staff enrollment, NFC tag pairing, ESP32 device registry, college policy thresholds, and **Emergency Access Code generator**.
- **Emergency "Tap to Scan" Button**:
  - 76×76 square-shaped button reserved for emergency manual roll-calls.
  - Protected by a 4-digit **Admin Access Code** managed via the Admin Console.

---

## 📁 Repository Structure

```
├── attendance_app/               # Flutter Multi-Role Client Application
│   ├── lib/
│   │   ├── models/               # User, AttendanceRecord, Session, Leave, Mark models
│   │   ├── providers/            # AttendanceProvider, ThemeProvider state management
│   │   ├── screens/              # Student, Faculty, Advisor, HOD, Admin & Auth screens
│   │   ├── theme/                # Light Theme default & Dark Theme configuration
│   │   └── widgets/              # Radial gauge, Calendar view, Emergency tap dialog
│   └── test/                     # 13 automated unit & widget tests
├── firmware/                     # ESP32 C++ Arduino Edge Firmware
│   └── esp32_nfc_attendance/     # MFRC522 driver, LittleFS offline queue, NTP sync
├── functions/                    # Firebase Cloud Functions (TypeScript)
│   └── src/                      # recordScan, deviceHeartbeat, chatbot, risk model
├── firestore.rules               # Multi-tenant security rules (orgs/{orgId})
├── firestore.indexes.json        # Compound indexes for high-speed queries
└── scripts/                      # Sample seed dataset for testing
```

---

## 🚀 Getting Started

### 1. Flutter Mobile App

#### Prerequisites
- Flutter SDK (v3.24+ recommended)
- Android Studio / Xcode

#### Run the App
```bash
cd attendance_app
flutter pub get
flutter run
```

#### Run Automated Tests
```bash
flutter test
```

#### Build Release APK
```bash
flutter build apk --release
# Output: attendance_app/build/app/outputs/flutter-apk/app-release.apk
```

---

### 2. ESP32 Hardware Reader Setup

#### Pinout Configuration (ESP32 to MFRC522)
| MFRC522 Pin | ESP32 GPIO | Description |
|---|---|---|
| SDA / SS | GPIO 5 | SPI Chip Select |
| SCK | GPIO 18 | SPI Clock |
| MOSI | GPIO 23 | SPI Master Out Slave In |
| MISO | GPIO 19 | SPI Master In Slave Out |
| RST | GPIO 22 | Reset |
| 3.3V | 3.3V | Power Supply (Do NOT use 5V) |
| GND | GND | Ground |

Open `firmware/esp32_nfc_attendance/esp32_nfc_attendance.ino` in Arduino IDE or PlatformIO, set your WiFi SSID, password, and Firebase Cloud Function endpoint, and flash to your ESP32 board.

---

### 3. Firebase Backend Deployment

```bash
cd functions
npm install
npm run build
firebase deploy --only functions,firestore:rules,firestore:indexes
```

---

## 🛡️ License

This project is licensed under the MIT License.
