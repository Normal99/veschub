/// Selection model for the editor canvas.
library;

import 'package:flutter/foundation.dart';

class SelectionModel extends ChangeNotifier {
  final Set<String> _ids = {};

  Set<String> get ids => Set.unmodifiable(_ids);
  bool get isEmpty => _ids.isEmpty;
  bool get isMultiple => _ids.length > 1;
  String? get single => _ids.length == 1 ? _ids.first : null;

  bool isSelected(String id) => _ids.contains(id);

  void set(String id) {
    if (_ids.length == 1 && _ids.first == id) return;
    _ids
      ..clear()
      ..add(id);
    notifyListeners();
  }

  void setAll(Iterable<String> ids) {
    _ids
      ..clear()
      ..addAll(ids);
    notifyListeners();
  }

  void toggle(String id) {
    if (_ids.contains(id)) {
      _ids.remove(id);
    } else {
      _ids.add(id);
    }
    notifyListeners();
  }

  void add(String id) {
    if (_ids.add(id)) notifyListeners();
  }

  void clear() {
    if (_ids.isEmpty) return;
    _ids.clear();
    notifyListeners();
  }
}
