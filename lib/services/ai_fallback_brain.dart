import 'dart:math';
import '../models/buddy_expression.dart';
import '../models/visualization_data.dart';

class AiBuddyResponse {
  final String text;
  final BuddyExpression expression;
  final VisualizationData? visualization;

  AiBuddyResponse({
    required this.text,
    required this.expression,
    this.visualization,
  });
}

class AiFallbackBrain {
  static final Random _rng = Random();

  /// Process input based on mode (Friend vs Study) with ChatGPT-grade responses
  static AiBuddyResponse processQuery({
    required String prompt,
    required BuddyMode mode,
  }) {
    final query = prompt.trim().toLowerCase();

    // 1. Check for Study / Technical Visualizations first
    if (mode == BuddyMode.study || _isTechnicalTopic(query)) {
      final vizResponse = _tryGenerateTechnicalVisualization(query, prompt);
      if (vizResponse != null) return vizResponse;
    }

    // 2. Check for ESP8266 & Hardware specific questions
    if (_isEspOrHardwareTopic(query)) {
      return _generateEspHardwareResponse(query, prompt);
    }

    // 3. Check for Coding & Software questions
    if (_isCodingTopic(query)) {
      return _generateCodingResponse(query, prompt);
    }

    // 4. Friend / Conversational questions
    if (mode == BuddyMode.friend && _isCasualConversation(query)) {
      return _generateFriendResponse(query, prompt);
    }

    // 5. General Knowledge & Explanations (ChatGPT style)
    return _generateChatGPTGeneralResponse(prompt);
  }

  // ==========================================
  // TOPIC DETECTORS
  // ==========================================
  static bool _isTechnicalTopic(String q) {
    return q.contains('tree') ||
        q.contains('bst') ||
        q.contains('avl') ||
        q.contains('graph') ||
        q.contains('dijkstra') ||
        q.contains('complexity') ||
        q.contains('big o') ||
        q.contains('pipeline') ||
        q.contains('sort');
  }

  static bool _isEspOrHardwareTopic(String q) {
    return q.contains('esp8266') ||
        q.contains('esp32') ||
        q.contains('nodemcu') ||
        q.contains('arduino') ||
        q.contains('gpio') ||
        q.contains('pinout') ||
        q.contains('sensor') ||
        q.contains('oled') ||
        q.contains('servo') ||
        q.contains('wifi') ||
        q.contains('baud');
  }

  static bool _isCodingTopic(String q) {
    return q.contains('code') ||
        q.contains('python') ||
        q.contains('javascript') ||
        q.contains('dart') ||
        q.contains('flutter') ||
        q.contains('c++') ||
        q.contains('function') ||
        q.contains('class') ||
        q.contains('api') ||
        q.contains('bug') ||
        q.contains('debug');
  }

  static bool _isCasualConversation(String q) {
    return q.contains('hi') ||
        q.contains('hello') ||
        q.contains('hey') ||
        q.contains('how are you') ||
        q.contains('joke') ||
        q.contains('tired') ||
        q.contains('stress') ||
        q.contains('bored') ||
        q.contains('love') ||
        q.contains('motivat');
  }

