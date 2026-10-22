import 'buddy_expression.dart';
import 'visualization_data.dart';

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final BuddyMode mode;
  final BuddyExpression? expression;
  final VisualizationData? visualization;
  final String? esp32ResponseInfo;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    required this.mode,
    this.expression,
    this.visualization,
    this.esp32ResponseInfo,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      text: json['text'] ?? '',
      isUser: json['isUser'] == true,
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      mode: json['mode'] == 'study' ? BuddyMode.study : BuddyMode.friend,
      expression: json['expression'] != null
          ? BuddyExpression.values.firstWhere(
              (e) => e.name == json['expression'],
              orElse: () => BuddyExpression.happy,
            )
          : null,
      visualization: json['visualization'] != null
          ? VisualizationData.fromJson(
              Map<String, dynamic>.from(json['visualization']))
          : null,
      esp32ResponseInfo: json['esp32ResponseInfo'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'isUser': isUser,
        'timestamp': timestamp.toIso8601String(),
        'mode': mode.name,
        if (expression != null) 'expression': expression!.name,
        if (visualization != null) 'visualization': visualization!.toJson(),
        if (esp32ResponseInfo != null) 'esp32ResponseInfo': esp32ResponseInfo,
      };
}
