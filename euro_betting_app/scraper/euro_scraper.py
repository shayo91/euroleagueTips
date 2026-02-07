from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import pandas as pd
import requests
from bs4 import BeautifulSoup

POSITIONS = ("PG", "SG", "SF", "PF", "C")


@dataclass(frozen=True)
class RawDataPaths:
  raw_json: Path
  output_json: Path


def _read_json(path: Path) -> dict[str, Any]:
  return json.loads(path.read_text(encoding="utf-8"))


def get_standings(raw_json_path: str | Path = "scraper/raw_input.json") -> pd.DataFrame:
  raw = _read_json(Path(raw_json_path))
  rows = raw.get("standings", [])
  return pd.DataFrame(rows)


def get_player_stats(raw_json_path: str | Path = "scraper/raw_input.json") -> pd.DataFrame:
  raw = _read_json(Path(raw_json_path))
  rows = raw.get("player_stats", [])
  return pd.DataFrame(rows)


def _normalize_position(value: Any) -> str:
  raw = str(value).strip().upper()
  if raw in POSITIONS:
    return raw
  mapping = {
    "POINT GUARD": "PG",
    "SHOOTING GUARD": "SG",
    "SMALL FORWARD": "SF",
    "POWER FORWARD": "PF",
    "CENTER": "C",
  }
  if raw in mapping:
    return mapping[raw]
  return "PG"


def calculate_defense_vs_position(
  player_game_logs: pd.DataFrame,
  *,
  opponent_team_id_col: str = "opponent_team_id",
  position_col: str = "position",
  points_col: str = "points",
  game_id_col: str = "game_id",
) -> dict[str, dict[str, float]]:
  if player_game_logs.empty:
    return {}

  df = player_game_logs.copy()
  df[position_col] = df[position_col].map(_normalize_position)
  df[points_col] = pd.to_numeric(df[points_col], errors="coerce").fillna(0.0)

  if game_id_col not in df.columns:
    df[game_id_col] = df.index.astype(str)

  grouped = (
    df.groupby([opponent_team_id_col, position_col, game_id_col])[points_col]
    .sum()
    .reset_index()
  )

  per_game_allowed = (
    grouped.groupby([opponent_team_id_col, position_col])[points_col]
    .mean()
    .reset_index()
  )

  matrix: dict[str, dict[str, float]] = {}
  for _, row in per_game_allowed.iterrows():
    team_id = str(row[opponent_team_id_col])
    position = str(row[position_col])
    allowed = float(row[points_col])

    team_row = matrix.setdefault(team_id, {p: 0.0 for p in POSITIONS})
    team_row[position] = round(allowed, 2)

  return matrix


def build_euro_data(raw_json_path: str | Path) -> dict[str, Any]:
  raw = _read_json(Path(raw_json_path))

  teams = raw.get("teams", [])
  schedule = raw.get("schedule", [])

  player_game_logs_df = pd.DataFrame(raw.get("player_game_logs", []))
  defense_vs_position = calculate_defense_vs_position(player_game_logs_df)

  return {
    "teams": teams,
    "defense_vs_position": defense_vs_position,
    "schedule": schedule,
  }


def save_euro_data(
  *,
  raw_json_path: str | Path = "scraper/raw_input.json",
  output_json_path: str | Path = "scraper/euro_data.json",
) -> Path:
  output_path = Path(output_json_path)
  output_path.parent.mkdir(parents=True, exist_ok=True)

  data = build_euro_data(raw_json_path)
  output_path.write_text(json.dumps(data, indent=2), encoding="utf-8")
  return output_path


def scrape_basketball_reference_euroleague(*, url: str) -> dict[str, Any]:
  response = requests.get(url, timeout=30)
  response.raise_for_status()

  soup = BeautifulSoup(response.text, "html.parser")

  return {
    "source": url,
    "title": soup.title.string.strip() if soup.title and soup.title.string else None,
    "note": (
      "Parsing is intentionally not implemented yet. "
      "Once you confirm the tables you want, we can extract them into DataFrames "
      "and map them into the raw_input.json structure."
    ),
  }


def main(argv: list[str] | None = None) -> int:
  parser = argparse.ArgumentParser()
  parser.add_argument(
    "--raw",
    default="scraper/raw_input.json",
    help="Path to local raw JSON input (placeholder for hidden EuroLeague API).",
  )
  parser.add_argument(
    "--out",
    default="scraper/euro_data.json",
    help="Output path for processed euro_data.json.",
  )

  args = parser.parse_args(argv)
  save_euro_data(raw_json_path=args.raw, output_json_path=args.out)
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
