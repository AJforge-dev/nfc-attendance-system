/*
 * NFC Attendance System - ESP32 Edge Reader Firmware
 * 
 * Hardware:
 *   - ESP32 NodeMCU / DevKit v1
 *   - MFRC522 RFID / NFC Reader (13.56 MHz SPI)
 *   - Status LEDs:
 *       - Green LED: Present
 *       - Yellow LED: Late
 *       - Red LED: Error / Unknown Card / Duplicate
 *       - Blue LED: WiFi / LittleFS Queue Sync
 *   - Piezo Buzzer (Audio feedback)
 * 
 * Features:
 *   - Reads 4-byte / 7-byte NFC UID (ISO 14443A)
 *   - NTP Timestamp synchronization (preserves true tap time)
 *   - LittleFS Flash Storage: Offline scan queue when network is unavailable
 *   - Auto-retry every 15 seconds to drain offline scans with original timestamps
 *   - Periodic 60s Heartbeat to cloud with WiFi RSSI & queue stats
 *   - HTTPS POST to Firebase Cloud Function with device bearer authentication
 */

#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include <SPI.h>
#include <MFRC522.h>
#include <LittleFS.h>
#include <ArduinoJson.h>
#include <time.h>

// ======================== CONFIGURATION ========================
const char* WIFI_SSID     = "CAMPUS_WIFI";
const char* WIFI_PASSWORD = "CampusPassword123";

// Firebase Cloud Function Endpoints
const char* RECORD_SCAN_URL = "https://us-central1-nfc-attendance-prod.cloudfunctions.net/recordScan";
const char* HEARTBEAT_URL   = "https://us-central1-nfc-attendance-prod.cloudfunctions.net/deviceHeartbeat";

// Device Identification & Security Token
const char* DEVICE_ID       = "ESP32_ROOM_302";
const char* DEVICE_TOKEN    = "dvt_live_9a8b7c6d5e4f3a2b1c";

// Pinout Definitions (Standard ESP32 VSPI)
#define PIN_RC522_SS    5
#define PIN_RC522_RST   22
#define PIN_LED_GREEN   12   // Present
#define PIN_LED_YELLOW  14   // Late
#define PIN_LED_RED     27   // Error / Duplicate / Unknown
#define PIN_LED_BLUE    26   // WiFi / Syncing
#define PIN_BUZZER      25   // Piezo Buzzer

// NTP Settings
const char* NTP_SERVER_1 = "pool.ntp.org";
const char* NTP_SERVER_2 = "time.google.com";
const long  GMT_OFFSET_SEC = 19800; // IST: GMT+5:30 (5 * 3600 + 30 * 60)
const int   DAYLIGHT_OFFSET_SEC = 0;

// Flash Queue File
const char* QUEUE_FILE_PATH = "/offline_queue.jsonl";
const unsigned long RETRY_INTERVAL_MS   = 15000; // 15 seconds
const unsigned long HEARTBEAT_INTERVAL_MS = 60000; // 60 seconds

// ======================== GLOBAL OBJECTS ========================
MFRC522 mfrc522(PIN_RC522_SS, PIN_RC522_RST);
unsigned long lastRetryTime = 0;
unsigned long lastHeartbeatTime = 0;
unsigned long lastTapTime = 0;
String lastScannedUid = "";

// ======================== HARDWARE HELPERS ========================
void beep(int durationMs, int frequency = 2000) {
  tone(PIN_BUZZER, frequency, durationMs);
  delay(durationMs);
  noTone(PIN_BUZZER);
}

void indicatePresent() {
  digitalWrite(PIN_LED_GREEN, HIGH);
  beep(100, 2500);
  delay(50);
  beep(100, 3000);
  delay(500);
  digitalWrite(PIN_LED_GREEN, LOW);
}

void indicateLate() {
  digitalWrite(PIN_LED_YELLOW, HIGH);
  beep(250, 1800);
  delay(500);
  digitalWrite(PIN_LED_YELLOW, LOW);
}

