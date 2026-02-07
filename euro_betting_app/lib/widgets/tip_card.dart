import 'package:flutter/cupertino.dart';

import '../services/tips_controller.dart';

class TipCard extends StatelessWidget {
  const TipCard({
    super.key,
    required this.item,
  });

  final TipItem item;

  @override
  Widget build(BuildContext context) {
    final confidenceColor = _confidenceColor(item.tip.confidenceScore);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Avatar(initials: _initials(item.player.name)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.player.name,
                  style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              _LineBadge(
                text:
                    '${item.tip.direction.name.toUpperCase()} ${item.tip.suggestedLine.toStringAsFixed(1)}',
                backgroundColor: confidenceColor,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.tip.reasoning,
            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  fontSize: 13,
                  color: const Color(0xFF8E8E93),
                ),
          ),
        ],
      ),
    );
  }

  Color _confidenceColor(double confidenceScore) {
    if (confidenceScore >= 0.75) {
      return const Color(0xFF30D158);
    }
    if (confidenceScore >= 0.45) {
      return const Color(0xFFFF9F0A);
    }
    return const Color(0xFF8E8E93);
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) {
      return '?';
    }

    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';

    final initials = (first + last).toUpperCase();
    return initials.isEmpty ? '?' : initials;
  }
}

class _LineBadge extends StatelessWidget {
  const _LineBadge({
    required this.text,
    required this.backgroundColor,
  });

  final String text;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: backgroundColor.withValues(alpha: 0.55),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: backgroundColor,
            ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.initials,
  });

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF2C2C2E),
      ),
      child: Text(
        initials,
        style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFEBEBF5),
            ),
      ),
    );
  }
}
