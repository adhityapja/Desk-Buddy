import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/visualization_data.dart';

class GraphVisualizer extends StatefulWidget {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final String title;
  final String? subtitle;

  const GraphVisualizer({
    super.key,
    required this.nodes,
    required this.edges,
    required this.title,
    this.subtitle,
  });

  @override
  State<GraphVisualizer> createState() => _GraphVisualizerState();
}

class _GraphVisualizerState extends State<GraphVisualizer> {
  final TransformationController _controller = TransformationController();
  GraphNode? _selectedNode;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF7928CA) : const Color(0xFF6366F1);
    final cardBg = isDark ? const Color(0xFF131722) : Colors.white;
    final borderColor = isDark ? primaryColor.withOpacity(0.4) : const Color(0xFFE2E8F0);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: isDark ? primaryColor.withOpacity(0.09) : Colors.black.withOpacity(0.04),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.hub_rounded,
                    color: isDark ? const Color(0xFFB388FF) : const Color(0xFF6366F1),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (widget.subtitle != null)
                        Text(
                          widget.subtitle!,
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: isDark ? Colors.grey : const Color(0xFF94A3B8),
                    size: 18,
                  ),
                  tooltip: 'Reset Zoom',
                  onPressed: () {
                    _controller.value = Matrix4.identity();
                    setState(() => _selectedNode = null);
                  },
                ),
              ],
            ),
          ),
          Divider(
            color: isDark ? const Color(0xFF232936) : const Color(0xFFE2E8F0),
            height: 1,
          ),

          // Graph Canvas
          SizedBox(
            height: 250,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: Stack(
                children: [
                  InteractiveViewer(
                    transformationController: _controller,
                    boundaryMargin: const EdgeInsets.all(120),
                    minScale: 0.5,
                    maxScale: 3.0,
                    child: Center(
                      child: SizedBox(
                        width: 320,
                        height: 240,
                        child: CustomPaint(
                          painter: _GraphPainter(
                            nodes: widget.nodes,
                            edges: widget.edges,
                            selectedNode: _selectedNode,
                            isDark: isDark,
                          ),
                          child: Stack(
                            children: _buildNodeWidgets(isDark),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Legend at top-right
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1B202E).withOpacity(0.9)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.circle,
                            size: 8,
                            color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF2563EB),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Path",
                            style: TextStyle(
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.circle,
                            size: 8,
                            color: isDark ? const Color(0xFF7928CA) : const Color(0xFF6366F1),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Node",
                            style: TextStyle(
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, Offset> _calculateNodePositions() {
    final positions = <String, Offset>{};
    final n = widget.nodes.length;
    if (n == 0) return positions;

    final center = const Offset(160, 120);
    final radius = 85.0;

    for (int i = 0; i < n; i++) {
      final node = widget.nodes[i];
      if (node.x != null && node.y != null) {
        positions[node.id] = Offset(node.x! * 300, node.y! * 220);
      } else {
        final angle = (2 * pi / n) * i - (pi / 2);
        positions[node.id] = Offset(
          center.dx + radius * cos(angle),
          center.dy + radius * sin(angle),
        );
      }
    }
    return positions;
  }

  List<Widget> _buildNodeWidgets(bool isDark) {
    final positions = _calculateNodePositions();
    return widget.nodes.map<Widget>((node) {
      final pos = positions[node.id] ?? const Offset(160, 120);
      final isSelected = _selectedNode?.id == node.id;
      final isHighlighted = node.isHighlighted || isSelected;

      return Positioned(
        left: pos.dx - 22,
        top: pos.dy - 22,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedNode = isSelected ? null : node;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: isHighlighted
                    ? (isDark
                        ? [const Color(0xFF00E5FF), const Color(0xFF0072FF)]
                        : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)])
                    : (isDark
                        ? [const Color(0xFF7928CA), const Color(0xFF3B1261)]
                        : [const Color(0xFF6366F1), const Color(0xFF4338CA)]),
              ),
              border: Border.all(
                color: isHighlighted ? Colors.white : const Color(0xFFCBD5E1),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isHighlighted
                          ? (isDark ? const Color(0xFF00E5FF) : const Color(0xFF2563EB))
                          : (isDark ? const Color(0xFF7928CA) : const Color(0xFF6366F1)))
                      .withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Text(
                node.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}

class _GraphPainter extends CustomPainter {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final GraphNode? selectedNode;
  final bool isDark;

  _GraphPainter({
    required this.nodes,
    required this.edges,
    this.selectedNode,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final positions = <String, Offset>{};
    final n = nodes.length;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = 85.0;

    for (int i = 0; i < n; i++) {
      final node = nodes[i];
      if (node.x != null && node.y != null) {
        positions[node.id] = Offset(node.x! * 300, node.y! * 220);
      } else {
        final angle = (2 * pi / n) * i - (pi / 2);
        positions[node.id] = Offset(
          center.dx + radius * cos(angle),
          center.dy + radius * sin(angle),
        );
      }
    }

    final edgePaint = Paint()
      ..color = isDark ? const Color(0xFF4A5568) : const Color(0xFFCBD5E1)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final highlightPaint = Paint()
      ..color = isDark ? const Color(0xFF00E5FF) : const Color(0xFF2563EB)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (final edge in edges) {
      final fromPos = positions[edge.from];
      final toPos = positions[edge.to];
      if (fromPos == null || toPos == null) continue;

      final isEdgeHighlight = edge.isHighlighted ||
          (selectedNode != null && (edge.from == selectedNode!.id || edge.to == selectedNode!.id));

      final paintToUse = isEdgeHighlight ? highlightPaint : edgePaint;
      canvas.drawLine(fromPos, toPos, paintToUse);

      // Draw weight label at midpoint
      if (edge.weight != null) {
        final mid = Offset((fromPos.dx + toPos.dx) / 2, (fromPos.dy + toPos.dy) / 2);
        final bgPaint = Paint()..color = isDark ? const Color(0xFF131722) : Colors.white;
        canvas.drawCircle(mid, 11, bgPaint);
        final borderPaint = Paint()
          ..color = isDark ? const Color(0xFF232936) : const Color(0xFFCBD5E1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        canvas.drawCircle(mid, 11, borderPaint);

        textPainter.text = TextSpan(
          text: edge.weight!,
          style: TextStyle(
            color: isEdgeHighlight
                ? (isDark ? const Color(0xFF00E5FF) : const Color(0xFF2563EB))
                : (isDark ? Colors.amberAccent : const Color(0xFFD97706)),
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(mid.dx - textPainter.width / 2, mid.dy - textPainter.height / 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GraphPainter oldDelegate) => true;
}
