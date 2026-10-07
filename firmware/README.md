# ESP32 + MFRC522 NFC Edge Reader

This module runs on an ESP32 microcontroller paired with an MFRC522 (13.56 MHz) RFID/NFC reader. It captures student ID taps, verifies connectivity, and securely pushes scans to the Firebase Cloud backend.

---

## Hardware Pinout & Wiring

| MFRC522 Pin | ESP32 Pin (VSPI) | Description |
|---|---|---|
| **3.3V** | 3V3 | Power (Do NOT connect to 5V!) |
| **RST** | GPIO 22 | Reset pin |
| **GND** | GND | Ground |
| **IRQ** | Not Connected | Interrupt (Unused) |
| **MISO** | GPIO 19 | SPI Master-In Slave-Out |
| **MOSI** | GPIO 23 | SPI Master-Out Slave-In |
| **SCK** | GPIO 18 | SPI Clock |
| **SDA (SS)** | GPIO 5 | SPI Chip Select |

### Status Indicators & Feedback
| Component | ESP32 Pin | Meaning |
|---|---|---|
| **Green LED** | GPIO 12 | Attendance Marked: **Present** (Double beep) |
| **Yellow LED** | GPIO 14 | Attendance Marked: **Late** (Single long tone) |
| **Red LED** | GPIO 27 | Error / Unregistered Card / Duplicate Scan |
| **Blue LED** | GPIO 26 | WiFi Activity / LittleFS Offline Queue Sync |
| **Piezo Buzzer** | GPIO 25 | Audible feedback for swipe events |

---

## Key Firmware Features

1. **True Timestamping (NTP)**:
   - Synchronizes time via `pool.ntp.org` and `time.google.com` (configurable GMT offset, e.g., IST GMT+5:30).
   - Even when offline, the internal RTC preserves the exact second the student tapped their card.

2. **LittleFS Offline Queue**:
   - If WiFi drops or cloud endpoint is unreachable, scans are safely written to `/offline_queue.jsonl` in flash memory.
   - When network connectivity is restored, the ESP32 automatically replays queued scans every 15 seconds preserving the original tap timestamp.

3. **Cloud Heartbeat**:
   - Pings `/deviceHeartbeat` every 60 seconds with WiFi signal strength (RSSI), queue depth, free heap, and uptime so administrators can monitor classroom readers in real time.

4. **Security**:
   - Secure HTTPS client with bearer token matching the device registry in Firestore (`devices/{deviceId}`).

---

## Flashing Instructions (Arduino IDE / PlatformIO)

1. **Install Board**: In Arduino IDE Boards Manager, install `esp32` by Espressif Systems.
2. **Install Libraries**:
   - `MFRC522` by GithubCommunity
   - `ArduinoJson` (v6.x or v7.x) by Benoit Blanchon
   - `LittleFS_esp32` (built-in with ESP32 core >= 2.0.0)
3. **Partition Scheme**: Select **Default with LittleFS** or **Minimal SPIFFS (Large APPS with OTA)**.
4. **Configure**:
   - Set `WIFI_SSID` and `WIFI_PASSWORD`.
   - Set `RECORD_SCAN_URL` and `HEARTBEAT_URL` to your deployed Firebase Cloud Function URLs.
   - Set `DEVICE_ID` and `DEVICE_TOKEN`.
5. Connect ESP32 via Micro-USB/USB-C and click **Upload**.
