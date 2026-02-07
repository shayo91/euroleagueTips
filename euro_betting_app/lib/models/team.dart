class Team {
  const Team({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.nextOpponentId,
  });

  final String id;
  final String name;
  final String logoUrl;
  final String nextOpponentId;

  factory Team.fromJson(Map<String, dynamic> json) => Team(
        id: (json['id'] as String?) ?? (json['team_id'] as String?) ?? '',
        name: (json['name'] as String?) ?? '',
        logoUrl: (json['logoUrl'] as String?) ??
            (json['logo_url'] as String?) ??
            '',
        nextOpponentId: (json['nextOpponentId'] as String?) ??
            (json['next_opponent_id'] as String?) ??
            '',
      );
}
