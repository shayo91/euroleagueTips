import 'enums.dart';

class Player {
  const Player({
    required this.id,
    required this.name,
    required this.teamId,
    required this.position,
    required this.seasonAvgPts,
    required this.last5AvgPts,
    required this.last5GamePts,
    required this.imageUrl,
  });

  final String id;
  final String name;
  final String teamId;
  final PlayerPosition position;
  final double seasonAvgPts;
  final double last5AvgPts;
  final List<double> last5GamePts;
  final String imageUrl;

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: (json['id'] as String?) ?? '',
        name: (json['name'] as String?) ?? '',
        teamId: (json['teamId'] as String?) ?? (json['team_id'] as String?) ?? '',
        position: playerPositionFromJson(json['position']),
        seasonAvgPts: (json['seasonAvgPts'] as num?)?.toDouble() ??
            (json['season_avg_pts'] as num?)?.toDouble() ??
            0.0,
        last5AvgPts: (json['last5AvgPts'] as num?)?.toDouble() ??
            (json['last5_avg_pts'] as num?)?.toDouble() ??
            0.0,
        last5GamePts: ((json['last5GamePts'] as List<dynamic>?) ??
                (json['last5_game_pts'] as List<dynamic>?) ??
                const [])
            .map((e) => (e as num).toDouble())
            .toList(growable: false),
        imageUrl: (json['imageUrl'] as String?) ??
            (json['image_url'] as String?) ??
            '',
      );
}
