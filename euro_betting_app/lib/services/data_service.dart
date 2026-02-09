import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/defense_stats.dart';
import '../models/player.dart';
import '../models/team.dart';

class EuroData {
  const EuroData({
    required this.teams,
    required this.players,
    required this.defenses,
    required this.schedule,
  });

  final List<Team> teams;
  final List<Player> players;
  final List<DefenseStats> defenses;
  final List<Map<String, dynamic>> schedule;
}

class DataService {
  DataService({
    required this.dataUrl,
  });

  final String dataUrl;

  static const _cacheKey = 'euro_data_cache_v1';

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
  }

  Future<EuroData> fetchData() async {
    try {
      final response = await http.get(Uri.parse(dataUrl));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}');
      }

      await _cacheRawJson(response.body);
      return _parseEuroData(response.body);
    } catch (e) {
      final cached = await _readCachedRawJson();
      if (cached == null) {
        rethrow;
      }
      return _parseEuroData(cached);
    }
  }

  Future<void> _cacheRawJson(String rawJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, rawJson);
  }

  Future<String?> _readCachedRawJson() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cacheKey);
  }

  EuroData _parseEuroData(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Expected JSON object at root');
    }

    final teamsJson = (decoded['teams'] as List<dynamic>?) ?? const [];
    final playersJson = (decoded['players'] as List<dynamic>?) ?? const [];
    final scheduleJson = (decoded['schedule'] as List<dynamic>?) ??
        (decoded['upcomingGames'] as List<dynamic>?) ??
        const [];

    final defenseJson =
        decoded['defense_vs_position'] ?? decoded['defenseStats'];

    final schedule = scheduleJson
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);

    print('DataService._parseEuroData():');
    print('  Schedule games: ${schedule.length}');

    final opponentByTeamId = <String, String>{};
    for (final game in schedule) {
      final homeTeamId = game['homeTeamId'] as String?;
      final awayTeamId = game['awayTeamId'] as String?;

      if (homeTeamId != null && awayTeamId != null) {
        opponentByTeamId[homeTeamId] ??= awayTeamId;
        opponentByTeamId[awayTeamId] ??= homeTeamId;
      }
    }

    print('  Teams with opponents in schedule: ${opponentByTeamId.length}');
    if (opponentByTeamId.isNotEmpty) {
      final sample = opponentByTeamId.entries.first;
      print('  Sample: ${sample.key} vs ${sample.value}');
    }

    final teams = teamsJson.whereType<Map<String, dynamic>>().map((json) {
      final teamId = (json['id'] as String?) ?? (json['team_id'] as String?) ?? '';
      return Team(
        id: teamId,
        name: (json['name'] as String?) ?? '',
        logoUrl: (json['logoUrl'] as String?) ??
            (json['logo_url'] as String?) ??
            '',
        nextOpponentId: opponentByTeamId[teamId] ??
            (json['nextOpponentId'] as String?) ??
            (json['next_opponent_id'] as String?) ??
            '',
        record: (json['record'] as String?) ?? '',
      );
    }).toList(growable: false);

    final players = playersJson
        .whereType<Map<String, dynamic>>()
        .map(Player.fromJson)
        .toList(growable: false);

    final defenses = <DefenseStats>[];
    if (defenseJson is Map<String, dynamic>) {
      for (final entry in defenseJson.entries) {
        final teamId = entry.key;
        final value = entry.value;
        if (value is Map<String, dynamic>) {
          defenses.add(DefenseStats.fromDefenseVsPosition(teamId, value));
        }
      }
    } else if (defenseJson is List<dynamic>) {
      defenses.addAll(
        defenseJson
            .whereType<Map<String, dynamic>>()
            .map(DefenseStats.fromJson),
      );
    }

    return EuroData(
      teams: teams,
      players: players,
      defenses: defenses,
      schedule: schedule,
    );
  }
}
