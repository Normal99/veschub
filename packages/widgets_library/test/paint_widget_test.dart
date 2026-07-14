import 'package:dashboard_model/dashboard_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_dsl/paint_dsl.dart';
import 'package:widgets_library/widgets_library.dart';

void main() {
  group('PaintWidget', () {
    testWidgets('renders a program without throwing', (tester) async {
      const program = PaintProgram(
        ops: [
          ClearOp(color: 0xFF101010),
          BrushOp(color: 0xFFFF0000, style: PaintFill.fill),
          RectOp(x: 0, y: 0, w: 100, h: 100),
          BrushOp(color: 0xFF00FF00, style: PaintFill.stroke, strokeWidth: 3),
          CircleOp(cx: '\$cx', cy: 50, r: '\$r'),
        ],
      );
      final widget = buildWidget(
        const WidgetInstance(id: 'p', kind: 'paint'),
        {
          'program': program.toJson(),
          'cx': 50,
          'r': 20,
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(width: 200, height: 200, child: widget),
          ),
        ),
      );
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('tolerates a missing/invalid program', (tester) async {
      final widget = buildWidget(
        const WidgetInstance(id: 'p', kind: 'paint'),
        const {},
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(width: 100, height: 100, child: widget),
          ),
        ),
      );
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });

  group('paint widget registration', () {
    test('is registered at Expert level', () {
      expect(builtInWidgets['paint']?.level, CapabilityLevel.expert);
    });

    test('has a property manifest', () {
      expect(propertyManifest['paint'], isNotEmpty);
    });
  });
}
