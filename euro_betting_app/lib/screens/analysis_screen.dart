import 'package:flutter/cupertino.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text('Analysis'),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text('Analysis placeholder'),
            ),
          ),
        ],
      ),
    );
  }
}
