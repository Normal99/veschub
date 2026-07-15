/// Property bindings — how a widget property resolves to a value.
///
/// A binding is either:
///  * a [LiteralBinding] (constant value, e.g. a colour or a max RPM),
///  * a [TelemetryBinding] (resolved from the telemetry store by canonical key),
///  * a [FormulaBinding] (a math expression evaluated against telemetry keys),
///  * or a [GraphBinding] (resolved by a node-graph dataflow, Expert mode only).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'binding.freezed.dart';
part 'binding.g.dart';

/// Base class for property bindings.
///
/// Serialized as a discriminated union with a `type` key so each variant can
/// be reliably decoded without relying on runtime-type names.
@Freezed(unionKey: 'type', unionValueCase: FreezedUnionCase.snake)
sealed class Binding with _$Binding {
  const Binding._();

  /// A constant value baked into the document.
  @JsonSerializable(explicitToJson: true)
  const factory Binding.literal({
    @JsonKey(name: 'value') required Object value,
  }) = LiteralBinding;

  /// Resolved from the telemetry store by [key].
  const factory Binding.telemetry({
    @JsonKey(name: 'key') required String key,
  }) = TelemetryBinding;

  /// Resolved by a node graph (Expert). The [graphId] references a graph
  /// stored in the dashboard document; the named [output] of that graph feeds
  /// this property.
  const factory Binding.graph({
    @JsonKey(name: 'graph_id') required String graphId,
    @JsonKey(name: 'output') required String output,
  }) = GraphBinding;

  /// Resolved by evaluating a math expression (Expert). Telemetry keys are
  /// referenced by name (e.g. `erpm / 1000`, `tempMotor - tempMosfet`).
  const factory Binding.formula({
    @JsonKey(name: 'expression') required String expression,
  }) = FormulaBinding;

  factory Binding.fromJson(Map<String, dynamic> json) =>
      _$BindingFromJson(json);
}

/// (De)serializes `Map<String, Binding>` since [Binding] is a discriminated
/// union that `json_serializable` cannot encode automatically for map values.
class BindingMapConverter
    extends JsonConverter<Map<String, Binding>, Map<String, dynamic>> {
  const BindingMapConverter();

  @override
  Map<String, Binding> fromJson(Map<String, dynamic> json) => json.map(
        (k, v) =>
            MapEntry(k, Binding.fromJson(Map<String, dynamic>.from(v as Map))),
      );

  @override
  Map<String, dynamic> toJson(Map<String, Binding> object) => object.map(
        (k, v) => MapEntry(k, v.toJson()),
      );
}
