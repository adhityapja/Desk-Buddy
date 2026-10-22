import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/buddy_expression.dart';
import '../models/esp32_config.dart';
import '../services/esp32_service.dart';

class Esp32SettingsDialog extends StatefulWidget {
  final Esp32Config initialConfig;
  final Function(Esp32Config newConfig) onSave;
  final Esp32Service esp32Service;

  const Esp32SettingsDialog({
    super.key,
    required this.initialConfig,
    required this.onSave,
    required this.esp32Service,
  });

  @override
  State<Esp32SettingsDialog> createState() => _Esp32SettingsDialogState();
}

class _Esp32SettingsDialogState extends State<Esp32SettingsDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _hostController;
  late TextEditingController _portController;
  late TextEditingController _chatEndpointController;
  late TextEditingController _reactionEndpointController;
  late TextEditingController _apiKeyController;
  late Esp32OperationMode _operationMode;
  late String _deviceName;
  late String _aiProvider;
  late bool _autoTts;

  bool _isTesting = false;
  bool _isScanning = false;
  String? _testResult;
  bool? _testSuccess;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _deviceName = widget.initialConfig.deviceName;
    _hostController = TextEditingController(text: widget.initialConfig.host);
    _portController = TextEditingController(text: widget.initialConfig.port.toString());
    _chatEndpointController =
        TextEditingController(text: widget.initialConfig.chatEndpoint);
    _reactionEndpointController =
        TextEditingController(text: widget.initialConfig.reactionEndpoint);
    _apiKeyController = TextEditingController(text: widget.initialConfig.apiKey);
    _operationMode = widget.initialConfig.operationMode;
    _aiProvider = widget.initialConfig.aiProvider;
    _autoTts = widget.initialConfig.autoTts;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _chatEndpointController.dispose();
    _reactionEndpointController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _runConnectionTest() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
      _testSuccess = null;
    });

    final tempConfig = widget.initialConfig.copyWith(
      deviceName: _deviceName,
      host: _hostController.text.trim(),
      port: int.tryParse(_portController.text.trim()) ?? 80,
    );
    final testService = Esp32Service(config: tempConfig);
    final res = await testService.testConnection();

    if (mounted) {
      setState(() {
        _isTesting = false;
        _testSuccess = res['online'] == true;
        _testResult = res['message'];
      });
    }
  }

  Future<void> _scanSubnet() async {
    setState(() {
      _isScanning = true;
      _testResult = "Scanning local subnet for $_deviceName...";
      _testSuccess = null;
    });

    final testService = widget.esp32Service;
    final foundIp = await testService.scanForDevice();

    if (mounted) {
      setState(() {
        _isScanning = false;
        if (foundIp != null) {
          _hostController.text = foundIp;
          _testSuccess = true;
          _testResult = "Found $_deviceName at $foundIp!";
        } else {
          _testSuccess = false;
          _testResult = "No $_deviceName discovered automatically. Try entering IP manually.";
        }
      });
    }
  }

  Future<void> _sendTestReaction(BuddyExpression expr) async {
    final tempConfig = widget.initialConfig.copyWith(
      host: _hostController.text.trim(),
      port: int.tryParse(_portController.text.trim()) ?? 80,
    );
    final testService = Esp32Service(config: tempConfig);
    final ok = await testService.sendReactionToHardware(expr);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok
              ? "Dispatched ${expr.name} reaction to $_deviceName!"
              : "$_deviceName unreachable (check WiFi connection)"),
          backgroundColor: ok ? const Color(0xFF10B981) : Colors.redAccent,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _saveSettings() {
    final newConfig = widget.initialConfig.copyWith(
      deviceName: _deviceName,
      host: _hostController.text.trim().isEmpty ? '192.168.4.1' : _hostController.text.trim(),
      port: int.tryParse(_portController.text.trim()) ?? 80,
      chatEndpoint: _chatEndpointController.text.trim(),
      reactionEndpoint: _reactionEndpointController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
      aiProvider: _aiProvider,
      operationMode: _operationMode,
      autoTts: _autoTts,
    );
    widget.onSave(newConfig);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF141A28) : Colors.white;
    final primaryColor = isDark ? const Color(0xFF00E5FF) : const Color(0xFF2563EB);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? Colors.grey[400] : const Color(0xFF64748B);
    final cardBg = isDark ? const Color(0xFF1B2335) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 20,
        right: 20,
        top: 16,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.memory_rounded, color: primaryColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$_deviceName & Hardware Settings",
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "Connect your microcontroller & configure ChatGPT brain",
                      style: TextStyle(color: subtextColor, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: primaryColor,
            unselectedLabelColor: subtextColor,
            indicatorColor: primaryColor,
            tabs: const [
              Tab(text: "Connection"),
              Tab(text: "ChatGPT & AI"),
              Tab(text: "Arduino Code"),
            ],
          ),
          const SizedBox(height: 10),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildConnectionTab(isDark, cardBg, borderColor, primaryColor, textColor, subtextColor),
                _buildAiTab(isDark, cardBg, borderColor, primaryColor, textColor, subtextColor),
                _buildArduinoCodeTab(isDark, cardBg, borderColor, primaryColor, textColor, subtextColor),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Save Button
          ElevatedButton(
            onPressed: _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: isDark ? Colors.black : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.save_rounded, size: 18),
                SizedBox(width: 8),
                Text("Save & Apply Settings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionTab(
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color primaryColor,
    Color textColor,
    Color? subtextColor,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Device Selection
          Row(
            children: [
              _buildDeviceChoice("ESP8266 (Recommended)", "ESP8266", isDark, primaryColor),
              const SizedBox(width: 10),
              _buildDeviceChoice("ESP32", "ESP32", isDark, primaryColor),
            ],
          ),
          const SizedBox(height: 12),

          // IP Presets
          Text("Quick IP Presets:", style: TextStyle(color: subtextColor, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildPresetChip("SoftAP (192.168.4.1)", "192.168.4.1", isDark),
              _buildPresetChip("Home WiFi (192.168.1.45)", "192.168.1.45", isDark),
              _buildPresetChip("Local (esp8266.local)", "esp8266.local", isDark),
            ],
          ),
          const SizedBox(height: 14),

          // Host & Port Row
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _hostController,
                  style: TextStyle(color: textColor, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: "$_deviceName IP Address / Hostname",
                    labelStyle: TextStyle(color: subtextColor, fontSize: 12),
                    filled: true,
                    fillColor: cardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _portController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: textColor, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: "Port",
                    labelStyle: TextStyle(color: subtextColor, fontSize: 12),
                    filled: true,
                    fillColor: cardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Action Buttons: Ping & Subnet Scan
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isTesting ? null : _runConnectionTest,
                  icon: _isTesting
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.wifi_tethering_rounded, size: 16),
                  label: Text(_isTesting ? "Testing..." : "Test Ping", style: const TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isScanning ? null : _scanSubnet,
                  icon: _isScanning
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.radar_rounded, size: 16),
                  label: Text(_isScanning ? "Scanning..." : "Auto-Scan Subnet", style: const TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF10B981),
                    side: const BorderSide(color: Color(0xFF10B981)),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),

          // Test Feedback Banner
          if (_testResult != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _testSuccess == true
                    ? const Color(0xFF10B981).withOpacity(0.15)
                    : Colors.redAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _testSuccess == true ? const Color(0xFF10B981) : Colors.redAccent,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _testSuccess == true ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                    color: _testSuccess == true ? const Color(0xFF10B981) : Colors.redAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _testResult!,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Test Reaction to Hardware
          Text("Dispatch Test Face / OLED Reaction:", style: TextStyle(color: subtextColor, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildReactionTestBtn("Happy 😊", BuddyExpression.happy, primaryColor),
                _buildReactionTestBtn("Excited ⚡", BuddyExpression.excited, primaryColor),
                _buildReactionTestBtn("Study 🧠", BuddyExpression.studyFocused, primaryColor),
                _buildReactionTestBtn("Cool 😎", BuddyExpression.cool, primaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiTab(
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color primaryColor,
    Color textColor,
    Color? subtextColor,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Operation Mode
          Text("Operating Architecture:", style: TextStyle(color: subtextColor, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          _buildModeOption(
            title: "Direct $_deviceName Endpoint",
            desc: "Forwards prompts directly to http://${_hostController.text}/chat",
            mode: Esp32OperationMode.directEndpoint,
            isDark: isDark,
            primaryColor: primaryColor,
          ),
          const SizedBox(height: 8),

          _buildModeOption(
            title: "Companion Sync Mode",
            desc: "App generates intelligent ChatGPT answers & syncs reactions to $_deviceName",
            mode: Esp32OperationMode.companionSync,
            isDark: isDark,
            primaryColor: primaryColor,
          ),
          const SizedBox(height: 8),

          _buildModeOption(
            title: "Virtual Simulator Mode",
            desc: "Runs completely offline inside app (useful when hardware is turned off)",
            mode: Esp32OperationMode.simulatorMode,
            isDark: isDark,
            primaryColor: primaryColor,
          ),
          const SizedBox(height: 16),

          // Optional Cloud AI API Key
          Text("AI Brain Engine:", style: TextStyle(color: subtextColor, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          Row(
            children: [
              _buildAiChoice("Built-in ChatGPT Brain", "builtin", isDark, primaryColor),
              const SizedBox(width: 8),
              _buildAiChoice("OpenAI API", "openai", isDark, primaryColor),
            ],
          ),
          const SizedBox(height: 10),

          if (_aiProvider == 'openai') ...[
            TextField(
              controller: _apiKeyController,
              obscureText: true,
              style: TextStyle(color: textColor, fontSize: 13),
              decoration: InputDecoration(
                labelText: "OpenAI API Key (sk-...)",
                labelStyle: TextStyle(color: subtextColor, fontSize: 12),
                hintText: "Enter your OpenAI key for GPT-4o-mini",
                filled: true,
                fillColor: cardBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Auto TTS Voice toggle
          SwitchListTile(
            value: _autoTts,
            onChanged: (val) => setState(() => _autoTts = val),
            title: Text("Auto-Speak Voice Replies", style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: Text("Read ChatGPT and study answers aloud using TTS", style: TextStyle(color: subtextColor, fontSize: 11)),
            activeColor: primaryColor,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildArduinoCodeTab(
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color primaryColor,
    Color textColor,
    Color? subtextColor,
  ) {
    const arduinoSketch = '''#include <ESP8266WiFi.h>
#include <ESP8266WebServer.h>
#include <ArduinoJson.h>

// WiFi Configuration
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

ESP8266WebServer server(80);

void setup() {
  Serial.begin(115200);
  delay(100);

  // Connect to WiFi
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("\\nWiFi Connected!");
  Serial.print("ESP8266 IP Address: ");
  Serial.println(WiFi.localIP());

  // 1. Health Status endpoint
  server.on("/status", HTTP_GET, []() {
    server.send(200, "application/json", "{\\"status\\":\\"online\\",\\"device\\":\\"ESP8266\\"}");
  });

  // 2. Reaction Sync endpoint (App tells ESP8266 what face/OLED to show)
  server.on("/reaction", HTTP_POST, []() {
    if (server.hasArg("plain")) {
      StaticJsonDocument<256> doc;
      deserializeJson(doc, server.arg("plain"));
      const char* expr = doc["expression"];
      const char* text = doc["text"];
      Serial.printf("Face Expression: %s\\n", expr);
      if (text) Serial.printf("Preview Text: %s\\n", text);
      // Trigger your OLED screen or Servo movement here!
    }
    server.send(200, "application/json", "{\\"success\\":true}");
  });

  // 3. Direct AI Chat endpoint
  server.on("/chat", HTTP_POST, []() {
    server.send(200, "application/json",
      "{\\"response\\":\\"Hello from your online ESP8266 robot!\\",\\"expression\\":\\"HAPPY\\"}");
  });

  server.begin();
  Serial.println("HTTP Server Started!");
}

void loop() {
  server.handleClient();
}''';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Flashable ESP8266 Arduino Code:",
              style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(const ClipboardData(text: arduinoSketch));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Arduino Code copied to clipboard!"), duration: Duration(seconds: 2)),
                );
              },
              icon: Icon(Icons.copy_rounded, size: 14, color: primaryColor),
              label: Text("Copy Code", style: TextStyle(color: primaryColor, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0D121D) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: SingleChildScrollView(
              child: Text(
                arduinoSketch,
                style: TextStyle(
                  color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0F172A),
                  fontFamily: 'monospace',
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceChoice(String label, String value, bool isDark, Color primaryColor) {
    final isSelected = _deviceName == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _deviceName = value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor.withOpacity(0.15) : (isDark ? const Color(0xFF1B2335) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? primaryColor : Colors.transparent, width: 1.5),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? primaryColor : (isDark ? Colors.grey[300] : const Color(0xFF475569)),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, String ip, bool isDark) {
    return InkWell(
      onTap: () => setState(() => _hostController.text = ip),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF222B3F) : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white70 : const Color(0xFF334155),
            fontSize: 10.5,
          ),
        ),
      ),
    );
  }

  Widget _buildReactionTestBtn(String label, BuddyExpression expr, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: OutlinedButton(
        onPressed: () => _sendTestReaction(expr),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          side: BorderSide(color: primaryColor.withOpacity(0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 11)),
      ),
    );
  }

  Widget _buildModeOption({
    required String title,
    required String desc,
    required Esp32OperationMode mode,
    required bool isDark,
    required Color primaryColor,
  }) {
    final isSelected = _operationMode == mode;
    return InkWell(
      onTap: () => setState(() => _operationMode = mode),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withOpacity(0.12)
              : (isDark ? const Color(0xFF1B2335) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : (isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? primaryColor : Colors.grey,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiChoice(String label, String value, bool isDark, Color primaryColor) {
    final isSelected = _aiProvider == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _aiProvider = value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor.withOpacity(0.15) : (isDark ? const Color(0xFF1B2335) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? primaryColor : Colors.transparent, width: 1.5),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? primaryColor : (isDark ? Colors.grey[300] : const Color(0xFF475569)),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 11.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
