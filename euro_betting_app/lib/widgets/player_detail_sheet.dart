import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../services/my_slip_controller.dart';
import '../services/prediction_controller.dart';
import '../services/tips_controller.dart';

class PlayerDetailSheet extends StatelessWidget {
  const PlayerDetailSheet({
    super.key,
    required this.item,
  });

  final TipItem item;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PredictionController>(
      create: (_) => PredictionController(item: item),
      child: const _PlayerDetailSheetBody(),
    );
  }
}

class _PlayerDetailSheetBody extends StatefulWidget {
  const _PlayerDetailSheetBody();

  @override
  State<_PlayerDetailSheetBody> createState() => _PlayerDetailSheetBodyState();
}

class _PlayerDetailSheetBodyState extends State<_PlayerDetailSheetBody> {
  late final TextEditingController _bookieLineController;

  @override
  void initState() {
    super.initState();
    final prediction = context.read<PredictionController>();
    _bookieLineController = TextEditingController(
      text: prediction.bookieLine.toStringAsFixed(1),
    );
  }

  @override
  void dispose() {
    _bookieLineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prediction = context.watch<PredictionController>();
    final item = prediction.item;

    final isUpTrend = item.player.last5GamePts.isNotEmpty &&
        item.player.last5GamePts.last > item.player.last5GamePts.first;

    final lineColor =
        isUpTrend ? const Color(0xFF30D158) : const Color(0xFF8E8E93);

    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    final isRisky = prediction.isRisky;
    final trackColor = isRisky
        ? const Color(0xFFFF453A)
        : const Color(0xFF0A84FF);

    return CupertinoPopupSurface(
      isSurfacePainted: true,
      child: SafeArea(
        top: false,
        child: Container(
          color: const Color(0xFF000000),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _Header(item: item),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _ChartCard(
                  points: item.player.last5GamePts,
                  lineColor: lineColor,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _ComparisonRow(
                  seasonAvgPts: item.player.seasonAvgPts,
                  opponentAllowedPts: item.opponentAllowedPtsToPosition,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _BookieLineCard(
                  controller: _bookieLineController,
                  onChanged: (value) {
                    final parsed = double.tryParse(value.replaceAll(',', '.'));
                    if (parsed == null) {
                      return;
                    }
                    context.read<PredictionController>().bookieLine = parsed;
                  },
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _PredictionSummaryCard(
                  direction: prediction.direction,
                  confidenceScore: prediction.confidenceScore,
                  expectedPoints: prediction.expectedPoints,
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  16 + bottomPadding,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                    borderRadius: BorderRadius.circular(999),
                    color: trackColor,
                    onPressed: () {
                      context.read<MySlipController>().trackBet(
                            TrackedBet(
                              playerId: item.player.id,
                              playerName: item.player.name,
                              line: prediction.bookieLine,
                              direction: prediction.direction,
                              confidenceScore: prediction.confidenceScore,
                              createdAt: DateTime.now(),
                            ),
                          );
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      isRisky ? 'Track Bet (Risky)' : 'Track Bet',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.item,
  });

  final TipItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.player.name,
                style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle,
              ),
              const SizedBox(height: 4),
              Text(
                '${item.team.name} vs ${item.opponent.name}',
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                      fontSize: 13,
                      color: const Color(0xFF8E8E93),
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _LogoPair(
          leftUrl: item.team.logoUrl,
          rightUrl: item.opponent.logoUrl,
        ),
      ],
    );
  }
}

class _LogoPair extends StatelessWidget {
  const _LogoPair({
    required this.leftUrl,
    required this.rightUrl,
  });

  final String leftUrl;
  final String rightUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TeamLogo(url: leftUrl),
        const SizedBox(width: 8),
        _TeamLogo(url: rightUrl),
      ],
    );
  }
}

class _TeamLogo extends StatelessWidget {
  const _TeamLogo({
    required this.url,
  });

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: 38,
        height: 38,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: const Color(0xFF2C2C2E),
            alignment: Alignment.center,
            child: const Icon(
              CupertinoIcons.photo,
              size: 18,
              color: Color(0xFF8E8E93),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.points,
    required this.lineColor,
  });

  final List<double> points;
  final Color lineColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 160,
        child: points.length < 2
            ? Center(
                child: Text(
                  'Not enough game data yet',
                  style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                        fontSize: 13,
                        color: const Color(0xFF8E8E93),
                      ),
                ),
              )
            : LineChart(
                LineChartData(
                  minX: 0,
                  maxX:
                      (points.length - 1).toDouble().clamp(0, double.infinity),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      color: lineColor,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: lineColor.withValues(alpha: 0.15),
                      ),
                      spots: [
                        for (var i = 0; i < points.length; i++)
                          FlSpot(i.toDouble(), points[i]),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _BookieLineCard extends StatelessWidget {
  const _BookieLineCard({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bookie Line',
            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  fontSize: 12,
                  color: const Color(0xFF8E8E93),
                ),
          ),
          const SizedBox(height: 8),
          CupertinoTextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: false,
            ),
            placeholder: '14.5',
            onChanged: onChanged,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }
}

class _PredictionSummaryCard extends StatelessWidget {
  const _PredictionSummaryCard({
    required this.direction,
    required this.confidenceScore,
    required this.expectedPoints,
  });

  final TipDirection direction;
  final double confidenceScore;
  final double expectedPoints;

  @override
  Widget build(BuildContext context) {
    final confidencePct = (confidenceScore * 100).round();
    final directionColor = direction == TipDirection.over
        ? const Color(0xFF30D158)
        : const Color(0xFFFF9F0A);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatColumn(
              label: 'Direction',
              value: direction.name.toUpperCase(),
              valueColor: directionColor,
            ),
          ),
          Container(
            width: 1,
            height: 34,
            color: const Color(0xFF2C2C2E),
          ),
          Expanded(
            child: _StatColumn(
              label: 'Confidence',
              value: '$confidencePct%',
            ),
          ),
          Container(
            width: 1,
            height: 34,
            color: const Color(0xFF2C2C2E),
          ),
          Expanded(
            child: _StatColumn(
              label: 'Expected',
              value: expectedPoints.toStringAsFixed(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.seasonAvgPts,
    required this.opponentAllowedPts,
  });

  final double seasonAvgPts;
  final double opponentAllowedPts;

  @override
  Widget build(BuildContext context) {
    final diff = opponentAllowedPts - seasonAvgPts;
    final diffColor = diff >= 0
        ? const Color(0xFF30D158)
        : const Color(0xFFFF453A);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatColumn(
              label: 'Player Season Avg',
              value: seasonAvgPts.toStringAsFixed(1),
            ),
          ),
          Container(
            width: 1,
            height: 34,
            color: const Color(0xFF2C2C2E),
          ),
          Expanded(
            child: _StatColumn(
              label: 'Opponent Allowed',
              value: opponentAllowedPts.toStringAsFixed(1),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: diffColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: diffColor.withValues(alpha: 0.55),
              ),
            ),
            child: Text(
              diff >= 0
                  ? '+${diff.toStringAsFixed(1)}'
                  : diff.toStringAsFixed(1),
              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: diffColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                fontSize: 12,
                color: const Color(0xFF8E8E93),
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
        ),
      ],
    );
  }
}
