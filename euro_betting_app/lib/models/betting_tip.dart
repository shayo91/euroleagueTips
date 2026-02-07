import 'enums.dart';

class BettingTip {
  const BettingTip({
    required this.playerId,
    required this.matchupDescription,
    required this.suggestedLine,
    required this.direction,
    required this.confidenceScore,
    required this.reasoning,
  });

  final String playerId;
  final String matchupDescription;
  final double suggestedLine;
  final TipDirection direction;
  final double confidenceScore;
  final String reasoning;

  factory BettingTip.fromJson(Map<String, dynamic> json) => BettingTip(
        playerId: (json['playerId'] as String?) ?? '',
        matchupDescription: (json['matchupDescription'] as String?) ?? '',
        suggestedLine: (json['suggestedLine'] as num?)?.toDouble() ?? 0.0,
        direction: tipDirectionFromJson(json['direction']),
        confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0.0,
        reasoning: (json['reasoning'] as String?) ?? '',
      );
}
