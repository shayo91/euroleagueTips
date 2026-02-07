import 'package:flutter/foundation.dart';

import '../models/enums.dart';
import 'tips_controller.dart';

class PredictionController extends ChangeNotifier {
  PredictionController({
    required TipItem item,
  })  : _item = item,
        _bookieLine = item.player.seasonAvgPts;

  final TipItem _item;
  double _bookieLine;

  TipItem get item => _item;
  double get bookieLine => _bookieLine;

  set bookieLine(double value) {
    if (value == _bookieLine) {
      return;
    }
    _bookieLine = value;
    notifyListeners();
  }

  TipDirection get direction => edge >= 0 ? TipDirection.over : TipDirection.under;

  double get expectedPoints {
    final base = (_item.player.seasonAvgPts * 0.6) + (_item.player.last5AvgPts * 0.4);
    final defenseDelta = _item.opponentAllowedPtsToPosition - _item.player.seasonAvgPts;
    return base + (defenseDelta * 0.25);
  }

  double get edge => expectedPoints - _bookieLine;

  double get confidenceScore {
    final raw = (edge.abs() / 10.0).clamp(0.0, 1.0);
    return raw;
  }

  bool get isRisky {
    if (confidenceScore < 0.35) {
      return true;
    }

    if (direction == TipDirection.over && _bookieLine > expectedPoints + 2.0) {
      return true;
    }

    if (direction == TipDirection.under && _bookieLine < expectedPoints - 2.0) {
      return true;
    }

    return false;
  }
}
