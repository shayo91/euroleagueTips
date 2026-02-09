import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../services/data_service.dart';
import '../services/tips_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isClearing = false;

  Future<void> _clearCache() async {
    setState(() => _isClearing = true);
    try {
      await context.read<DataService>().clearCache();
      if (mounted) {
        // Reload tips with fresh data
        await context.read<TipsController>().load();
        
        showCupertinoDialog<void>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Cache Cleared'),
            content: const Text('Data cache has been cleared and refreshed.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog<void>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to clear cache: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isClearing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          const CupertinoSliverNavigationBar(
            largeTitle: Text('Settings'),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                CupertinoButton.filled(
                  onPressed: _isClearing ? null : _clearCache,
                  child: _isClearing
                      ? const CupertinoActivityIndicator()
                      : const Text('Clear Cache & Refresh Data'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tap the button above to clear the cached data and fetch fresh tips from Euroleague.',
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 14,
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