void indicateError() {
  digitalWrite(PIN_LED_RED, HIGH);
  beep(400, 800);
  delay(100);
  beep(400, 800);
  delay(300);
  digitalWrite(PIN_LED_RED, LOW);
}

void indicateQueued() {
  digitalWrite(PIN_LED_BLUE, HIGH);
  beep(150, 1500);
  delay(100);
  digitalWrite(PIN_LED_BLUE, LOW);
}

// ======================== TIME SYNCHRONIZATION ========================
void initNTP() {
  configTime(GMT_OFFSET_SEC, DAYLIGHT_OFFSET_SEC, NTP_SERVER_1, NTP_SERVER_2);
  struct tm timeinfo;
  int retry = 0;
  Serial.print("[NTP] Synchronizing time");
  while (!getLocalTime(&timeinfo) && retry < 10) {
    delay(500);
    Serial.print(".");
    retry++;
  }
  if (retry < 10) {
    Serial.println("\n[NTP] Time synchronized successfully.");
  } else {
    Serial.println("\n[NTP] Warning: Initial NTP sync timed out. Will retry.");
  }
}

unsigned long getCurrentEpoch() {
  time_t now;
  time(&now);
  return (unsigned long)now;
}

// ======================== LITTLEFS OFFLINE QUEUE ========================
void initStorage() {
  if (!LittleFS.begin(true)) {
    Serial.println("[LittleFS] Storage Mount Failed!");
    indicateError();
  } else {
    Serial.println("[LittleFS] Storage Mounted Successfully.");
  }
}

int getOfflineQueueCount() {
  if (!LittleFS.exists(QUEUE_FILE_PATH)) return 0;
  File f = LittleFS.open(QUEUE_FILE_PATH, "r");
  if (!f) return 0;
  int count = 0;
  while (f.available()) {
    String line = f.readStringUntil('\n');
    if (line.length() > 5) count++;
  }
  f.close();
  return count;
}

void queueOfflineScan(const String& tagUid, unsigned long timestamp) {
  File f = LittleFS.open(QUEUE_FILE_PATH, "a");
  if (!f) {
    Serial.println("[LittleFS] Error opening queue file for write!");
    return;
  }
  StaticJsonDocument<256> doc;
  doc["tagUid"]    = tagUid;
  doc["deviceId"]  = DEVICE_ID;
  doc["timestamp"] = timestamp;
  doc["token"]     = DEVICE_TOKEN;
  
  String serialized;
  serializeJson(doc, serialized);
  f.println(serialized);
  f.close();
  
  Serial.printf("[LittleFS] Offline scan queued: UID=%s, Timestamp=%lu\n", tagUid.c_str(), timestamp);
  indicateQueued();
}

// ======================== NETWORK & CLOUD POST ========================
int sendScanPayload(const String& jsonPayload, String& responseBody) {
  if (WiFi.status() != WL_CONNECTED) {
    return -1; // Network unavailable
  }

  WiFiClientSecure client;
  client.setInsecure(); // In production, provide root CA cert fingerprint
  HTTPClient https;

  if (!https.begin(client, RECORD_SCAN_URL)) {
    return -2;
  }

  https.addHeader("Content-Type", "application/json");
  https.addHeader("Authorization", String("Bearer ") + DEVICE_TOKEN);
  https.setTimeout(6000);

  int httpCode = https.POST(jsonPayload);
  if (httpCode > 0) {
    responseBody = https.getString();
  }
  https.end();
  return httpCode;
}

