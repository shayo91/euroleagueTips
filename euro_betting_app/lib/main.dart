import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'screens/analysis_screen.dart';
import 'screens/matches_screen.dart';
import 'screens/settings_screen.dart';
import 'services/data_service.dart';
import 'services/tips_controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    const dataUrl =
        'https://raw.githubusercontent.com/shayo91/euroleagueTips/main/euro_betting_app/data.json';

    return MultiProvider(
      providers: [
        Provider<DataService>(
          create: (_) => DataService(
            dataUrl: dataUrl,
          ),
        ),
        ChangeNotifierProvider<TipsController>(
          create: (context) => TipsController(
            dataService: context.read<DataService>(),
          )..load(),
        ),
      ],
      child: CupertinoApp(
        title: 'EuroEdge',
        theme: CupertinoThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Color(0xFF000000),
          primaryColor: Color(0xFF0A84FF),
          barBackgroundColor: Color(0xFF000000),
        ),
        home: const MainScaffold(),
      ),
    );
  }
}

class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.sportscourt),
            label: 'Matches',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.graph_square),
            label: 'Analysis',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.settings),
            label: 'Settings',
          ),
        ],
      ),
      tabBuilder: (context, index) => CupertinoTabView(
        builder: (context) => switch (index) {
          0 => const MatchesScreen(),
          1 => const AnalysisScreen(),
          2 => const SettingsScreen(),
          _ => const MatchesScreen(),
        },
      ),
    );
  }
}