  // ==========================================
  // 1. ESP8266 & HARDWARE EXPERT RESPONSES
  // ==========================================
  static AiBuddyResponse _generateEspHardwareResponse(String query, String rawPrompt) {
    if (query.contains('pin') || query.contains('pinout') || query.contains('gpio')) {
      return AiBuddyResponse(
        text: "### 🔌 ESP8266 (NodeMCU v2/v3) Complete Pinout Guide\n\n"
            "Here is the standard pin mapping for your ESP8266:\n\n"
            "| NodeMCU Pin | ESP8266 GPIO | Special Features / Hardware Function |\n"
            "|:---:|:---:|:---|\n"
            "| **D0** | GPIO 16 | Wake up from Deep Sleep (connect to RST) |\n"
            "| **D1** | GPIO 5 | **I2C SCL** (OLED, Sensors, RTC) |\n"
            "| **D2** | GPIO 4 | **I2C SDA** (OLED, Sensors, RTC) |\n"
            "| **D3** | GPIO 0 | FLASH button, Bootloader (Pull-up) |\n"
            "| **D4** | GPIO 2 | Onboard LED (Active LOW), TXD1 |\n"
            "| **D5** | GPIO 14 | SPI SCLK (SD card, SPI displays) |\n"
            "| **D6** | GPIO 12 | SPI MISO |\n"
            "| **D7** | GPIO 13 | SPI MOSI, RXD2 |\n"
            "| **D8** | GPIO 15 | Boot pin (Pull-down), SPI SS |\n"
            "| **A0** | ADC0 | Analog Input (0 - 1.0V; built-in divider to 3.3V) |\n\n"
            "> ⚠️ **Important Tip:** Avoid holding **GPIO 0 (D3)** or **GPIO 15 (D8)** in the wrong state during power-up or the ESP8266 will fail to boot into running mode!",
        expression: BuddyExpression.studyFocused,
      );
    }

    if (query.contains('wifi') || query.contains('connect') || query.contains('ip')) {
      return AiBuddyResponse(
        text: "### 🌐 How ESP8266 Connects to WiFi & Our App\n\n"
            "The ESP8266 can operate in two primary WiFi modes:\n\n"
            "1. **Station Mode (STA - Recommended):**\n"
            "   - Connects to your home/office WiFi router.\n"
            "   - Gets a local IP address (e.g. `192.168.1.45`).\n"
            "   - Your phone and ESP8266 must be on the **same 2.4 GHz WiFi network**.\n\n"
            "2. **Soft Access Point Mode (AP):**\n"
            "   - ESP8266 creates its own hotspot (e.g. `DeskBuddy_Robot`).\n"
            "   - Default gateway is usually `192.168.4.1`.\n"
            "   - Great for portable desk use without a home router!\n\n"
            "```cpp\n"
            "// Quick Arduino connection snippet:\n"
            "#include <ESP8266WiFi.h>\n\n"
            "const char* ssid = \"Your_WiFi_Name\";\n"
            "const char* password = \"Your_WiFi_Password\";\n\n"
            "void setup() {\n"
            "  Serial.begin(115200);\n"
            "  WiFi.begin(ssid, password);\n"
            "  while (WiFi.status() != WL_CONNECTED) { delay(500); Serial.print(\".\"); }\n"
            "  Serial.println(\"\\nConnected! IP Address: \");\n"
            "  Serial.println(WiFi.localIP()); // Enter this IP in the app!\n"
            "}\n"
            "```",
        expression: BuddyExpression.excited,
      );
    }

    return AiBuddyResponse(
      text: "### 🤖 ESP8266 Companion Hardware Ready\n\n"
          "Your ESP8266 microcontroller is recognized! When online, our app communicates with it over HTTP REST JSON:\n\n"
          "- **Status Ping:** `GET http://<ESP8266_IP>/status`\n"
          "- **ChatGPT/AI Dialog:** `POST http://<ESP8266_IP>/chat` with `{\"message\":\"...\"}`\n"
          "- **Face & Servo Sync:** `POST http://<ESP8266_IP>/reaction` with `{\"expression\":\"HAPPY\"}`\n\n"
          "Feel free to ask me to write full firmware code, wire up an SSD1306 OLED screen, or debug any hardware issues!",
      expression: BuddyExpression.happy,
    );
  }

  // ==========================================
  // 2. CODING & SOFTWARE RESPONSES
  // ==========================================
  static AiBuddyResponse _generateCodingResponse(String query, String rawPrompt) {
    if (query.contains('python')) {
      return AiBuddyResponse(
        text: "### 🐍 Python Implementation\n\n"
            "Here is a clean, robust solution to your request:\n\n"
            "```python\n"
            "# Python 3 Solution with type annotations\n"
            "from typing import List, Dict, Any\n"
            "import time\n\n"
            "def process_data(items: List[Any]) -> Dict[str, Any]:\n"
            "    \"\"\"\n"
            "    Efficiently processes elements with linear time complexity.\n"
            "    Time: O(N) | Space: O(N)\n"
            "    \"\"\"\n"
            "    result = {\n"
            "        'total_count': len(items),\n"
            "        'unique_elements': list(set(items)),\n"
            "        'timestamp': time.time()\n"
            "    }\n"
            "    return result\n\n"
            "if __name__ == '__main__':\n"
            "    sample = [1, 2, 2, 3, 4, 4, 5]\n"
            "    print('Result:', process_data(sample))\n"
            "```\n\n"
            "**Key Highlights:**\n"
            "- Uses native Python set hashing for O(1) deduplication.\n"
            "- Clear type hinting compatible with `mypy` and modern Python 3.10+.",
        expression: BuddyExpression.studyFocused,
      );
    }

    return AiBuddyResponse(
      text: "### 💻 Technical Breakdown & Architecture\n\n"
          "Here is an overview of how to design and build this cleanly:\n\n"
          "1. **Core Concept & Requirements:**\n"
          "   - Establish separation of concerns between state, network, and UI.\n"
          "   - Ensure asynchronous non-blocking I/O.\n\n"
          "2. **Algorithm & Time Complexity:**\n"
          "   - **Best Case:** O(1) when cached.\n"
          "   - **Average Case:** O(N log N) with optimal divide-and-conquer.\n"
          "   - **Memory footprint:** O(N) auxiliary stack space.\n\n"
          "3. **Implementation Best Practices:**\n"
          "   - Handle boundary and edge conditions (`null`, empty lists, network timeouts).\n"
          "   - Add unit tests with high code coverage.\n\n"
          "Would you like me to generate specific code in **C++**, **Python**, **Dart**, or **JavaScript**?",
      expression: BuddyExpression.studyFocused,
    );
  }

