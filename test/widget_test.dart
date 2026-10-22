import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:desk_buddy/main.dart';
import 'package:desk_buddy/models/buddy_expression.dart';
import 'package:desk_buddy/models/esp32_config.dart';
import 'package:desk_buddy/services/ai_fallback_brain.dart';
import 'package:desk_buddy/services/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Desk Buddy app smoke test and theme toggle', (WidgetTester tester) async {
    await tester.pumpWidget(const DeskBuddyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Title and ESP8266 Device Name
    expect(find.text('DESK BUDDY'), findsOneWidget);
    expect(find.text('ESP8266'), findsWidgets);

    // Initial theme should be dark
    expect(ThemeController.instance.isDark, true);

    // Find and tap theme switch button (Sun icon in dark mode)
    final themeToggleFinder = find.byTooltip('Switch to White Theme');
    expect(themeToggleFinder, findsOneWidget);
    await tester.tap(themeToggleFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // Verify theme changed to light (white theme)
    expect(ThemeController.instance.isDark, false);
    expect(find.byTooltip('Switch to Dark Theme'), findsOneWidget);

    // Switch back to dark theme
    await tester.tap(find.byTooltip('Switch to Dark Theme'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(ThemeController.instance.isDark, true);
  });

  test('ESP8266 Config serialization & defaults test', () {
    final config = Esp32Config();
    expect(config.deviceName, 'ESP8266');
    expect(config.host, '192.168.4.1');
    expect(config.port, 80);
    expect(config.chatUrl, 'http://192.168.4.1:80/chat');

    final json = config.toJson();
    final restored = Esp32Config.fromJson(json);
    expect(restored.deviceName, 'ESP8266');
    expect(restored.host, '192.168.4.1');
  });

  test('AI Brain ChatGPT-style response test for ESP8266 & Study', () {
    final espResp = AiFallbackBrain.processQuery(
      prompt: "What is the ESP8266 pinout?",
      mode: BuddyMode.friend,
    );
    expect(espResp.text.contains("ESP8266"), true);
    expect(espResp.text.contains("GPIO"), true);

    final bstResp = AiFallbackBrain.processQuery(
      prompt: "Explain Binary Search Tree",
      mode: BuddyMode.study,
    );
    expect(bstResp.text.contains("Binary Search Tree"), true);
    expect(bstResp.visualization, isNotNull);
  });
}
