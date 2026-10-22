import 'package:flutter/material.dart';
import '../models/buddy_expression.dart';

class VoiceInputBar extends StatefulWidget {
  final TextEditingController controller;
  final bool isListening;
  final bool isLoading;
  final BuddyMode currentMode;
  final VoidCallback onSend;
  final VoidCallback onToggleListen;
  final Function(String prompt) onSelectPrompt;

  const VoiceInputBar({
    super.key,
    required this.controller,
    required this.isListening,
    required this.isLoading,
    required this.currentMode,
    required this.onSend,
    required this.onToggleListen,
    required this.onSelectPrompt,
  });

  @override
  State<VoiceInputBar> createState() => _VoiceInputBarState();
}

class _VoiceInputBarState extends State<VoiceInputBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _micPulseController;

  @override
  void initState() {
    super.initState();
    _micPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _micPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.trim().isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final barBg = isDark ? const Color(0xFF0F1420) : Colors.white;
    final borderTopColor = isDark ? const Color(0xFF1E2838) : const Color(0xFFE2E8F0);
    final inputBg = isDark ? const Color(0xFF161F2E) : const Color(0xFFF8FAFC);
    final inputBorderColor = widget.isListening
        ? const Color(0xFFFF4081)
        : (isDark ? const Color(0xFF28354A) : const Color(0xFFCBD5E1));

    final themeAccent = widget.currentMode == BuddyMode.study
        ? (isDark ? const Color(0xFF00E5FF) : const Color(0xFF2563EB))
        : (isDark ? const Color(0xFFFF4081) : const Color(0xFFE11D48));

    return Container(
      decoration: BoxDecoration(
        color: barBg,
        border: Border(top: BorderSide(color: borderTopColor, width: 1)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Suggestion Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: widget.currentMode == BuddyMode.friend
                    ? [
                        _buildChip("ESP8266 Pinout Guide 🔌", "What is the complete pinout of ESP8266 NodeMCU?", isDark, themeAccent),
                        _buildChip("How was your day? 😊", "How was your day buddy?", isDark, themeAccent),
                        _buildChip("Tell me a joke 🎭", "Tell me a funny programmer joke!", isDark, themeAccent),
                        _buildChip("Connect ESP8266 to WiFi 🌐", "How do I connect ESP8266 to my home WiFi network?", isDark, themeAccent),
                        _buildChip("Motivate me! ⚡", "Give me some energy and motivation!", isDark, themeAccent),
                      ]
                    : [
                        _buildChip("Explain Binary Search Tree 🌳", "Explain Binary Search Tree and draw it", isDark, themeAccent),
                        _buildChip("Graph Dijkstra Algorithm 🕸️", "Explain Graph theory and Dijkstra shortest path", isDark, themeAccent),
                        _buildChip("Compare Big-O Complexity 📊", "Compare Big O algorithm time complexity", isDark, themeAccent),
                        _buildChip("ESP8266 Web Server Code 🤖", "Write an ESP8266WebServer code with REST endpoints", isDark, themeAccent),
                        _buildChip("How System Pipeline Works ⚡", "Explain the system execution pipeline", isDark, themeAccent),
                      ],
              ),
            ),

            // Input Row
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Row(
                children: [
                  // Text Field
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: inputBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: inputBorderColor,
                          width: 1.3,
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextField(
                              controller: widget.controller,
                              enabled: !widget.isLoading,
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontSize: 14,
                              ),
                              maxLines: 4,
                              minLines: 1,
                              decoration: InputDecoration(
                                hintText: widget.isListening
                                    ? "Listening to your voice... 🎙️"
                                    : widget.currentMode == BuddyMode.friend
                                        ? "Ask anything like ChatGPT..."
                                        : "Ask study question / algorithm...",
                                hintStyle: TextStyle(
                                  color: widget.isListening
                                      ? const Color(0xFFFF80AB)
                                      : (isDark ? Colors.grey : const Color(0xFF94A3B8)),
                                  fontSize: 13,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onSubmitted: (_) {
                                if (hasText && !widget.isLoading) {
                                  widget.onSend();
                                }
                              },
                            ),
                          ),
                          if (hasText)
                            IconButton(
                              icon: Icon(
                                Icons.clear,
                                size: 18,
                                color: isDark ? Colors.grey : const Color(0xFF94A3B8),
                              ),
                              onPressed: () {
                                widget.controller.clear();
                                setState(() {});
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Mic / Send Button
                  AnimatedBuilder(
                    animation: _micPulseController,
                    builder: (context, child) {
                      return GestureDetector(
                        onTap: widget.isLoading
                            ? null
                            : (hasText ? widget.onSend : widget.onToggleListen),
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: widget.isListening
                                  ? [const Color(0xFFFF1744), const Color(0xFFFF4081)]
                                  : hasText
                                      ? (widget.currentMode == BuddyMode.study
                                          ? [const Color(0xFF00E5FF), const Color(0xFF2563EB)]
                                          : [const Color(0xFFFF4081), const Color(0xFF9333EA)])
                                      : (isDark
                                          ? [const Color(0xFF233045), const Color(0xFF1A2232)]
                                          : [const Color(0xFFE2E8F0), const Color(0xFFCBD5E1)]),
                            ),
                            border: Border.all(
                              color: widget.isListening
                                  ? Colors.white
                                  : (hasText ? themeAccent : Colors.transparent),
                              width: 1.5,
                            ),
                            boxShadow: [
                              if (widget.isListening)
                                BoxShadow(
                                  color: const Color(0xFFFF1744).withOpacity(0.6),
                                  blurRadius: 10 + (_micPulseController.value * 6),
                                  spreadRadius: 2,
                                )
                              else if (hasText)
                                BoxShadow(
                                  color: themeAccent.withOpacity(0.35),
                                  blurRadius: 8,
                                ),
                            ],
                          ),
                          child: Center(
                            child: widget.isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    hasText
                                        ? Icons.send_rounded
                                        : (widget.isListening
                                            ? Icons.mic
                                            : Icons.mic_none_rounded),
                                    color: (hasText || widget.isListening || isDark)
                                        ? Colors.white
                                        : const Color(0xFF475569),
                                    size: 21,
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, String prompt, bool isDark, Color themeAccent) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        backgroundColor: isDark ? const Color(0xFF1A2333) : const Color(0xFFF1F5F9),
        side: BorderSide(
          color: isDark ? themeAccent.withOpacity(0.3) : const Color(0xFFE2E8F0),
        ),
        label: Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF334155),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        onPressed: () => widget.onSelectPrompt(prompt),
      ),
    );
  }
}
