#!/usr/bin/env python3
"""Generate mock schedule and defense stats for demo purposes."""

import json
from pathlib import Path
from datetime import datetime, timedelta
import random

def generate_schedule(teams):
    """Generate upcoming games schedule."""
    schedule = []
    team_ids = [t['id'] for t in teams]
    
    # Create a simple round-robin style schedule
    start_date = datetime.now() + timedelta(days=1)
    
    for i, home_team in enumerate(team_ids):
        for j, away_team in enumerate(team_ids):
            if i < j:  # Avoid duplicate matchups
                game_date = start_date + timedelta(days=(i + j) % 30)
                schedule.append({
                    'homeTeamId': home_team,
                    'awayTeamId': away_team,
                    'gameDate': game_date.isoformat(),
                    'gameId': f"{home_team}_vs_{away_team}_{i}_{j}"
                })
    
    return schedule


def generate_defense_stats(teams, players):
    """Generate defensive statistics for each team by position."""
    positions = ['PG', 'SG', 'SF', 'PF', 'C']
    defense_vs_position = {}
    
    # Calculate league average by position
    position_stats = {pos: {'total': 0, 'count': 0} for pos in positions}
    
    for player in players:
        pos = player.get('position', 'C')
        avg_pts = player.get('seasonAvgPts', 10)
        position_stats[pos]['total'] += avg_pts
        position_stats[pos]['count'] += 1
    
    # Set defaults for missing positions
    league_avg = {}
    for pos in positions:
        stats = position_stats[pos]
        if stats['count'] > 0:
            league_avg[pos] = stats['total'] / stats['count']
        else:
            # Use default league average for positions with no players in data
            league_avg[pos] = 12.0
    
    # Generate defense stats for each team
    for team in teams:
        team_id = team['id']
        team_defense = {}
        
        for pos in positions:
            # Vary between 75% and 125% of league average
            factor = random.uniform(0.75, 1.25)
            allowed_pts = league_avg.get(pos, 12.0) * factor
            # Ensure minimum of 5 points
            allowed_pts = max(5.0, allowed_pts)
            
            team_defense[pos] = round(allowed_pts, 1)
        
        defense_vs_position[team_id] = team_defense
    
    return defense_vs_position


def main():
    data_path = Path(__file__).parent.parent / 'resources' / 'data.json'
    
    if not data_path.exists():
        print(f"ERROR: {data_path} not found")
        return 1
    
    # Load existing data
    with open(data_path) as f:
        data = json.load(f)
    
    teams = data.get('teams', [])
    players = data.get('players', [])
    
    if not teams:
        print("ERROR: No teams found in data.json")
        return 1
    
    # Generate schedule and defense stats
    schedule = generate_schedule(teams)
    defense_vs_position = generate_defense_stats(teams, players)
    
    # Update data
    data['schedule'] = schedule
    data['defense_vs_position'] = defense_vs_position
    
    # Save back to file
    with open(data_path, 'w') as f:
        json.dump(data, f, indent=2)
    
    print(f"✓ Generated {len(schedule)} games in schedule")
    print(f"✓ Generated defense stats for {len(defense_vs_position)} teams")
    print(f"✓ Saved to {data_path}")
    
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
