import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/buddy_expression.dart';
import '../models/esp32_config.dart';
import '../models/visualization_data.dart';
import 'ai_fallback_brain.dart';

class Esp32Response {
  final String text;
  final BuddyExpression expression;
  final VisualizationData? visualization;
  final String statusInfo;
  final bool isFromHardware;
  final int? latencyMs;

  Esp32Response({
    required this.text,
    required this.expression,
    this.visualization,
    required this.statusInfo,
    required this.isFromHardware,
    this.latencyMs,
  });
}

class Esp32Service {
  Esp32Config config;
  Timer? _heartbeatTimer;
  Function(bool isOnline, int? latencyMs)? onStatusChanged;
  bool _isCurrentlyOnline = false;

  bool get isOnline => _isCurrentlyOnline;

  Esp32Service({required this.config});

  /// Start periodic heartbeat to monitor ESP8266 online/offline status
  void startHeartbeat({Duration interval = const Duration(seconds: 8)}) {
    stopHeartbeat();
    _checkHeartbeat();
    _heartbeatTimer = Timer.periodic(interval, (_) => _checkHeartbeat());
  }

  void stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<void> _checkHeartbeat() async {
    final res = await testConnection();
    final wasOnline = _isCurrentlyOnline;
    _isCurrentlyOnline = res['online'] == true;
    final latency = res['latencyMs'] as int?;

    if (wasOnline != _isCurrentlyOnline || _isCurrentlyOnline) {
      onStatusChanged?.call(_isCurrentlyOnline, latency);
    }
  }

  /// Ping ESP8266 / ESP32 and measure latency
  Future<Map<String, dynamic>> testConnection() async {
    final stopwatch = Stopwatch()..start();
    try {
      final uri = Uri.parse(config.statusUrl);
      final response = await http.get(uri).timeout(const Duration(seconds: 2));
      stopwatch.stop();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _isCurrentlyOnline = true;
        return {
          'online': true,
          'latencyMs': stopwatch.elapsedMilliseconds,
          'body': response.body,
          'message': '${config.deviceName} Connected (${stopwatch.elapsedMilliseconds}ms)',
        };
      }
    } catch (_) {
      // Fallback: Try base URI ping
      try {
        final base = Uri.parse(config.baseUri);
        final baseRes = await http.get(base).timeout(const Duration(milliseconds: 1500));
        stopwatch.stop();
        if (baseRes.statusCode >= 200 && baseRes.statusCode < 400) {
          _isCurrentlyOnline = true;
          return {
            'online': true,
            'latencyMs': stopwatch.elapsedMilliseconds,
            'body': baseRes.body,
            'message': '${config.deviceName} Connected (${stopwatch.elapsedMilliseconds}ms)',
          };
        }
      } catch (_) {}
    }

