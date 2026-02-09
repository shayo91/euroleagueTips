import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show SelectableText;
import 'package:provider/provider.dart';

import '../services/tips_controller.dart';
import '../widgets/player_detail_sheet.dart';
import '../widgets/tip_card.dart';
import '../widgets/tip_card_skeleton.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  Object? _lastShownError;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TipsController>();

    if (!controller.isLoading &&
        controller.error != null &&
        controller.error != _lastShownError) {
      _lastShownError = controller.error;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        showCupertinoDialog<void>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Network Error'),
            content: Text(controller.error.toString()),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () async {
                  Navigator.of(context).pop();
                  await context.read<TipsController>().load();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      });
    }

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
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: TipCardSkeleton(),
                  ),
                  childCount: 5,
                ),
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
