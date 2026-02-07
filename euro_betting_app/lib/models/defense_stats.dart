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
        teamId: (json['teamId'] as String?) ?? '',
        allowedPtsPG: (json['allowedPtsPG'] as num?)?.toDouble() ?? 0.0,
        allowedPtsSG: (json['allowedPtsSG'] as num?)?.toDouble() ?? 0.0,
        allowedPtsSF: (json['allowedPtsSF'] as num?)?.toDouble() ?? 0.0,
        allowedPtsPF: (json['allowedPtsPF'] as num?)?.toDouble() ?? 0.0,
        allowedPtsC: (json['allowedPtsC'] as num?)?.toDouble() ?? 0.0,
      );
}