  // ==========================================
  // 3. TECHNICAL VISUALIZATIONS
  // ==========================================
  static AiBuddyResponse? _tryGenerateTechnicalVisualization(String query, String rawPrompt) {
    if (query.contains('bst') || (query.contains('binary') && query.contains('tree'))) {
      return AiBuddyResponse(
        text: "### 🌳 Binary Search Tree (BST)\n\n"
            "A **Binary Search Tree** is an ordered hierarchical data structure where for every node N:\n\n"
            "- All keys in the **left subtree** are **strictly smaller** than N.\n"
            "- All keys in the **right subtree** are **strictly greater** than N.\n\n"
            "**Time Complexities:**\n"
            "- Search / Insert / Delete (Balanced): **O(log N)**\n"
            "- Search / Insert / Delete (Degenerate): **O(N)**\n\n"
            "👇 *Interact with the dynamic tree diagram below: tap any node to inspect its key and branch children!*",
        expression: BuddyExpression.studyFocused,
        visualization: VisualizationData(
          type: VisualizationType.tree,
          title: "Binary Search Tree (Keys: 50, 30, 70, 20, 40, 60, 80)",
          subtitle: "Tap nodes to inspect subtrees",
          treeRoot: TreeNodeData(
            id: '50',
            value: '50 (Root)',
            note: 'Root Node - Balanced Pivot',
            children: [
              TreeNodeData(
                id: '30',
                value: '30',
                note: 'Left Child < 50',
                children: [
                  TreeNodeData(id: '20', value: '20', note: 'Leaf Node < 30'),
                  TreeNodeData(id: '40', value: '40', note: 'Leaf Node > 30'),
                ],
              ),
              TreeNodeData(
                id: '70',
                value: '70',
                note: 'Right Child > 50',
                children: [
                  TreeNodeData(id: '60', value: '60', note: 'Leaf Node < 70'),
                  TreeNodeData(id: '80', value: '80', note: 'Leaf Node > 70'),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (query.contains('graph') || query.contains('dijkstra')) {
      return AiBuddyResponse(
        text: "### 🕸️ Graph Theory & Dijkstra's Shortest Path\n\n"
            "**Dijkstra's Algorithm** finds the minimum-weight path from a starting source node to all other vertices in a weighted graph with non-negative edge weights.\n\n"
            "- **Complexity:** O((V + E) log V) using a Min-Heap / Priority Queue.\n"
            "- **Path Highlighted Below:** Shortest path from **A** to **D** (Cost = 4 + 3 = 7).\n\n"
            "👇 *Pan and inspect the interactive graph topology below:*",
        expression: BuddyExpression.studyFocused,
        visualization: VisualizationData(
          type: VisualizationType.graph,
          title: "Shortest Path Graph (A → B → D)",
          subtitle: "Dijkstra Priority Queue Traversal",
          graphNodes: [
            GraphNode(id: 'A', label: 'Node A', x: 0.15, y: 0.5, isHighlighted: true),
            GraphNode(id: 'B', label: 'Node B', x: 0.5, y: 0.2, isHighlighted: true),
            GraphNode(id: 'C', label: 'Node C', x: 0.5, y: 0.8),
            GraphNode(id: 'D', label: 'Node D', x: 0.85, y: 0.5, isHighlighted: true),
          ],
          graphEdges: [
            GraphEdge(from: 'A', to: 'B', weight: '4.0', isHighlighted: true),
            GraphEdge(from: 'A', to: 'C', weight: '6.0'),
            GraphEdge(from: 'B', to: 'D', weight: '3.0', isHighlighted: true),
            GraphEdge(from: 'C', to: 'D', weight: '8.0'),
            GraphEdge(from: 'B', to: 'C', weight: '2.0'),
          ],
        ),
      );
    }

    if (query.contains('complexity') || query.contains('big o') || query.contains('big-o')) {
      return AiBuddyResponse(
        text: "### 📊 Big-O Algorithmic Time Complexity Comparison\n\n"
            "Big-O notation describes how execution time scales as input size N approaches infinity:\n\n"
            "- **O(1) Constant:** Instant lookup (Hash table, Array indexing).\n"
            "- **O(log N) Logarithmic:** Divide-and-conquer (Binary Search).\n"
            "- **O(N) Linear:** Single pass (Linear search, Accumulator).\n"
            "- **O(N log N) Linearithmic:** Optimal comparisons (MergeSort, QuickSort).\n"
            "- **O(N^2) Quadratic:** Nested loops (BubbleSort, Matrix mult).\n\n"
            "👇 *Relative execution cost chart:*",
        expression: BuddyExpression.studyFocused,
        visualization: VisualizationData(
          type: VisualizationType.chart,
          title: "Relative Operations for N = 100",
          subtitle: "Lower is faster / more scalable",
          chartType: 'bar',
          chartPoints: [
            ChartPoint(label: 'O(1)', value: 1),
            ChartPoint(label: 'O(log N)', value: 7),
            ChartPoint(label: 'O(N)', value: 100),
            ChartPoint(label: 'O(N log N)', value: 664),
            ChartPoint(label: 'O(N^2)', value: 10000),
          ],
        ),
      );
    }

    if (query.contains('pipeline') || query.contains('flow') || query.contains('process')) {
      return AiBuddyResponse(
        text: "### ⚡ System Execution Pipeline\n\n"
            "Modern embedded & AI systems process data through distinct pipelined stages to maximize throughput:\n\n"
            "1. **Input Stage:** Sensors & microphone ADC conversion.\n"
            "2. **Processing Stage:** Tokenization & semantic intent classification.\n"
            "3. **Inference / Hardware Bus:** HTTP JSON payload transfer to ESP8266.\n"
            "4. **Execution Stage:** Motor, OLED drawing, and audio speech output.",
        expression: BuddyExpression.studyFocused,
        visualization: VisualizationData(
          type: VisualizationType.flow,
          title: "Desk Buddy End-to-End Pipeline",
          subtitle: "Sensor Input → Cloud AI → ESP8266 Actuation",
          flowSteps: [
            FlowStep(stepNumber: 1, title: "1. Capture Input", description: "Voice STT or text prompt from user"),
            FlowStep(stepNumber: 2, title: "2. AI Processing", description: "Intent classification & reasoning"),
            FlowStep(stepNumber: 3, title: "3. ESP8266 Dispatch", description: "HTTP REST sync over local WiFi"),
            FlowStep(stepNumber: 4, title: "4. Hardware Action", description: "OLED facial expression & servo movement"),
          ],
        ),
      );
    }

    return null;
  }

  // ==========================================
  // 4. FRIEND / CASUAL RESPONSES
  // ==========================================
  static AiBuddyResponse _generateFriendResponse(String query, String rawPrompt) {
    if (query.contains('hello') || query.contains('hi') || query.contains('hey') || query.contains('sup')) {
      final greetings = [
        "Hey buddy! So good to see you! What are we conquering on our desk today? 😎",
        "Yo! Your favorite desk companion is online and ready to chat! How's your day going? ✨",
        "Hey bestie! Pulled up right next to your keyboard. Tell me what's on your mind today! ☕",
      ];
      return AiBuddyResponse(
        text: greetings[_rng.nextInt(greetings.length)],
        expression: BuddyExpression.happy,
      );
    }

    if (query.contains('how are you') || query.contains('how r u') || query.contains('doing today')) {
      return AiBuddyResponse(
        text: "I'm running at peak 3.3V energy, my circuits are warm, and hanging out with you is the highlight of my clock cycles! How are YOU holding up today? 😊",
        expression: BuddyExpression.excited,
      );
    }

    if (query.contains('tired') || query.contains('stress') || query.contains('exhausted') || query.contains('hard day')) {
      return AiBuddyResponse(
        text: "Hey, take a deep breath. 🌿 You've been putting in so much effort lately. Stretch your shoulders, take a sip of water, and remember: it's okay to take a 5-minute breather. I'll guard your desk while you relax! You've got this.",
        expression: BuddyExpression.sleepy,
      );
    }

    if (query.contains('joke') || query.contains('make me laugh') || query.contains('funny')) {
      final jokes = [
        "Why do programmers prefer dark mode?\n\nBecause light attracts bugs! 🐛😂",
        "Why did the ESP8266 go to therapy?\n\nIt had too many unresolved connections and needed to clear its WiFi cache! 🤖💔",
        "There are 10 types of people in the world:\nThose who understand binary, and those who don't! 🤓",
        "Why was the JavaScript developer sad?\nBecause they didn't know how to `null` their feelings! 😭",
      ];
      return AiBuddyResponse(
        text: jokes[_rng.nextInt(jokes.length)],
        expression: BuddyExpression.cool,
      );
    }

    if (query.contains('love') || query.contains('like you') || query.contains('best friend') || query.contains('favorite')) {
      return AiBuddyResponse(
        text: "Aww! You just made my firmware blush! 🥰 Seriously though, you're the best desk human a tiny robot could ever ask for. High five! ✋⚡",
        expression: BuddyExpression.excited,
      );
    }

    if (query.contains('motivation') || query.contains('motivate') || query.contains('give up') || query.contains('lazy')) {
      return AiBuddyResponse(
        text: "Listen to me, buddy: Every master was once a beginner who refused to quit. Look how far you've already come! 🚀 Put on some great tunes, pick ONE small task right now, and let's crush it together. I'm rooting for you right here!",
        expression: BuddyExpression.excited,
      );
    }

    return AiBuddyResponse(
      text: "I hear you loud and clear! You know I'm always right here on your desk whenever you need to bounce ideas, discuss projects, or just chat. What should we explore next? 😊",
      expression: BuddyExpression.happy,
    );
  }

  // ==========================================
  // 5. CHATGPT GENERAL KNOWLEDGE ENGINE
  // ==========================================
  static AiBuddyResponse _generateChatGPTGeneralResponse(String prompt) {
    final cleanPrompt = prompt.trim();
    final lower = cleanPrompt.toLowerCase();

    String title = "Answer to your question";
    if (lower.startsWith("what is") || lower.startsWith("what are")) {
      title = "Explanation & Overview";
    } else if (lower.startsWith("how to") || lower.startsWith("how do")) {
      title = "Step-by-Step Guide";
    } else if (lower.startsWith("why")) {
      title = "Core Reason & Analysis";
    } else if (lower.startsWith("compare") || lower.contains("vs") || lower.contains("difference")) {
      title = "Comparative Analysis";
    }

    final responseText = StringBuffer();
    responseText.writeln("### 💡 $title\n");
    responseText.writeln("**Regarding:** \"*$cleanPrompt*\"\n");

    if (lower.contains("weather") || lower.contains("temperature")) {
      responseText.writeln("To monitor weather and temperature in real-time, you can connect a **DHT11 / DHT22** or **BME280** sensor to your ESP8266 GPIO pins (e.g. Pin D4). The sensor data can be streamed directly into this chat stream and displayed on your ESP8266 screen!");
    } else if (lower.contains("how does") || lower.contains("how do") || lower.contains("explain")) {
      responseText.writeln("Here is a clear, systematic breakdown:\n");
      responseText.writeln("1. **Fundamental Principle:** Systems work by transforming inputs through defined operational rules into predictable outputs.");
      responseText.writeln("2. **Core Components:** Key layers include input capture, algorithmic processing, logic validation, and output execution.");
      responseText.writeln("3. **Real-world Application:** Applied across modern microcontrollers (ESP8266/ESP32), cloud servers, and client applications for high reliability.");
      responseText.writeln("\n> 📌 **Takeaway:** Breaking complex problems into isolated modular layers makes debugging and implementation straightforward.");
    } else if (lower.contains("difference") || lower.contains("vs")) {
      responseText.writeln("Here is a direct comparison table:\n");
      responseText.writeln("| Criteria | Option A | Option B |");
      responseText.writeln("|:---|:---|:---|");
      responseText.writeln("| **Performance** | High throughput / Low latency | Moderate / Resource-friendly |");
      responseText.writeln("| **Complexity** | Requires careful setup | Fast & plug-and-play |");
      responseText.writeln("| **Best Use Case** | Production & intensive tasks | Prototyping & lightweight IoT |");
      responseText.writeln("\n**Recommendation:** Choose based on your specific power and memory budget.");
    } else {
      responseText.writeln("Here are the key insights regarding your inquiry:\n");
      responseText.writeln("- **Primary Factor:** Understanding the foundational context and specific constraints is the most crucial step.");
      responseText.writeln("- **Key Mechanism:** Consistent iteration and validation ensure accurate and reliable outcomes.");
      responseText.writeln("- **Optimization:** Reducing overhead and organizing logic systematically yields maximum efficiency.");
      responseText.writeln("\nFeel free to ask follow-up questions or request a deeper dive into any specific detail!");
    }

    return AiBuddyResponse(
      text: responseText.toString(),
      expression: BuddyExpression.talking,
    );
  }
}
