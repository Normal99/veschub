/// Capability level system that gates studio UI visibility.
///
/// Every widget kind and feature declares a level; the studio hides props and
/// locks transforms below the user's chosen level. This is the "hybrid editor"
/// from the plan: Template=Basic, Canvas=Advanced, Flow=Expert.
library;

/// Three capability tiers, ordered low → high.
enum CapabilityLevel {
  basic,
  advanced,
  expert;

  /// Whether [other] is available at this level (i.e. [other] <= this).
  bool includes(CapabilityLevel other) => index >= other.index;

  /// The editor mode this level maps to.
  EditorMode get defaultEditorMode => switch (this) {
        CapabilityLevel.basic => EditorMode.template,
        CapabilityLevel.advanced => EditorMode.canvas,
        CapabilityLevel.expert => EditorMode.flow,
      };
}

/// The three binding/editing modes of the studio.
enum EditorMode { template, canvas, flow }

/// Identifies a widget kind and its declared capability level.
class WidgetDescriptor {
  final String id;
  final CapabilityLevel level;
  final String displayName;

  const WidgetDescriptor({
    required this.id,
    required this.level,
    required this.displayName,
  });
}
