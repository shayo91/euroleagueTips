class DefenseStats {
  const DefenseStats({
    required this.teamId,
    required this.allowedPtsPG,
    required this.allowedPtsSG,
    required this.allowedPtsSF,
    required this.allowedPtsPF,
    required this.allowedPtsC,
  });

  final String teamId;
  final double allowedPtsPG;
  final double allowedPtsSG;
  final double allowedPtsSF;
  final double allowedPtsPF;
  final double allowedPtsC;

  factory DefenseStats.fromJson(Map<String, dynamic> json) => DefenseStats(
        teamId: (json['teamId'] as String?) ?? (json['team_id'] as String?) ?? '',
        allowedPtsPG: (json['allowedPtsPG'] as num?)?.toDouble() ??
            (json['allowed_pts_pg'] as num?)?.toDouble() ??
            0.0,
        allowedPtsSG: (json['allowedPtsSG'] as num?)?.toDouble() ??
            (json['allowed_pts_sg'] as num?)?.toDouble() ??
            0.0,
        allowedPtsSF: (json['allowedPtsSF'] as num?)?.toDouble() ??
            (json['allowed_pts_sf'] as num?)?.toDouble() ??
            0.0,
        allowedPtsPF: (json['allowedPtsPF'] as num?)?.toDouble() ??
            (json['allowed_pts_pf'] as num?)?.toDouble() ??
            0.0,
        allowedPtsC: (json['allowedPtsC'] as num?)?.toDouble() ??
            (json['allowed_pts_c'] as num?)?.toDouble() ??
            0.0,
      );

  factory DefenseStats.fromDefenseVsPosition(
    String teamId,
    Map<String, dynamic> json,
  ) =>
      DefenseStats(
        teamId: teamId,
        allowedPtsPG: (json['PG'] as num?)?.toDouble() ??
            (json['pg'] as num?)?.toDouble() ??
            0.0,
        allowedPtsSG: (json['SG'] as num?)?.toDouble() ??
            (json['sg'] as num?)?.toDouble() ??
            0.0,
        allowedPtsSF: (json['SF'] as num?)?.toDouble() ??
            (json['sf'] as num?)?.toDouble() ??
            0.0,
        allowedPtsPF: (json['PF'] as num?)?.toDouble() ??
            (json['pf'] as num?)?.toDouble() ??
            0.0,
        allowedPtsC: (json['C'] as num?)?.toDouble() ??
            (json['c'] as num?)?.toDouble() ??
            0.0,
      );
}
