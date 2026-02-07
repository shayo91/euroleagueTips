import 'dart:math';

import '../models/betting_tip.dart';
import '../models/defense_stats.dart';
import '../models/enums.dart';
import '../models/player.dart';
import '../models/team.dart';

class AnalysisEngine {
  static const _thresholdMultiplier = 1.15;

  static List<BettingTip> generateTips(
    List<Player> players,
    List<Team> teams,
    List<DefenseStats> defenses,
  ) {
    final teamsById = {for (final t in teams) t.id: t};
    final defensesByTeamId = {for (final d in defenses) d.teamId: d};

    final tips = <BettingTip>[];

    for (final player in players) {
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

      final leagueAverage = _leagueAveragePtsForPosition(player.position);
      final allowedPts = _allowedPtsForPosition(
        opponentDefense,
        player.position,
      );

      final isGreenLight = allowedPts > leagueAverage * _thresholdMultiplier;
      if (!isGreenLight) {
        continue;
      }

      final pctAboveAverage = (allowedPts / leagueAverage) - 1.0;
      final confidenceScore =
          min(1.0, max(0.0, pctAboveAverage / 0.50));

      tips.add(
        BettingTip(
          playerId: player.id,
          matchupDescription: '${player.name} vs ${opponent.name}',
          suggestedLine: player.last5AvgPts,
          direction: TipDirection.over,
          confidenceScore: confidenceScore,
          reasoning:
              'Opponent allows ${allowedPts.toStringAsFixed(1)} pts '
              'to ${_positionLabel(player.position)}s '
              '(Worst in League)',
        ),
      );
    }

    tips.sort((a, b) => b.confidenceScore.compareTo(a.confidenceScore));
    return tips;
  }

  static double _leagueAveragePtsForPosition(PlayerPosition position) =>
      switch (position) {
        PlayerPosition.pg => 11.5,
        PlayerPosition.sg => 12.0,
        PlayerPosition.sf => 11.0,
        PlayerPosition.pf => 10.5,
        PlayerPosition.c => 11.8,
      };

  static double _allowedPtsForPosition(
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

  static String _positionLabel(PlayerPosition position) =>
      switch (position) {
        PlayerPosition.pg => 'PG',
        PlayerPosition.sg => 'SG',
        PlayerPosition.sf => 'SF',
        PlayerPosition.pf => 'PF',
        PlayerPosition.c => 'C',
      };
}
