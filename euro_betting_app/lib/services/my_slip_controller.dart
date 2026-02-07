import 'package:flutter/foundation.dart';

import '../models/enums.dart';

class TrackedBet {
  const TrackedBet({
    required this.playerId,
    required this.playerName,
    required this.line,
    required this.direction,
    required this.confidenceScore,
    required this.createdAt,
  });

  final String playerId;
  final String playerName;
  final double line;
  final TipDirection direction;
  final double confidenceScore;
  final DateTime createdAt;
}

class MySlipController extends ChangeNotifier {
  List<TrackedBet> _bets = const [];

  List<TrackedBet> get bets => _bets;

  void trackBet(TrackedBet bet) {
    _bets = List.unmodifiable([bet, ..._bets]);
    notifyListeners();
  }
}
