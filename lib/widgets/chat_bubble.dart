import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/buddy_expression.dart';
import '../models/chat_message.dart';
import '../models/visualization_data.dart';
import 'visualizers/chart_visualizer.dart';
import 'visualizers/flow_visualizer.dart';
import 'visualizers/graph_visualizer.dart';
import 'visualizers/tree_visualizer.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final Function(String text)? onSpeak;
  final bool isSpeaking;

  const ChatBubble({
    super.key,
    required this.message,
    this.onSpeak,
    this.isSpeaking = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final themeColor = message.mode == BuddyMode.study
        ? (isDark ? const Color(0xFF00E5FF) : const Color(0xFF2563EB))
        : (isDark ? const Color(0xFFFF4081) : const Color(0xFFE11D48));

    // Colors
    final userBubbleColor = isDark ? const Color(0xFF2563EB) : const Color(0xFF2563EB);
    final botBubbleColor = isDark ? const Color(0xFF161F2E) : Colors.white;
    final botBorderColor = isDark ? const Color(0xFF232E43) : const Color(0xFFE2E8F0);
    final textColor = isUser
        ? Colors.white
        : (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                // Assistant / ESP8266 Avatar Icon
                Container(
                  width: 34,
                  height: 34,
                  margin: const EdgeInsets.only(right: 10, top: 2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: message.mode == BuddyMode.study
                          ? [const Color(0xFF00E5FF), const Color(0xFF2563EB)]
                          : [const Color(0xFFFF4081), const Color(0xFF9333EA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: themeColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    message.mode == BuddyMode.study
                        ? Icons.psychology_rounded
                        : Icons.smart_toy_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
              ],

              // Message Body
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.82,
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                  decoration: BoxDecoration(
                    color: isUser ? userBubbleColor : botBubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    border: Border.all(
                      color: isUser ? const Color(0xFF3B82F6) : botBorderColor,
                      width: 1.1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withOpacity(0.25)
                            : Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Assistant Badge (ChatGPT / ESP8266)
                      if (!isUser) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF0D121D)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white12
                                      : const Color(0xFFCBD5E1),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    size: 10,
                                    color: message.mode == BuddyMode.study
                                        ? const Color(0xFF00E5FF)
                                        : const Color(0xFFFF4081),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    message.esp32ResponseInfo ?? "ChatGPT AI",
                                    style: TextStyle(
                                      color: isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF475569),
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Text Content (Markdown for Assistant, Text for User)
                      if (isUser)
                        Text(
                          message.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            height: 1.4,
                            fontWeight: FontWeight.w400,
                          ),
                        )
                      else
                        MarkdownBody(
                          data: message.text,
                          selectable: true,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(
                              color: textColor,
                              fontSize: 14.2,
                              height: 1.5,
                            ),
                            h1: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            h2: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            h3: TextStyle(
                              color: isDark
                                  ? const Color(0xFF00E5FF)
                                  : const Color(0xFF2563EB),
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                            ),
                            strong: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontWeight: FontWeight.w700,
                            ),
                            code: TextStyle(
                              color: isDark
                                  ? const Color(0xFF38BDF8)
                                  : const Color(0xFF0284C7),
                              backgroundColor: isDark
                                  ? const Color(0xFF0D121D)
                                  : const Color(0xFFF1F5F9),
                              fontSize: 12.5,
                              fontFamily: 'monospace',
                            ),
                            codeblockDecoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF0B0F17)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF1E2838)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            tableBody: TextStyle(
                              color: textColor,
                              fontSize: 12.5,
                            ),
                            tableHead: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            tableBorder: TableBorder.all(
                              color: isDark
                                  ? const Color(0xFF2A364F)
                                  : const Color(0xFFCBD5E1),
                              width: 0.8,
                            ),
                            blockquote: TextStyle(
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                              fontStyle: FontStyle.italic,
                              fontSize: 13.5,
                            ),
                            blockquoteDecoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF131A29)
                                  : const Color(0xFFF1F5F9),
                              border: Border(
                                left: BorderSide(
                                  color: message.mode == BuddyMode.study
                                      ? const Color(0xFF00E5FF)
                                      : const Color(0xFFFF4081),
                                  width: 3.5,
                                ),
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),

                      // Embedded Visualizations
                      if (message.visualization != null) ...[
                        const SizedBox(height: 12),
                        _buildVisualization(message.visualization!),
                      ],

                      // Action Toolbar (Audio, Copy, Timestamp)
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (!isUser) ...[
                            // Speak Button
                            InkWell(
                              onTap: () => onSpeak?.call(message.text),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Icon(
                                  isSpeaking
                                      ? Icons.volume_up_rounded
                                      : Icons.volume_mute_rounded,
                                  size: 16,
                                  color: isSpeaking
                                      ? (isDark
                                          ? const Color(0xFF00E5FF)
                                          : const Color(0xFF2563EB))
                                      : (isDark ? Colors.grey : const Color(0xFF94A3B8)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],

                          // Copy Button
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: message.text));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Copied response to clipboard"),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.copy_rounded,
                                size: 14,
                                color: isUser
                                    ? Colors.white70
                                    : (isDark ? Colors.grey : const Color(0xFF94A3B8)),
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Timestamp
                          Text(
                            "${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}",
                            style: TextStyle(
                              color: isUser
                                  ? Colors.white70
                                  : (isDark
                                      ? Colors.grey.withOpacity(0.6)
                                      : const Color(0xFF94A3B8)),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              if (isUser) ...[
                // User Avatar Icon
                Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.only(left: 8, top: 2),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2563EB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: Colors.white, size: 18),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVisualization(VisualizationData viz) {
    switch (viz.type) {
      case VisualizationType.tree:
        if (viz.treeRoot == null) return const SizedBox.shrink();
        return TreeVisualizer(
          root: viz.treeRoot!,
          title: viz.title,
          subtitle: viz.subtitle,
        );

      case VisualizationType.graph:
        if (viz.graphNodes == null || viz.graphEdges == null) {
          return const SizedBox.shrink();
        }
        return GraphVisualizer(
          nodes: viz.graphNodes!,
          edges: viz.graphEdges!,
          title: viz.title,
          subtitle: viz.subtitle,
        );

      case VisualizationType.chart:
        if (viz.chartPoints == null) return const SizedBox.shrink();
        return ChartVisualizer(
          points: viz.chartPoints!,
          title: viz.title,
          subtitle: viz.subtitle,
          chartType: viz.chartType ?? 'bar',
        );

      case VisualizationType.flow:
        if (viz.flowSteps == null) return const SizedBox.shrink();
        return FlowVisualizer(
          steps: viz.flowSteps!,
          title: viz.title,
          subtitle: viz.subtitle,
        );
    }
  }
}
