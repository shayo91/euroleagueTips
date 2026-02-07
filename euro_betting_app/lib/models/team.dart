class Team {
  const Team({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.nextOpponentId,
    required this.record,
  });

  final String id;
  final String name;
  final String logoUrl;
  final String nextOpponentId;
  final String record;

  double? get winPercentage {
    final parts = record.split('-');
    if (parts.length != 2) {
      return null;
    }
    final wins = int.tryParse(parts[0].trim());
    final losses = int.tryParse(parts[1].trim());
    if (wins == null || losses == null) {
      return null;
    }
    final total = wins + losses;
    if (total <= 0) {
      return null;
    }
    return wins / total;
  }

  factory Team.fromJson(Map<String, dynamic> json) => Team(
        id: (json['id'] as String?) ?? (json['team_id'] as String?) ?? '',
        name: (json['name'] as String?) ?? '',
        logoUrl: (json['logoUrl'] as String?) ??
            (json['logo_url'] as String?) ??
            '',
        nextOpponentId: (json['nextOpponentId'] as String?) ??
            (json['next_opponent_id'] as String?) ??
            '',
        record: (json['record'] as String?) ?? '',
      );
}
