import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show SelectableText;
import 'package:provider/provider.dart';

import '../services/tips_controller.dart';
import '../widgets/player_detail_sheet.dart';
import '../widgets/tip_card.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TipsController>();

    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          const CupertinoSliverNavigationBar(
            largeTitle: Text('EuroEdge'),
          ),
          CupertinoSliverRefreshControl(
            onRefresh: () => context.read<TipsController>().load(),
          ),
          if (controller.isLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CupertinoActivityIndicator(),
              ),
            )
          else if (controller.error != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText.rich(
                    TextSpan(
                      text: controller.error.toString(),
                      style: const TextStyle(
                        color: CupertinoColors.systemRed,
                      ),
                    ),
                  ),
                ),
              ),
            )
          else if (controller.items.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text('No tips yet.'),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList.separated(
                itemBuilder: (context, index) {
                  final item = controller.items[index];

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      showCupertinoModalPopup<void>(
                        context: context,
                        builder: (context) => PlayerDetailSheet(
                          item: item,
                        ),
                      );
                    },
                    child: TipCard(
                      item: item,
                    ),
                  );
                },
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemCount: controller.items.length,
              ),
            ),
        ],
      ),
    );
  }
}
