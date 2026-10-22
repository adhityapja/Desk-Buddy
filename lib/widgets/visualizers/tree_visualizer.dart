import 'package:flutter/material.dart';
import '../../models/visualization_data.dart';

class TreeVisualizer extends StatefulWidget {
  final TreeNodeData root;
  final String title;
  final String? subtitle;

  const TreeVisualizer({
    super.key,
    required this.root,
    required this.title,
    this.subtitle,
  });

  @override
  State<TreeVisualizer> createState() => _TreeVisualizerState();
}

class _TreeVisualizerState extends State<TreeVisualizer> {
  TreeNodeData? _selectedNode;
  final TransformationController _transformController = TransformationController();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF00E5FF) : const Color(0xFF2563EB);
    final cardBg = isDark ? const Color(0xFF131722) : Colors.white;
    final borderColor = isDark ? primaryColor.withOpacity(0.35) : const Color(0xFFE2E8F0);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: isDark ? primaryColor.withOpacity(0.08) : Colors.black.withOpacity(0.04),
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
                    color: primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.account_tree_rounded, color: primaryColor, size: 18),
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
                    _transformController.value = Matrix4.identity();
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

          // Interactive Tree Canvas
          SizedBox(
            height: 240,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: Stack(
                children: [
                  InteractiveViewer(
                    transformationController: _transformController,
                    boundaryMargin: const EdgeInsets.all(100),
                    minScale: 0.5,
                    maxScale: 3.0,
                    child: Center(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: _buildTreeWidget(widget.root, isDark, primaryColor),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Selected Node Details Banner
                  if (_selectedNode != null)
                    Positioned(
                      bottom: 8,
                      left: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E2638) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: primaryColor),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: primaryColor, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Node '${_selectedNode!.value}': ${_selectedNode!.note ?? 'Children: ${_selectedNode!.children.length}'}",
                                style: TextStyle(
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _selectedNode = null),
                              child: Icon(
                                Icons.close,
                                color: isDark ? Colors.grey : const Color(0xFF94A3B8),
                                size: 16,
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

  Widget _buildTreeWidget(TreeNodeData node, bool isDark, Color primaryColor) {
    final isSelected = node.isHighlighted || _selectedNode?.id == node.id;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            setState(() => _selectedNode = node);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isSelected
                    ? (isDark
                        ? [const Color(0xFF00E5FF), const Color(0xFF0072FF)]
                        : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)])
                    : (isDark
                        ? [const Color(0xFF222B40), const Color(0xFF192030)]
                        : [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)]),
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? primaryColor.withOpacity(0.5)
                        : const Color(0xFFCBD5E1)),
                width: 1.5,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: primaryColor.withOpacity(0.4),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: Text(
              node.value,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white : const Color(0xFF0F172A)),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),

        // Children branches
        if (node.children.isNotEmpty) ...[
          CustomPaint(
            size: Size(node.children.length * 60.0, 24),
            painter: _TreeBranchPainter(
              childCount: node.children.length,
              branchColor: primaryColor.withOpacity(0.6),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: node.children
                .map((child) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: _buildTreeWidget(child, isDark, primaryColor),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _TreeBranchPainter extends CustomPainter {
  final int childCount;
  final Color branchColor;

  _TreeBranchPainter({required this.childCount, required this.branchColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = branchColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final topCenter = Offset(size.width / 2, 0);

    if (childCount == 1) {
      canvas.drawLine(topCenter, Offset(size.width / 2, size.height), paint);
      return;
    }

    final step = size.width / childCount;
    for (int i = 0; i < childCount; i++) {
      final bottomX = (i + 0.5) * step;
      final path = Path()
        ..moveTo(topCenter.dx, topCenter.dy)
        ..cubicTo(
          topCenter.dx,
          size.height * 0.5,
          bottomX,
          size.height * 0.5,
          bottomX,
          size.height,
        );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