void drainOfflineQueue() {
  if (WiFi.status() != WL_CONNECTED) return;
  if (!LittleFS.exists(QUEUE_FILE_PATH)) return;

  File f = LittleFS.open(QUEUE_FILE_PATH, "r");
  if (!f || f.size() == 0) {
    if (f) f.close();
    LittleFS.remove(QUEUE_FILE_PATH);
    return;
  }

  digitalWrite(PIN_LED_BLUE, HIGH);
  Serial.println("[Queue] Draining offline scans...");

  String tempFilePath = "/queue_temp.jsonl";
  File tempFile = LittleFS.open(tempFilePath, "w");

  while (f.available()) {
    String line = f.readStringUntil('\n');
    line.trim();
    if (line.length() < 10) continue;

    String responseBody;
    int code = sendScanPayload(line, responseBody);

    if (code == 200 || code == 409) {
      // 200: Successfully synced; 409: Already recorded previously
      Serial.printf("[Queue] Successfully processed queued scan (HTTP %d)\n", code);
    } else {
      // Still failed (network glitch or server 500) -> preserve in temp file
      Serial.printf("[Queue] Failed to sync line (HTTP %d), retaining for next retry\n", code);
      if (tempFile) tempFile.println(line);
    }
  }

  f.close();
  if (tempFile) tempFile.close();

  LittleFS.remove(QUEUE_FILE_PATH);
  if (LittleFS.exists(tempFilePath)) {
    File checkTemp = LittleFS.open(tempFilePath, "r");
    if (checkTemp && checkTemp.size() > 0) {
      checkTemp.close();
      LittleFS.rename(tempFilePath, QUEUE_FILE_PATH);
    } else {
      if (checkTemp) checkTemp.close();
      LittleFS.remove(tempFilePath);
    }
  }

  digitalWrite(PIN_LED_BLUE, LOW);
}

void sendHeartbeat() {
  if (WiFi.status() != WL_CONNECTED) return;

  WiFiClientSecure client;
  client.setInsecure();
  HTTPClient https;

  if (https.begin(client, HEARTBEAT_URL)) {
    https.addHeader("Content-Type", "application/json");
    https.addHeader("Authorization", String("Bearer ") + DEVICE_TOKEN);
    https.setTimeout(4000);

    StaticJsonDocument<256> doc;
    doc["deviceId"]   = DEVICE_ID;
    doc["token"]      = DEVICE_TOKEN;
    doc["rssi"]        = WiFi.RSSI();
    doc["queueSize"]   = getOfflineQueueCount();
    doc["uptimeSec"]   = millis() / 1000;
    doc["freeHeap"]    = ESP.getFreeHeap();

    String payload;
    serializeJson(doc, payload);

    int httpCode = https.POST(payload);
    Serial.printf("[Heartbeat] Code: %d, RSSI: %d dBm, Queue: %d\n", httpCode, WiFi.RSSI(), doc["queueSize"].as<int>());
    https.end();
  }
}

// ======================== SCAN PROCESSOR ========================
void processCardScan(const String& tagUid) {
  unsigned long now = getCurrentEpoch();
  Serial.printf("\n[Scan] Detected Tag UID: %s at Epoch: %lu\n", tagUid.c_str(), now);

  // If WiFi is disconnected, queue immediately to LittleFS
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("[Scan] Offline: Storing scan to flash queue");
    queueOfflineScan(tagUid, now);
    return;
  }

  // Build JSON payload
  StaticJsonDocument<256> doc;
  doc["tagUid"]    = tagUid;
  doc["deviceId"]  = DEVICE_ID;
  doc["timestamp"] = now;
  doc["token"]     = DEVICE_TOKEN;

  String payload;
  serializeJson(doc, payload);

  String responseBody;
  int httpCode = sendScanPayload(payload, responseBody);

  Serial.printf("[Scan] Cloud HTTP Response: %d\n", httpCode);
  if (httpCode > 0) {
    Serial.printf("[Scan] Response: %s\n", responseBody.c_str());
  }

  if (httpCode == 200) {
    // Check if response indicates present or late
    StaticJsonDocument<256> respDoc;
    DeserializationError err = deserializeJson(respDoc, responseBody);
    if (!err) {
      const char* status = respDoc["status"] | "present";
      if (strcmp(status, "late") == 0) {
        Serial.println("[Scan] Result: LATE");
        indicateLate();
      } else {
        Serial.println("[Scan] Result: PRESENT");
        indicatePresent();
      }
    } else {
      indicatePresent();
    }
  } else if (httpCode == 409) {
    Serial.println("[Scan] Result: DUPLICATE (Already marked)");
    indicateError();
  } else if (httpCode == 404 || httpCode == 422) {
    Serial.println("[Scan] Result: UNKNOWN TAG OR NO ACTIVE SESSION");
    indicateError();
  } else {
    // Network glitch or timeout: Save to LittleFS queue for safe replay
    Serial.println("[Scan] Cloud unreachable, caching to LittleFS flash queue");
    queueOfflineScan(tagUid, now);
  }
}

