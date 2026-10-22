enum Esp32OperationMode {
  directEndpoint, // Forward user prompts directly to ESP8266/ESP32 /chat endpoint
  companionSync, // App runs smart brain/cloud AI and syncs status & expressions to ESP
  simulatorMode, // Purely on-device simulation mode (when ESP is offline or testing)
}

class Esp32Config {
  final String deviceName; // "ESP8266" or "ESP32"
  final String host;
  final int port;
  final String chatEndpoint;
  final String reactionEndpoint;
  final String statusEndpoint;
  final Esp32OperationMode operationMode;
  final bool autoTts;
  final double ttsRate;
  final double ttsPitch;
  final String apiKey;
  final String aiProvider; // 'builtin', 'openai', 'gemini'

  Esp32Config({
    this.deviceName = 'ESP8266',
    this.host = '192.168.4.1',
    this.port = 80,
    this.chatEndpoint = '/chat',
    this.reactionEndpoint = '/reaction',
    this.statusEndpoint = '/status',
    this.operationMode = Esp32OperationMode.directEndpoint,
    this.autoTts = true,
    this.ttsRate = 0.5,
    this.ttsPitch = 1.1,
    this.apiKey = '',
    this.aiProvider = 'builtin',
  });

  String get baseUri {
    final cleanHost = host.trim().replaceAll(RegExp(r'^https?:\/\/'), '').replaceAll(RegExp(r'\/.*$'), '');
    return 'http://$cleanHost:$port';
  }

  String get chatUrl => '$baseUri$chatEndpoint';
  String get reactionUrl => '$baseUri$reactionEndpoint';
  String get statusUrl => '$baseUri$statusEndpoint';

  Esp32Config copyWith({
    String? deviceName,
    String? host,
    int? port,
    String? chatEndpoint,
    String? reactionEndpoint,
    String? statusEndpoint,
    Esp32OperationMode? operationMode,
    bool? autoTts,
    double? ttsRate,
    double? ttsPitch,
    String? apiKey,
    String? aiProvider,
  }) {
    return Esp32Config(
      deviceName: deviceName ?? this.deviceName,
      host: host ?? this.host,
      port: port ?? this.port,
      chatEndpoint: chatEndpoint ?? this.chatEndpoint,
      reactionEndpoint: reactionEndpoint ?? this.reactionEndpoint,
      statusEndpoint: statusEndpoint ?? this.statusEndpoint,
      operationMode: operationMode ?? this.operationMode,
      autoTts: autoTts ?? this.autoTts,
      ttsRate: ttsRate ?? this.ttsRate,
      ttsPitch: ttsPitch ?? this.ttsPitch,
      apiKey: apiKey ?? this.apiKey,
      aiProvider: aiProvider ?? this.aiProvider,
    );
  }

  Map<String, dynamic> toJson() => {
        'deviceName': deviceName,
        'host': host,
        'port': port,
        'chatEndpoint': chatEndpoint,
        'reactionEndpoint': reactionEndpoint,
        'statusEndpoint': statusEndpoint,
        'operationMode': operationMode.name,
        'autoTts': autoTts,
        'ttsRate': ttsRate,
        'ttsPitch': ttsPitch,
        'apiKey': apiKey,
        'aiProvider': aiProvider,
      };

  factory Esp32Config.fromJson(Map<String, dynamic> json) {
    return Esp32Config(
      deviceName: json['deviceName'] ?? 'ESP8266',
      host: json['host'] ?? '192.168.4.1',
      port: (json['port'] as num?)?.toInt() ?? 80,
      chatEndpoint: json['chatEndpoint'] ?? '/chat',
      reactionEndpoint: json['reactionEndpoint'] ?? '/reaction',
      statusEndpoint: json['statusEndpoint'] ?? '/status',
      operationMode: Esp32OperationMode.values.firstWhere(
        (m) => m.name == json['operationMode'],
        orElse: () => Esp32OperationMode.directEndpoint,
      ),
      autoTts: json['autoTts'] ?? true,
      ttsRate: (json['ttsRate'] as num?)?.toDouble() ?? 0.5,
      ttsPitch: (json['ttsPitch'] as num?)?.toDouble() ?? 1.1,
      apiKey: json['apiKey'] ?? '',
      aiProvider: json['aiProvider'] ?? 'builtin',
    );
  }
}
