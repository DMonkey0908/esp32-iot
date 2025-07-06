#include <WiFi.h>
#include <WebSocketsServer.h>
#include <EEPROM.h>

#define EEPROM_SIZE 100
#define SSID_ADDR 0
#define PASS_ADDR 50

WebSocketsServer webSocket = WebSocketsServer(81);

String receivedSSID = "";
String receivedPASS = "";

bool wifiConfigured = false;

void saveWiFiCredentials(const String& ssid, const String& password) {
  EEPROM.writeString(SSID_ADDR, ssid);
  EEPROM.writeString(PASS_ADDR, password);
  EEPROM.commit();
}

void loadWiFiCredentials(String& ssid, String& password) {
  ssid = EEPROM.readString(SSID_ADDR);
  password = EEPROM.readString(PASS_ADDR);
}

void handleWebSocketMessage(uint8_t num, uint8_t * payload, size_t length) {
  String data = String((char*)payload).substring(0, length);
  int separatorIndex = data.indexOf(';');
  if (separatorIndex != -1) {
    receivedSSID = data.substring(0, separatorIndex);
    receivedPASS = data.substring(separatorIndex + 1);

    Serial.println("Received SSID: " + receivedSSID);
    Serial.println("Received PASS: " + receivedPASS);

    saveWiFiCredentials(receivedSSID, receivedPASS);

    webSocket.sendTXT(num, "Credentials received. Restarting...");
    delay(1000);
    ESP.restart();
  } else {
    webSocket.sendTXT(num, "Invalid format. Use SSID;PASSWORD");
  }
}

void startAPMode() {
  WiFi.softAP("ESP32_Config", "12345678");
  IPAddress IP = WiFi.softAPIP();
  Serial.print("AP IP address: ");
  Serial.println(IP);

  webSocket.begin();
  webSocket.onEvent([](uint8_t num, WStype_t type, uint8_t * payload, size_t length) {
    if (type == WStype_TEXT) {
      handleWebSocketMessage(num, payload, length);
    }
  });

  Serial.println("WebSocket server started.");
}

void connectToWiFi() {
  String ssid, password;
  loadWiFiCredentials(ssid, password);

  Serial.println("Connecting to WiFi: " + ssid);
  WiFi.begin(ssid.c_str(), password.c_str());

  int retry = 0;
  while (WiFi.status() != WL_CONNECTED && retry < 20) {
    delay(500);
    Serial.print(".");
    retry++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nConnected! IP: " + WiFi.localIP().toString());
  } else {
    Serial.println("\nFailed to connect. Restarting in AP mode...");
    delay(2000);
    startAPMode();
  }
}

void setup() {
  Serial.begin(115200);
  EEPROM.begin(EEPROM_SIZE);

  String ssid, pass;
  loadWiFiCredentials(ssid, pass);

  if (ssid.length() == 0 || pass.length() == 0) {
    Serial.println("No saved WiFi credentials. Starting in AP mode...");
    startAPMode();
  } else {
    connectToWiFi();
  }
}

void loop() {
  if (WiFi.getMode() == WIFI_AP) {
    webSocket.loop();
  }
}
