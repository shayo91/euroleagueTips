enum PlayerPosition {
  pg,
  sg,
  sf,
  pf,
  c,
}

enum TipDirection {
  over,
  under,
}

PlayerPosition playerPositionFromJson(Object? value) {
  final raw = value?.toString().toLowerCase();
  return switch (raw) {
    'pg' => PlayerPosition.pg,
    'sg' => PlayerPosition.sg,
    'sf' => PlayerPosition.sf,
    'pf' => PlayerPosition.pf,
    'c' => PlayerPosition.c,
    _ => throw FormatException('Unknown PlayerPosition: $value'),
  };
}

TipDirection tipDirectionFromJson(Object? value) {
  final raw = value?.toString().toLowerCase();
  return switch (raw) {
    'over' => TipDirection.over,
    'under' => TipDirection.under,
    _ => throw FormatException('Unknown TipDirection: $value'),
  };
}
