import '../models/defense_stats.dart';
import '../models/enums.dart';
import '../models/player.dart';
import '../models/team.dart';

class MockDataService {
  const MockDataService();

  static const realMadrid = Team(
    id: 'rm',
    name: 'Real Madrid',
    logoUrl: 'https://example.com/logos/real_madrid.png',
    nextOpponentId: 'asm',
  );

  static const monaco = Team(
    id: 'asm',
    name: 'Monaco',
    logoUrl: 'https://example.com/logos/monaco.png',
    nextOpponentId: 'rm',
  );

  static const panathinaikos = Team(
    id: 'pao',
    name: 'Panathinaikos',
    logoUrl: 'https://example.com/logos/panathinaikos.png',
    nextOpponentId: 'alb',
  );

  static const albaBerlin = Team(
    id: 'alb',
    name: 'Alba Berlin',
    logoUrl: 'https://example.com/logos/alba_berlin.png',
    nextOpponentId: 'pao',
  );

  List<Team> getTeams() => const [
        realMadrid,
        monaco,
        panathinaikos,
        albaBerlin,
      ];

  List<Player> getPlayers() => const [
        Player(
          id: 'rm_pg_1',
          name: 'Facundo Campazzo',
          teamId: 'rm',
          position: PlayerPosition.pg,
          seasonAvgPts: 12.1,
          last5AvgPts: 13.4,
          last5GamePts: [12, 14, 15, 13, 13],
          imageUrl: 'https://example.com/players/campazzo.png',
        ),
        Player(
          id: 'rm_c_1',
          name: 'Walter Tavares',
          teamId: 'rm',
          position: PlayerPosition.c,
          seasonAvgPts: 11.3,
          last5AvgPts: 12.0,
          last5GamePts: [10, 12, 11, 13, 14],
          imageUrl: 'https://example.com/players/tavares.png',
        ),
        Player(
          id: 'asm_pg_1',
          name: 'Mike James',
          teamId: 'asm',
          position: PlayerPosition.pg,
          seasonAvgPts: 16.9,
          last5AvgPts: 18.2,
          last5GamePts: [15, 17, 19, 20, 20],
          imageUrl: 'https://example.com/players/mike_james.png',
        ),
        Player(
          id: 'asm_pf_1',
          name: 'John Brown',
          teamId: 'asm',
          position: PlayerPosition.pf,
          seasonAvgPts: 8.6,
          last5AvgPts: 9.1,
          last5GamePts: [7, 9, 10, 8, 12],
          imageUrl: 'https://example.com/players/john_brown.png',
        ),
        Player(
          id: 'pao_sg_1',
          name: 'Kendrick Nunn',
          teamId: 'pao',
          position: PlayerPosition.sg,
          seasonAvgPts: 14.7,
          last5AvgPts: 15.9,
          last5GamePts: [13, 16, 15, 17, 18],
          imageUrl: 'https://example.com/players/nunn.png',
        ),
        Player(
          id: 'pao_c_1',
          name: 'Mathias Lessort',
          teamId: 'pao',
          position: PlayerPosition.c,
          seasonAvgPts: 12.4,
          last5AvgPts: 13.1,
          last5GamePts: [11, 12, 14, 13, 15],
          imageUrl: 'https://example.com/players/lessort.png',
        ),
        Player(
          id: 'alb_pg_1',
          name: 'Sterling Brown',
          teamId: 'alb',
          position: PlayerPosition.pg,
          seasonAvgPts: 10.8,
          last5AvgPts: 11.6,
          last5GamePts: [9, 10, 12, 13, 14],
          imageUrl: 'https://example.com/players/sterling_brown.png',
        ),
        Player(
          id: 'alb_sf_1',
          name: 'Johannes Thiemann',
          teamId: 'alb',
          position: PlayerPosition.sf,
          seasonAvgPts: 9.9,
          last5AvgPts: 10.3,
          last5GamePts: [8, 10, 11, 10, 12],
          imageUrl: 'https://example.com/players/thiemann.png',
        ),
      ];

  List<DefenseStats> getDefenseStats() => const [
        DefenseStats(
          teamId: 'rm',
          allowedPtsPG: 20.5,
          allowedPtsSG: 19.8,
          allowedPtsSF: 20.1,
          allowedPtsPF: 21.0,
          allowedPtsC: 18.9,
        ),
        DefenseStats(
          teamId: 'asm',
          allowedPtsPG: 21.3,
          allowedPtsSG: 20.7,
          allowedPtsSF: 20.9,
          allowedPtsPF: 21.8,
          allowedPtsC: 20.1,
        ),
        DefenseStats(
          teamId: 'pao',
          allowedPtsPG: 20.9,
          allowedPtsSG: 20.2,
          allowedPtsSF: 21.5,
          allowedPtsPF: 20.6,
          allowedPtsC: 19.7,
        ),
        DefenseStats(
          teamId: 'alb',
          allowedPtsPG: 28.7,
          allowedPtsSG: 22.8,
          allowedPtsSF: 22.1,
          allowedPtsPF: 23.0,
          allowedPtsC: 22.4,
        ),
      ];
}
