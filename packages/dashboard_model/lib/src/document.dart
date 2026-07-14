/// The versioned, serializable dashboard document.
///
/// A [DashboardDocument] is the unit authored in the studio and rendered by the
/// runtime. It is versioned from day one so the schema can evolve with
/// migrations. Widgets are positioned with a 2D affine transform (matrix)
/// rather than x/y/w/h, matching the scene-graph editor.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import 'binding.dart';
import 'capability.dart';

part 'document.freezed.dart';
part 'document.g.dart';

/// Schema version for the dashboard document.
///
/// Increment and add a migration step in [DashboardMigrator] whenever the
/// on-disk shape changes. Documents carry the version they were authored with.
const int kCurrentDocumentVersion = 2;

/// A single widget instance on the canvas.
@Freezed()
class WidgetInstance with _$WidgetInstance {
  const factory WidgetInstance({
    @JsonKey(name: 'id') required String id,

    /// Which built-in widget this is (e.g. 'gauge', 'bar', 'text').
    @JsonKey(name: 'kind') required String kind,

    /// 2D affine transform as a 6-element row-major matrix
    /// `[scaleX, skewY, skewX, scaleY, translateX, translateY]`.
    @JsonKey(name: 'transform')
    @Default([1, 0, 0, 1, 0, 0])
    List<double> transform,

    /// Z-order; higher draws on top.
    @JsonKey(name: 'z') @Default(0) int z,

    /// Property name → binding. Each property resolves to a value at render
    /// time via [dashboard_runtime].
    @JsonKey(name: 'properties')
    @Default(<String, Binding>{})
    @BindingMapConverter()
    Map<String, Binding> properties,

    /// Minimum capability level required to edit this widget.
    @JsonKey(name: 'level')
    @Default(CapabilityLevel.basic)
    CapabilityLevel level,
  }) = _WidgetInstance;

  factory WidgetInstance.fromJson(Map<String, dynamic> json) =>
      _$WidgetInstanceFromJson(json);
}

/// The canvas size in device-independent points.
@Freezed()
class CanvasSize with _$CanvasSize {
  const factory CanvasSize({
    @JsonKey(name: 'width') required double width,
    @JsonKey(name: 'height') required double height,
  }) = _CanvasSize;

  factory CanvasSize.fromJson(Map<String, dynamic> json) =>
      _$CanvasSizeFromJson(json);
}

/// The top-level dashboard document.
@Freezed()
class DashboardDocument with _$DashboardDocument {
  const factory DashboardDocument({
    /// Schema version this document was authored with.
    @JsonKey(name: 'version') @Default(kCurrentDocumentVersion) int version,
    @JsonKey(name: 'name') @Default('Untitled') String name,

    /// Human-readable description (added in schema v2; migrated to '' for v1).
    @JsonKey(name: 'description') @Default('') String description,
    @JsonKey(name: 'canvas') required CanvasSize canvas,
    @JsonKey(name: 'widgets')
    @Default(<WidgetInstance>[])
    List<WidgetInstance> widgets,

    /// Node graphs referenced by [Binding.graph] (Expert mode). Stored as
    /// opaque JSON; typed in Phase 6 (node_graph).
    @JsonKey(name: 'graphs')
    @Default(<String, dynamic>{})
    Map<String, dynamic> graphs,

    /// Background colour as an ARGB int (0xAARRGGBB).
    @JsonKey(name: 'background') @Default(0xFF000000) int background,

    /// Accent colour as an ARGB int.
    @JsonKey(name: 'accent') @Default(0xFFFFFFFF) int accent,
  }) = _DashboardDocument;

  factory DashboardDocument.fromJson(Map<String, dynamic> json) =>
      _$DashboardDocumentFromJson(json);
}