    stopwatch.stop();
    _isCurrentlyOnline = false;
    return {
      'online': false,
      'latencyMs': null,
      'message': 'Cannot reach ${config.deviceName} at ${config.baseUri}',
    };
  }

  /// Scan typical local IPs to auto-discover ESP8266
  Future<String?> scanForDevice({String subnetPrefix = '192.168.1'}) async {
    final candidates = [
      '192.168.4.1', // Default SoftAP
      '$subnetPrefix.4',
      '$subnetPrefix.10',
      '$subnetPrefix.15',
      '$subnetPrefix.20',
      '$subnetPrefix.25',
      '$subnetPrefix.30',
      '$subnetPrefix.50',
      '$subnetPrefix.100',
    ];

    for (final ip in candidates) {
      try {
        final uri = Uri.parse('http://$ip:${config.port}${config.statusEndpoint}');
        final res = await http.get(uri).timeout(const Duration(milliseconds: 600));
        if (res.statusCode >= 200 && res.statusCode < 300) {
          return ip;
        }
      } catch (_) {}
    }
    return null;
  }

  /// Send query according to configured mode
  Future<Esp32Response> sendQuery({
    required String query,
    required BuddyMode mode,
  }) async {
    // 1. Direct Endpoint Mode: Forward prompt directly to ESP8266
    if (config.operationMode == Esp32OperationMode.directEndpoint) {
      final stopwatch = Stopwatch()..start();
      try {
        final uri = Uri.parse(config.chatUrl);
        final response = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'message': query,
                'prompt': query,
                'mode': mode.name,
              }),
            )
            .timeout(const Duration(seconds: 6));

        stopwatch.stop();

        if (response.statusCode >= 200 && response.statusCode < 300) {
          _isCurrentlyOnline = true;
          return _parseHardwareResponse(response.body, stopwatch.elapsedMilliseconds);
        }
      } catch (e) {
        stopwatch.stop();
        _isCurrentlyOnline = false;
      }
    }

    // 2. Cloud AI (OpenAI / Gemini) if API Key is configured
    if (config.apiKey.trim().isNotEmpty) {
      final cloudResponse = await _tryCloudAi(query, mode);
      if (cloudResponse != null) {
        // Sync reaction to ESP8266 if possible
        _syncReactionSafely(cloudResponse.expression);
        return cloudResponse;
      }
    }

    // 3. High-Quality Built-in ChatGPT Brain
    final aiResponse = AiFallbackBrain.processQuery(prompt: query, mode: mode);

    // Sync to ESP8266 if in Companion Sync mode or if device is reachable
    String statusNote;
    if (_isCurrentlyOnline || config.operationMode == Esp32OperationMode.companionSync) {
      final synced = await _syncReactionSafely(aiResponse.expression, textPreview: aiResponse.text);
      statusNote = synced
          ? "${config.deviceName} Synced & ChatGPT AI"
          : "${config.deviceName} Offline • ChatGPT AI";
    } else {
      statusNote = "ChatGPT AI Response";
    }

    return Esp32Response(
      text: aiResponse.text,
      expression: aiResponse.expression,
      visualization: aiResponse.visualization,
      statusInfo: statusNote,
      isFromHardware: false,
    );
  }

  /// Safely send reaction to hardware without throwing
  Future<bool> _syncReactionSafely(BuddyExpression expression, {String? textPreview}) async {
    try {
      final uri = Uri.parse(config.reactionUrl);
      final preview = textPreview != null && textPreview.length > 80
          ? textPreview.substring(0, 80)
          : textPreview;

      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'expression': expression.code,
              if (preview != null) 'text': preview,
            }),
          )
          .timeout(const Duration(milliseconds: 1800));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        _isCurrentlyOnline = true;
        return true;
      }
    } catch (_) {
      _isCurrentlyOnline = false;
    }
    return false;
  }

  /// Send immediate reaction trigger to ESP8266 (e.g. test button)
  Future<bool> sendReactionToHardware(BuddyExpression expression) async {
    return _syncReactionSafely(expression);
  }

  /// Cloud AI fallback if user provides their own key
  Future<Esp32Response?> _tryCloudAi(String query, BuddyMode mode) async {
    if (config.aiProvider == 'openai') {
      try {
        final res = await http.post(
          Uri.parse('https://api.openai.com/v1/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${config.apiKey.trim()}',
          },
          body: jsonEncode({
            'model': 'gpt-4o-mini',
            'messages': [
              {
                'role': 'system',
                'content': mode == BuddyMode.friend
                    ? "You are Desk Buddy, a friendly, warm, empathetic robot companion sitting on the user's desk."
                    : "You are Desk Buddy Study Tutor, an expert computer science and technical academic tutor."
              },
              {'role': 'user', 'content': query}
            ],
            'temperature': 0.7,
          }),
        ).timeout(const Duration(seconds: 12));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final text = data['choices'][0]['message']['content'] as String;
          return Esp32Response(
            text: text,
            expression: BuddyExpression.talking,
            statusInfo: "OpenAI GPT-4o-mini (Cloud)",
            isFromHardware: false,
          );
        }
      } catch (_) {}
    }
    return null;
  }

  Esp32Response _parseHardwareResponse(String responseBody, int latencyMs) {
    try {
      final data = jsonDecode(responseBody);
      if (data is Map<String, dynamic>) {
        final text = data['response'] ?? data['reply'] ?? data['text'] ?? responseBody;
        final expressionStr = data['expression']?.toString().toUpperCase();

        BuddyExpression expr = BuddyExpression.talking;
        if (expressionStr != null) {
          expr = BuddyExpression.values.firstWhere(
            (e) => e.code == expressionStr || e.name.toUpperCase() == expressionStr,
            orElse: () => BuddyExpression.talking,
          );
        }

        VisualizationData? viz;
        if (data['visualization'] != null) {
          viz = VisualizationData.fromJson(Map<String, dynamic>.from(data['visualization']));
        }

        return Esp32Response(
          text: text,
          expression: expr,
          visualization: viz,
          statusInfo: "${config.deviceName} Live (${latencyMs}ms)",
          isFromHardware: true,
          latencyMs: latencyMs,
        );
      }
    } catch (_) {}

    return Esp32Response(
      text: responseBody,
      expression: BuddyExpression.talking,
      statusInfo: "${config.deviceName} Text (${latencyMs}ms)",
      isFromHardware: true,
      latencyMs: latencyMs,
    );
  }
}
