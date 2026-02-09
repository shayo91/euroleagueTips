#!/usr/bin/env python3
"""Quickly populate schedule and defense stats in data.json"""

import json
from datetime import datetime, timedelta
import random
from pathlib import Path

data_path = Path(__file__).parent.parent / 'resources' / 'data.json'

with open(data_path) as f:
    data = json.load(f)

teams = data.get('teams', [])
players = data.get('players', [])
team_ids = [t['id'] for t in teams]

# Generate schedule
schedule = []
import itertools
start_date = datetime.now() + timedelta(days=1)
for i, (team_a, team_b) in enumerate(itertools.combinations(team_ids, 2)):
    game_date = start_date + timedelta(days=(i % 30))
    schedule.append({
        "homeTeamId": team_a,
        "awayTeamId": team_b,
        "gameDate": game_date.isoformat(),
        "gameId": f"{team_a}_vs_{team_b}_{i}"
    })

# Generate defense stats
positions = ['PG', 'SG', 'SF', 'PF', 'C']
position_stats = {pos: {'total': 0, 'count': 0} for pos in positions}

for player in players:
    pos = player.get('position', 'C')
    avg_pts = player.get('seasonAvgPts', 10)
    position_stats[pos]['total'] += avg_pts
    position_stats[pos]['count'] += 1

league_avg = {}
for pos in positions:
    stats = position_stats[pos]
    league_avg[pos] = stats['total'] / max(1, stats['count'])

defense_vs_position = {}
for i, team in enumerate(teams):
    team_id = team['id']
    team_defense = {}
    
    for pos in positions:
        team_pos_idx = i * 5 + positions.index(pos)
        
        if team_pos_idx % 4 == 0:
            factor = random.uniform(1.25, 1.5)
        elif team_pos_idx % 4 == 1:
            factor = random.uniform(0.5, 0.75)
        elif team_pos_idx % 4 == 2:
            factor = random.uniform(0.9, 1.1)
        else:
            factor = random.uniform(1.05, 1.2)
        
        allowed_pts = league_avg.get(pos, 12.0) * factor
        allowed_pts = max(3.0, min(25.0, allowed_pts))
        
        team_defense[pos] = round(allowed_pts, 1)
    
    defense_vs_position[team_id] = team_defense

# Update data
data['schedule'] = schedule
data['defense_vs_position'] = defense_vs_position

# Save
with open(data_path, 'w') as f:
    json.dump(data, f, indent=2)

print(f'✓ Generated {len(schedule)} games')
print(f'✓ Generated defense stats for {len(defense_vs_position)} teams')
print('✓ Saved to resources/data.json')