// ======================== SETUP & LOOP ========================
void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n=== NFC Attendance System ESP32 Edge Reader ===");

  // Setup GPIO pins
  pinMode(PIN_LED_GREEN, OUTPUT);
  pinMode(PIN_LED_YELLOW, OUTPUT);
  pinMode(PIN_LED_RED, OUTPUT);
  pinMode(PIN_LED_BLUE, OUTPUT);
  pinMode(PIN_BUZZER, OUTPUT);

  digitalWrite(PIN_LED_GREEN, LOW);
  digitalWrite(PIN_LED_YELLOW, LOW);
  digitalWrite(PIN_LED_RED, LOW);
  digitalWrite(PIN_LED_BLUE, LOW);

  // Initialize Storage
  initStorage();

  // Initialize SPI & MFRC522
  SPI.begin();
  mfrc522.PCD_Init();
  mfrc522.PCD_DumpVersionToSerial();
  Serial.println("[MFRC522] Ready for RFID/NFC cards.");

  // Connect to WiFi
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.printf("[WiFi] Connecting to %s", WIFI_SSID);

  int wifiTries = 0;
  while (WiFi.status() != WL_CONNECTED && wifiTries < 20) {
    digitalWrite(PIN_LED_BLUE, !digitalRead(PIN_LED_BLUE));
    delay(500);
    Serial.print(".");
    wifiTries++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    digitalWrite(PIN_LED_BLUE, HIGH);
    Serial.printf("\n[WiFi] Connected! IP: %s\n", WiFi.localIP().toString().c_str());
    initNTP();
    delay(500);
    digitalWrite(PIN_LED_BLUE, LOW);
  } else {
    digitalWrite(PIN_LED_BLUE, LOW);
    Serial.println("\n[WiFi] Could not connect. Starting in OFFLINE mode.");
  }

  // Initial startup beep
  beep(100, 2000);
  delay(80);
  beep(100, 2500);
}

void loop() {
  unsigned long currentMillis = millis();

  // 1. Maintain WiFi connection in background
  if (WiFi.status() != WL_CONNECTED && (currentMillis % 10000 == 0)) {
    WiFi.reconnect();
  }

  // 2. Retry draining offline queue every 15s
  if (currentMillis - lastRetryTime >= RETRY_INTERVAL_MS) {
    lastRetryTime = currentMillis;
    if (WiFi.status() == WL_CONNECTED && getOfflineQueueCount() > 0) {
      drainOfflineQueue();
    }
  }

  // 3. Send heartbeat every 60s
  if (currentMillis - lastHeartbeatTime >= HEARTBEAT_INTERVAL_MS) {
    lastHeartbeatTime = currentMillis;
    sendHeartbeat();
  }

  // 4. Poll for NFC / RFID Cards
  if (!mfrc522.PICC_IsNewCardPresent() || !mfrc522.PICC_ReadCardSerial()) {
    return;
  }

  // Extract UID as Hex String (e.g. "4A 7B 12 C9" -> "4A7B12C9")
  String uidStr = "";
  for (byte i = 0; i < mfrc522.uid.size; i++) {
    if (mfrc522.uid.uidByte[i] < 0x10) uidStr += "0";
    uidStr += String(mfrc522.uid.uidByte[i], HEX);
  }
  uidStr.toUpperCase();

  // Debounce consecutive scans of same tag within 3 seconds
  if (uidStr == lastScannedUid && (currentMillis - lastTapTime < 3000)) {
    mfrc522.PICC_HaltA();
    mfrc522.PCD_StopCrypto1();
    return;
  }

  lastScannedUid = uidStr;
  lastTapTime = currentMillis;

  processCardScan(uidStr);

  mfrc522.PICC_HaltA();
  mfrc522.PCD_StopCrypto1();
}
