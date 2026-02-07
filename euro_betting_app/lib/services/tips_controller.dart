import 'package:flutter/foundation.dart';

import '../models/betting_tip.dart';
import '../models/defense_stats.dart';
import '../models/enums.dart';
import '../models/player.dart';
import '../models/team.dart';
import 'analysis_engine.dart';
import 'mock_data_service.dart';

class TipItem {
  const TipItem({
    required this.tip,
    required this.player,
    required this.team,
    required this.opponent,
    required this.opponentAllowedPtsToPosition,
  });

  final BettingTip tip;
  final Player player;
  final Team team;
  final Team opponent;
  final double opponentAllowedPtsToPosition;
}

class TipsController extends ChangeNotifier {
  TipsController({
    required MockDataService mockDataService,
  }) : _mockDataService = mockDataService;

  final MockDataService _mockDataService;

  bool _isLoading = false;
  Object? _error;
  List<TipItem> _items = const [];

  bool get isLoading => _isLoading;
  Object? get error => _error;
  List<TipItem> get items => _items;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final teams = _mockDataService.getTeams();
      final players = _mockDataService.getPlayers();
      final defenses = _mockDataService.getDefenseStats();

      final tips = AnalysisEngine.generateTips(players, teams, defenses);
      final teamsById = {for (final t in teams) t.id: t};
      final playersById = {for (final p in players) p.id: p};
      final defensesByTeamId = {for (final d in defenses) d.teamId: d};

      final newItems = <TipItem>[];

      for (final tip in tips) {
        final player = playersById[tip.playerId];
        if (player == null) {
          continue;
        }

        final team = teamsById[player.teamId];
        if (team == null) {
          continue;
        }

        final opponent = teamsById[team.nextOpponentId];
        if (opponent == null) {
          continue;
        }

        final opponentDefense = defensesByTeamId[opponent.id];
        if (opponentDefense == null) {
          continue;
        }

        final opponentAllowedPtsToPosition = _allowedPtsForPosition(
          opponentDefense,
          player.position,
        );

        newItems.add(
          TipItem(
            tip: tip,
            player: player,
            team: team,
            opponent: opponent,
            opponentAllowedPtsToPosition: opponentAllowedPtsToPosition,
          ),
        );
      }

      _items = List.unmodifiable(newItems);
    } catch (e) {
      _error = e;
      _items = const [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

double _allowedPtsForPosition(
  DefenseStats defense,
  PlayerPosition position,
) =>
    switch (position) {
      PlayerPosition.pg => defense.allowedPtsPG,
      PlayerPosition.sg => defense.allowedPtsSG,
      PlayerPosition.sf => defense.allowedPtsSF,
      PlayerPosition.pf => defense.allowedPtsPF,
      PlayerPosition.c => defense.allowedPtsC,
    };
