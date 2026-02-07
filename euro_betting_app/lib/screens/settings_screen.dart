import 'package:flutter/cupertino.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text('Settings'),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text('Settings placeholder'),
            ),
          ),
        ],
      ),
    );
  }
}
