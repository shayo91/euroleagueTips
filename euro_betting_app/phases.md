## App Architecture & Design 

SystemFramework: Flutter (Mobile).Design System: Cupertino (iOS Native). We are avoiding Material widgets to give it a premium, native iPhone feel.State Management: Provider.Data Flow: Python Scraper (Backend) $\rightarrow$ JSON $\rightarrow$ Flutter App (Frontend).Visual Style: "Dark Sports Analytics" — Pure Black backgrounds (#000000), Dark Grey Cards (#1C1C1E), and Vivid Accent Colors (Green for Over, Red for Under).Phase 1: The iOS Shell (Navigation & Setup)Goal: Create a functional app skeleton with a native iOS Tab Bar and Dark Mode.

### Step 1: Initialize Project (Run in Terminal)Bashflutter create --org com.euroedge euro_betting_app
cd euro_betting_app
flutter pub add provider cupertino_icons google_fonts fl_chart intl
### Step 2: Windsurf Prompt"I am building a Flutter app called EuroEdge to analyze EuroLeague betting stats.Setup Main: Update lib/main.dart. 
Use CupertinoApp (not MaterialApp). Set the theme to CupertinoThemeData with brightness: Brightness.dark, scaffoldBackgroundColor: Color(0xFF000000), and primaryColor: Color(0xFF0A84FF).Navigation: Create a MainScaffold widget using CupertinoTabScaffold.Tabs: Implement 3 tabs with BottomNavigationBarItem:Matches (Icon: sportscourt)Analysis (Icon: graph_square)Settings (Icon: settings)Screens: Create three basic files in lib/screens/: matches_screen.dart, analysis_screen.dart, and settings_screen.dart.Typography: Use GoogleFonts.sfProDisplay (or fallback to generic sans-serif) to mimic Apple's system font.Header: In MatchesScreen, use a CupertinoSliverNavigationBar with a large title 'EuroEdge' so it collapses when scrolling."



## Phase 2: The Moneyball Data Models
Goal: Define the data structures that allow us to calculate "Points vs. Position."

Windsurf Prompt

"I need to define the core data models for the basketball analysis. Create a folder lib/models.

Please create these 4 Data Classes (with fromJson constructors):

Player: id, name, teamId, position (Enum: PG, SG, SF, PF, C), seasonAvgPts (double), last5AvgPts (double), imageUrl.

Team: id, name, logoUrl, nextOpponentId.

DefenseStats: This represents how a team defends specific positions. Fields: teamId, allowedPtsPG, allowedPtsSG, allowedPtsSF, allowedPtsPF, allowedPtsC.

BettingTip: playerId, matchupDescription, suggestedLine (double), direction (Enum: OVER, UNDER), confidenceScore (double 0.0-1.0), reasoning (String).

Mock Data: Create a lib/services/mock_data_service.dart class. Populate it with 4 hardcoded EuroLeague teams (Real Madrid, Monaco, Panathinaikos, Alba Berlin) and 2 key players per team. Crucially: Give 'Alba Berlin' very poor defense stats against 'PG' (Point Guards) so we can test the algorithm later."


## Phase 3: The "Green Light" Algorithm
Goal: The logic engine that compares a Player's average to the Opponent's weakness.

Windsurf Prompt

"Create a new file lib/services/analysis_engine.dart.

Implement a class AnalysisEngine with a static method: List<BettingTip> generateTips(List<Player> players, List<Team> teams, List<DefenseStats> defenses)

The Logic:

Loop through every player.

Find their Team and their Next Opponent.

Find the Opponent's DefenseStats.

The Mismatch Calculation:

Get the player's position (e.g., PG).

Get the Opponent's allowedPtsPG.

Compare allowedPtsPG to the League Average for PGs (assume 11.5 pts for now).

Rule: If Opponent allows > 15% more points than average, it's a 'Green Light' (Defensive Hole).

Create Tip: If a Green Light is found, create a BettingTip with direction: OVER and reasoning: 'Opponent allows X pts to PGs (Worst in League)'.

Sort the list of tips by confidenceScore descending."


## Phase 4: The Dashboard (Matches Tab)
Goal: A high-end, scannable list of betting suggestions.

Windsurf Prompt

"Now let's build the UI for the MatchesScreen.

State: Use Provider to load the MockDataService and run the AnalysisEngine on startup.

Tip Card Widget: Create lib/widgets/tip_card.dart.

Style: Dark Grey Container (Color(0xFF1C1C1E)), rounded corners (16px).

Layout:

Left: Player Avatar (Circle) & Name.

Right: The Betting Line (e.g., 'OVER 14.5') in a bold, colored badge (Green for high confidence).

Bottom: The reasoning text in smaller, grey font (e.g., 'Alba Berlin defense is bottom 3 vs PGs').

List: Use SliverList inside the MatchesScreen to render these cards.

Polish: Add a CupertinoActivityIndicator while data is 'loading'."


## Phase 5: The Deep Dive (Player Detail)
Goal: A modal that opens when you tap a card, showing the math behind the pick.

Windsurf Prompt

"Create a PlayerDetailSheet widget in lib/widgets/.

This should open via showCupertinoModalPopup when a Tip Card is tapped. Design:

Header: Player Name, Team Logo vs Opponent Logo.

Chart: Use fl_chart to show a simple Line Chart of the player's points in the last 5 games. Make the line Green if the trend is up.

Head-to-Head Stat: A row showing 'Player Season Avg' (e.g., 16.2) vs 'Opponent Allowed to Position' (e.g., 18.4). Highlight the difference.

Action Button: A large 'Track Bet' button at the bottom styled like the iOS App Store 'Get' button (Blue, pill-shaped)."



## Phase 6: The Data Source (Python Scraper)
Goal: Create the script to get real EuroLeague data. (Note: Run this outside Flutter).

Windsurf Prompt

"I need a Python script to fetch the data for my app. Create a file scraper/euro_scraper.py.

Use requests and pandas.

Target: The script needs to define a function get_standings() and get_player_stats().

Logic: Since EuroLeague's API is hidden, write a placeholder function that loads a local JSON file (I will provide the JSON structure later).

Export: The script should process the data and save a euro_data.json file containing:

teams: List of teams.

defense_vs_position: A calculated matrix showing how many points each team allows to each position (PG, SG, etc.).

schedule: Next round of games.

Self-Correction: If you can, use BeautifulSoup to sketch out how I would scrape basketball-reference.com/euroleague/ as a fallback source."