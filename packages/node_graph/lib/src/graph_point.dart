/// A simple 2D point used for node positions (pure-Dart, no Flutter dependency).
class GraphPoint {
  final double x;
  final double y;
  const GraphPoint(this.x, this.y);

  static const zero = GraphPoint(0, 0);

  GraphPoint copyWith({double? x, double? y}) =>
      GraphPoint(x ?? this.x, y ?? this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GraphPoint && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'GraphPoint($x, $y)';
}
