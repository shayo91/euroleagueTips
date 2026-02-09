import 'dart:math';

import '../models/betting_tip.dart';
import '../models/defense_stats.dart';
import '../models/enums.dart';
import '../models/player.dart';
import '../models/team.dart';

class AnalysisEngine {
  static const _thresholdMultiplier = 1.15;
  static const _homeAwayMultiplier = 0.05;

  static List<BettingTip> generateTips(
    List<Player> players,
    List<Team> teams,
    List<DefenseStats> defenses,
    List<Map<String, dynamic>> schedule,
  ) {
    final teamsById = {for (final t in teams) t.id: t};
    final defensesByTeamId = {for (final d in defenses) d.teamId: d};

    final tips = <BettingTip>[];
    
    var playersProcessed = 0;
    var playersWithTeam = 0;
    var playersWithOpponent = 0;
    var playersWithDefense = 0;
    var playersPassGreenLight = 0;

    for (final player in players) {
      playersProcessed++;
      final team = teamsById[player.teamId];
      if (team == null) {
        continue;
      }
      playersWithTeam++;

      final opponentId = _findOpponentId(
            teamId: team.id,
            schedule: schedule,
          ) ??
          team.nextOpponentId;

      final opponent = teamsById[opponentId];
      if (opponent == null) {
        continue;
      }
      playersWithOpponent++;

      final opponentDefense = defensesByTeamId[opponent.id];
      if (opponentDefense == null) {
        continue;
      }
      playersWithDefense++;

      final leagueAverage = _leagueAveragePtsForPosition(player.position);
      final allowedPts = _allowedPtsForPosition(
        opponentDefense,
        player.position,
      );

      final recencyWeighted = (player.last5AvgPts * 0.6) + (player.seasonAvgPts * 0.4);

      final isHome = _isHomeGame(
        teamId: team.id,
        opponentId: opponent.id,
        schedule: schedule,
      );

      final homeAwayAdjusted = recencyWeighted *
          switch (isHome) {
            true => 1 + _homeAwayMultiplier,
            false => 1 - _homeAwayMultiplier,
            null => 1,
          };

      final defenseMultiplier = (allowedPts / leagueAverage).clamp(0.85, 1.25);
      final projectedPoints = homeAwayAdjusted * defenseMultiplier;

      final isGreenLight = allowedPts > leagueAverage * _thresholdMultiplier;
      if (!isGreenLight) {
        continue;
      }
      playersPassGreenLight++;

      final defensiveHole = (allowedPts / leagueAverage) - 1.0;
      var confidenceScore =
          min(1.0, max(0.0, defensiveHole / 0.50));

      final blowoutPenalty = _blowoutPenalty(team: team, opponent: opponent);
      confidenceScore = (confidenceScore * blowoutPenalty).clamp(0.0, 1.0);

      tips.add(
        BettingTip(
          playerId: player.id,
          matchupDescription: '${player.name} vs ${opponent.name}',
          suggestedLine: projectedPoints,
          direction: TipDirection.over,
          confidenceScore: confidenceScore,
          reasoning:
              'Opponent allows ${allowedPts.toStringAsFixed(1)} pts '
              'to ${_positionLabel(player.position)}s '
              '(Worst in League)',
        ),
      );
    }
    
    print('AnalysisEngine.generateTips() stats:');
    print('  Players processed: $playersProcessed');
    print('  Players with team: $playersWithTeam');
    print('  Players with opponent: $playersWithOpponent');
    print('  Players with defense: $playersWithDefense');
    print('  Players pass green light: $playersPassGreenLight');
    print('  Tips generated: ${tips.length}');

    tips.sort((a, b) => b.confidenceScore.compareTo(a.confidenceScore));
    return tips;
  }

  static String? _findOpponentId({
    required String teamId,
    required List<Map<String, dynamic>> schedule,
  }) {
    for (final game in schedule) {
      final homeTeamId = game['homeTeamId'] as String?;
      final awayTeamId = game['awayTeamId'] as String?;
      if (homeTeamId == null || awayTeamId == null) {
        continue;
      }
      if (homeTeamId == teamId) {
        return awayTeamId;
      }
      if (awayTeamId == teamId) {
        return homeTeamId;
      }
    }
    return null;
  }

  static bool? _isHomeGame({
    required String teamId,
    required String opponentId,
    required List<Map<String, dynamic>> schedule,
  }) {
    for (final game in schedule) {
      final homeTeamId = game['homeTeamId'] as String?;
      final awayTeamId = game['awayTeamId'] as String?;
      if (homeTeamId == null || awayTeamId == null) {
        continue;
      }

      final isMatch = (homeTeamId == teamId && awayTeamId == opponentId) ||
          (homeTeamId == opponentId && awayTeamId == teamId);
      if (!isMatch) {
        continue;
      }

      return homeTeamId == teamId;
    }

    return null;
  }

  static double _blowoutPenalty({
    required Team team,
    required Team opponent,
  }) {
    final teamWinPct = team.winPercentage;
    final opponentWinPct = opponent.winPercentage;
    if (teamWinPct == null || opponentWinPct == null) {
      return 1.0;
    }

    final isBigMismatch =
        (teamWinPct > 0.8 && opponentWinPct < 0.2) ||
            (opponentWinPct > 0.8 && teamWinPct < 0.2);

    return isBigMismatch ? 0.7 : 1.0;
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
