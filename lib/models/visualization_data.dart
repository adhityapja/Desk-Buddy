
enum VisualizationType {
  tree,
  graph,
  chart,
  flow,
}

/// Node for Tree Visualization
class TreeNodeData {
  final String id;
  final String value;
  final List<TreeNodeData> children;
  final bool isHighlighted;
  final String? note;

  TreeNodeData({
    required this.id,
    required this.value,
    this.children = const [],
    this.isHighlighted = false,
    this.note,
  });

  factory TreeNodeData.fromJson(Map<String, dynamic> json) {
    return TreeNodeData(
      id: json['id']?.toString() ?? UniqueKey().toString(),
      value: json['value']?.toString() ?? '',
      children: (json['children'] as List<dynamic>?)
              ?.map((c) => TreeNodeData.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      isHighlighted: json['isHighlighted'] == true,
      note: json['note']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'value': value,
        'children': children.map((c) => c.toJson()).toList(),
        'isHighlighted': isHighlighted,
        if (note != null) 'note': note,
      };
}

/// Node for Graph Visualization
class GraphNode {
  final String id;
  final String label;
  final double? x;
  final double? y;
  final bool isStart;
  final bool isEnd;
  final bool isHighlighted;

  GraphNode({
    required this.id,
    required this.label,
    this.x,
    this.y,
    this.isStart = false,
    this.isEnd = false,
    this.isHighlighted = false,
  });

  factory GraphNode.fromJson(Map<String, dynamic> json) {
    return GraphNode(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? json['id']?.toString() ?? '',
      x: (json['x'] as num?)?.toDouble(),
      y: (json['y'] as num?)?.toDouble(),
      isStart: json['isStart'] == true,
      isEnd: json['isEnd'] == true,
      isHighlighted: json['isHighlighted'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        if (x != null) 'x': x,
        if (y != null) 'y': y,
        'isStart': isStart,
        'isEnd': isEnd,
        'isHighlighted': isHighlighted,
      };
}

/// Edge for Graph Visualization
class GraphEdge {
  final String from;
  final String to;
  final String? weight;
  final bool isDirected;
  final bool isHighlighted;

  GraphEdge({
    required this.from,
    required this.to,
    this.weight,
    this.isDirected = true,
    this.isHighlighted = false,
  });

  factory GraphEdge.fromJson(Map<String, dynamic> json) {
    return GraphEdge(
      from: json['from']?.toString() ?? '',
      to: json['to']?.toString() ?? '',
      weight: json['weight']?.toString(),
      isDirected: json['isDirected'] != false,
      isHighlighted: json['isHighlighted'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'from': from,
        'to': to,
        if (weight != null) 'weight': weight,
        'isDirected': isDirected,
        'isHighlighted': isHighlighted,
      };
}

/// Data Point for Chart Visualization
class ChartPoint {
  final String label;
  final double value;
  final String? subtitle;

  ChartPoint({
    required this.label,
    required this.value,
    this.subtitle,
  });

  factory ChartPoint.fromJson(Map<String, dynamic> json) {
    return ChartPoint(
      label: json['label']?.toString() ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      subtitle: json['subtitle']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'value': value,
        if (subtitle != null) 'subtitle': subtitle,
      };
}

/// Step for Flow / Concept Step Visualization
class FlowStep {
  final int stepNumber;
  final String title;
  final String description;
  final bool isActive;

  FlowStep({
    required this.stepNumber,
    required this.title,
    required this.description,
    this.isActive = false,
  });

  factory FlowStep.fromJson(Map<String, dynamic> json) {
    return FlowStep(
      stepNumber: (json['stepNumber'] as num?)?.toInt() ?? 1,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      isActive: json['isActive'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'stepNumber': stepNumber,
        'title': title,
        'description': description,
        'isActive': isActive,
      };
}

/// Complete Visualization Payload
class VisualizationData {
  final VisualizationType type;
  final String title;
  final String? subtitle;
  final TreeNodeData? treeRoot;
  final List<GraphNode>? graphNodes;
  final List<GraphEdge>? graphEdges;
  final List<ChartPoint>? chartPoints;
  final String? chartType; // 'bar' or 'line'
  final List<FlowStep>? flowSteps;

  VisualizationData({
    required this.type,
    required this.title,
    this.subtitle,
    this.treeRoot,
    this.graphNodes,
    this.graphEdges,
    this.chartPoints,
    this.chartType = 'bar',
    this.flowSteps,
  });

  factory VisualizationData.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type']?.toString().toLowerCase() ?? 'tree';
    VisualizationType type;
    switch (typeStr) {
      case 'graph':
        type = VisualizationType.graph;
        break;
      case 'chart':
        type = VisualizationType.chart;
        break;
      case 'flow':
        type = VisualizationType.flow;
        break;
      case 'tree':
      default:
        type = VisualizationType.tree;
        break;
    }

    return VisualizationData(
      type: type,
      title: json['title']?.toString() ?? 'Visualization',
      subtitle: json['subtitle']?.toString(),
      treeRoot: json['tree'] != null
          ? TreeNodeData.fromJson(json['tree'] as Map<String, dynamic>)
          : null,
      graphNodes: (json['nodes'] as List<dynamic>?)
          ?.map((n) => GraphNode.fromJson(n as Map<String, dynamic>))
          .toList(),
      graphEdges: (json['edges'] as List<dynamic>?)
          ?.map((e) => GraphEdge.fromJson(e as Map<String, dynamic>))
          .toList(),
      chartPoints: (json['points'] as List<dynamic>?)
          ?.map((p) => ChartPoint.fromJson(p as Map<String, dynamic>))
          .toList(),
      chartType: json['chartType']?.toString() ?? 'bar',
      flowSteps: (json['steps'] as List<dynamic>?)
          ?.map((s) => FlowStep.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'title': title,
        if (subtitle != null) 'subtitle': subtitle,
        if (treeRoot != null) 'tree': treeRoot!.toJson(),
        if (graphNodes != null)
          'nodes': graphNodes!.map((n) => n.toJson()).toList(),
        if (graphEdges != null)
          'edges': graphEdges!.map((e) => e.toJson()).toList(),
        if (chartPoints != null)
          'points': chartPoints!.map((p) => p.toJson()).toList(),
        if (chartType != null) 'chartType': chartType,
        if (flowSteps != null)
          'steps': flowSteps!.map((s) => s.toJson()).toList(),
      };
}

class UniqueKey {
  static int _counter = 0;
  @override
  String toString() => 'node_${++_counter}';
}
