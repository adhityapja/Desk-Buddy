import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/buddy_expression.dart';
import '../models/chat_message.dart';
import '../models/esp32_config.dart';
import '../services/esp32_service.dart';
import '../services/speech_service.dart';
import '../services/theme_controller.dart';
import '../services/tts_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/esp32_settings_dialog.dart';
import '../widgets/esp_connection_bar.dart';
import '../widgets/voice_input_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Services
  late Esp32Config _esp32Config;
  late Esp32Service _esp32Service;
  final TtsService _ttsService = TtsService();
  final SpeechService _speechService = SpeechService();

  // State
  BuddyMode _currentMode = BuddyMode.friend;
  BuddyExpression _currentExpression = BuddyExpression.happy;
  String _hardwareStatus = "Checking device...";
  bool _isEspOnline = false;
  int? _espLatencyMs;
  bool _isCheckingConnection = false;
  bool _isLoading = false;
  bool _isSpeaking = false;
  bool _isListening = false;

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _esp32Config = Esp32Config();
    _esp32Service = Esp32Service(config: _esp32Config);

    _initServices();
    _loadSettingsAndHistory();
    _setupHeartbeat();
  }

  @override
  void dispose() {
    _esp32Service.stopHeartbeat();
    _ttsService.dispose();
    _speechService.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupHeartbeat() {
    _esp32Service.onStatusChanged = (isOnline, latency) {
      if (mounted) {
        final wasOnline = _isEspOnline;
        setState(() {
          _isEspOnline = isOnline;
          _espLatencyMs = latency;
          _hardwareStatus = isOnline
              ? "${_esp32Config.deviceName} Online (${latency ?? 0}ms)"
              : "${_esp32Config.deviceName} Offline";
        });

        if (!wasOnline && isOnline) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.bolt, color: Colors.yellowAccent, size: 20),
                  const SizedBox(width: 8),
                  Text("⚡ ${_esp32Config.deviceName} is online! Ready to chat."),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    };
    _esp32Service.startHeartbeat();
  }

  Future<void> _checkConnection() async {
    setState(() => _isCheckingConnection = true);
    final res = await _esp32Service.testConnection();
    if (mounted) {
      setState(() {
        _isCheckingConnection = false;
        _isEspOnline = res['online'] == true;
        _espLatencyMs = res['latencyMs'];
        _hardwareStatus = res['message'];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']),
          backgroundColor: res['online'] == true ? const Color(0xFF10B981) : Colors.orange,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _initServices() async {
    await _ttsService.init();
    _ttsService.onPlayingChanged = (playing) {
      if (mounted) {
        setState(() {
          _isSpeaking = playing;
          if (playing) {
            _currentExpression = BuddyExpression.talking;
          } else {
            _currentExpression = _currentMode == BuddyMode.study
                ? BuddyExpression.studyFocused
                : BuddyExpression.happy;
          }
        });
      }
    };

    await _speechService.init();
    _speechService.onListeningStateChanged = (listening) {
      if (mounted) {
        setState(() {
          _isListening = listening;
          if (listening) {
            _currentExpression = BuddyExpression.listening;
          } else {
            _currentExpression = _currentMode == BuddyMode.study
                ? BuddyExpression.studyFocused
                : BuddyExpression.happy;
          }
        });
      }
    };
  }

  Future<void> _loadSettingsAndHistory() async {
    final prefs = await SharedPreferences.getInstance();

    // Load config
    final configStr = prefs.getString('esp32_config');
    if (configStr != null) {
      try {
        _esp32Config = Esp32Config.fromJson(jsonDecode(configStr));
        _esp32Service.config = _esp32Config;
      } catch (_) {}
    }

    // Load messages
    final msgsStr = prefs.getString('chat_history');
    if (msgsStr != null) {
      try {
        final List<dynamic> list = jsonDecode(msgsStr);
        final loaded = list.map((m) => ChatMessage.fromJson(m)).toList();
        if (loaded.isNotEmpty) {
          setState(() {
            _messages.addAll(loaded);
          });
          _scrollToBottom();
          _checkConnection();
          return;
        }
      } catch (_) {}
    }

    // Default welcome messages
    _addInitialWelcomeMessages();
    _checkConnection();
  }

  void _addInitialWelcomeMessages() {
    final welcome = ChatMessage(
      id: 'welcome_1',
      text: "👋 **Welcome to Desk Buddy & ${_esp32Config.deviceName}!**\n\n"
          "When your **${_esp32Config.deviceName}** is online, connect with it right here. You can ask me anything just like **ChatGPT**!\n\n"
          "- 💬 **Friend Mode:** Natural conversation, advice, jokes, and companionship.\n"
          "- 🧠 **Study Mode:** Detailed algorithmic breakdowns with **interactive visualizations** (BSTs, Graphs, Big-O Charts, Pipelines).\n"
          "- 🌓 **Switchable Themes:** Tap the Sun ☀️ / Moon 🌙 icon in the header to switch between Dark and White theme anytime!\n\n"
          "Tap **Connect** in the device bar above to link to your ${_esp32Config.deviceName}!",
      isUser: false,
      timestamp: DateTime.now(),
      mode: BuddyMode.friend,
      expression: BuddyExpression.excited,
      esp32ResponseInfo: "${_esp32Config.deviceName} ChatGPT AI",
    );

    setState(() {
      _messages.add(welcome);
    });
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _messages.take(40).map((m) => m.toJson()).toList();
    prefs.setString('chat_history', jsonEncode(jsonList));
  }

  Future<void> _saveConfig(Esp32Config newConfig) async {
    setState(() {
      _esp32Config = newConfig;
      _esp32Service.config = newConfig;
      _hardwareStatus = "Target: ${newConfig.host}:${newConfig.port}";
    });
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('esp32_config', jsonEncode(newConfig.toJson()));
    _checkConnection();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _switchMode(BuddyMode mode) {
    setState(() {
      _currentMode = mode;
      _currentExpression = mode == BuddyMode.study
          ? BuddyExpression.studyFocused
          : BuddyExpression.happy;
    });

    final promptNotice = mode == BuddyMode.study
        ? "Switched to **Study Buddy Mode** 🧠! Ask me about algorithms, data structures (BSTs, graphs), or concepts to see visualizations!"
        : "Switched to **Close Friend Mode** 💖! What's up buddy? How can I brighten your desk today?";

    final modeMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: promptNotice,
      isUser: false,
      timestamp: DateTime.now(),
      mode: mode,
      expression: _currentExpression,
    );

    setState(() {
      _messages.add(modeMsg);
    });
    _saveHistory();
    _scrollToBottom();
  }

  Future<void> _sendMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty) return;

    _textController.clear();

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: query,
      isUser: true,
      timestamp: DateTime.now(),
      mode: _currentMode,
    );

    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
      _currentExpression = BuddyExpression.thinking;
    });
    _scrollToBottom();

    try {
      final response = await _esp32Service.sendQuery(
        query: query,
        mode: _currentMode,
      );

      final buddyMsg = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        text: response.text,
        isUser: false,
        timestamp: DateTime.now(),
        mode: _currentMode,
        expression: response.expression,
        visualization: response.visualization,
        esp32ResponseInfo: response.statusInfo,
      );

      setState(() {
        _messages.add(buddyMsg);
        _isLoading = false;
        _currentExpression = response.expression;
        _isEspOnline = _esp32Service.isOnline;
        _hardwareStatus = response.statusInfo;
      });

      _saveHistory();
      _scrollToBottom();

      // Trigger Auto-TTS if enabled
      if (_esp32Config.autoTts) {
        _ttsService.speak(response.text);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _currentExpression = BuddyExpression.happy;
      });
    }
  }

  void _toggleListening() async {
    if (_isListening) {
      await _speechService.stop();
    } else {
      await _speechService.startListening(
        onResult: (text) {
          setState(() {
            _textController.text = text;
          });
        },
      );
    }
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Esp32SettingsDialog(
        initialConfig: _esp32Config,
        esp32Service: _esp32Service,
        onSave: _saveConfig,
      ),
    );
  }

  void _clearChat() {
    final isDark = ThemeController.instance.isDark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E2433) : Colors.white,
        title: Text(
          "Clear Chat History?",
          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
        ),
        content: Text(
          "Are you sure you want to clear your conversation history?",
          style: TextStyle(color: isDark ? Colors.grey : const Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              "Cancel",
              style: TextStyle(color: isDark ? Colors.grey : const Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('chat_history');
              setState(() {
                _messages.clear();
              });
              _addInitialWelcomeMessages();
            },
            child: const Text("Clear", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final themeColor = _currentMode == BuddyMode.study
        ? (isDark ? const Color(0xFF00E5FF) : const Color(0xFF2563EB))
        : (isDark ? const Color(0xFFFF4081) : const Color(0xFFE11D48));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // Robot Icon
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _currentMode == BuddyMode.study
                      ? [const Color(0xFF00E5FF), const Color(0xFF2563EB)]
                      : [const Color(0xFFFF4081), const Color(0xFF9333EA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "DESK BUDDY",
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: themeColor.withOpacity(isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "AI",
                        style: TextStyle(
                          color: themeColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  _esp32Config.deviceName,
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Theme Switcher Toggle Button (Dark / White)
          IconButton(
            tooltip: isDark ? "Switch to White Theme" : "Switch to Dark Theme",
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => RotationTransition(turns: anim, child: child),
              child: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                key: ValueKey<bool>(isDark),
                color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF1E293B),
                size: 22,
              ),
            ),
            onPressed: () {
              ThemeController.instance.toggleTheme();
            },
          ),

          // Hardware Settings Icon
          IconButton(
            tooltip: "${_esp32Config.deviceName} Settings",
            icon: Icon(
              Icons.settings_input_component_rounded,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
              size: 22,
            ),
            onPressed: _showSettings,
          ),

          // Clear Chat Icon
          IconButton(
            tooltip: "Clear Chat",
            icon: Icon(
              Icons.delete_outline_rounded,
              color: isDark ? Colors.grey : const Color(0xFF94A3B8),
              size: 20,
            ),
            onPressed: _clearChat,
          ),
        ],
      ),
      body: Column(
        children: [
          // Live ESP8266 Connection Bar
          EspConnectionBar(
            config: _esp32Config,
            isOnline: _isEspOnline,
            latencyMs: _espLatencyMs,
            isChecking: _isCheckingConnection,
            currentMode: _currentMode,
            onConnectTap: _checkConnection,
            onSettingsTap: _showSettings,
            onModeToggle: () => _switchMode(
              _currentMode == BuddyMode.friend ? BuddyMode.study : BuddyMode.friend,
            ),
          ),

          // Chat Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return ChatBubble(
                  message: msg,
                  isSpeaking: _isSpeaking,
                  onSpeak: (text) => _ttsService.speak(text),
                );
              },
            ),
          ),

          // Loading Typing Indicator
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: themeColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "${_esp32Config.deviceName} & ChatGPT is thinking...",
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          // Voice & Text Input Bar
          VoiceInputBar(
            controller: _textController,
            isListening: _isListening,
            isLoading: _isLoading,
            currentMode: _currentMode,
            onSend: () => _sendMessage(_textController.text),
            onToggleListen: _toggleListening,
            onSelectPrompt: (p) => _sendMessage(p),
          ),
        ],
      ),
    );
  }
}
