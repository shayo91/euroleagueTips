from __future__ import annotations

import argparse
import json
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any
from urllib.parse import urljoin

import requests

POSITIONS = ("PG", "SG", "SF", "PF", "C")

EUROLEAGUE_BASE_URL = "https://www.euroleaguebasketball.net"
EUROLEAGUE_TEAMS_URL = "https://www.euroleaguebasketball.net/euroleague/teams/"
EUROLEAGUE_PLAYERS_URL = "https://www.euroleaguebasketball.net/euroleague/players/"


@dataclass(frozen=True)
class RawDataPaths:
  raw_json: Path
  output_json: Path


def _read_json(path: Path) -> dict[str, Any]:
  return json.loads(path.read_text(encoding="utf-8"))


def _get_soup(url: str) -> "BeautifulSoup":
  from bs4 import BeautifulSoup  # type: ignore

  headers = {
    "User-Agent": (
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
      "AppleWebKit/537.36 (KHTML, like Gecko) "
      "Chrome/120.0.0.0 Safari/537.36"
    )
  }

  response = requests.get(url, timeout=30, headers=headers)
  response.raise_for_status()
  return BeautifulSoup(response.text, "html.parser")


def _get_html(url: str) -> str:
  headers = {
    "User-Agent": (
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
      "AppleWebKit/537.36 (KHTML, like Gecko) "
      "Chrome/120.0.0.0 Safari/537.36"
    )
  }
  response = requests.get(url, timeout=30, headers=headers)
  response.raise_for_status()
  return response.text


def _extract_og_meta(soup: "BeautifulSoup", property_name: str) -> str:
  tag = soup.find("meta", attrs={"property": property_name})
  if not tag:
    return ""
  content = tag.get("content")
  return str(content).strip() if content else ""


def _absolute_url(url: str) -> str:
  if not url:
    return ""
  return urljoin(EUROLEAGUE_BASE_URL, url)


def _normalize_player_position(raw: str) -> str:
  value = raw.strip().lower()
  if "point" in value:
    return "PG"
  if "shoot" in value:
    return "SG"
  if "small" in value:
    return "SF"
  if "power" in value:
    return "PF"
  if "center" in value:
    return "C"
  if "guard" in value:
    return "PG"
  if "forward" in value:
    return "SF"
  return "PG"


def _extract_first_float(pattern: str, text: str) -> float | None:
  match = re.search(pattern, text, flags=re.IGNORECASE)
  if not match:
    return None
  try:
    return float(match.group(1))
  except ValueError:
    return None


def _extract_record_from_text(text: str) -> str:
  match = re.search(r"Won\s*W\s*(\d+)\s*Lost\s*L\s*(\d+)", text)
  if not match:
    return ""
  return f"{match.group(1)}-{match.group(2)}"


def _extract_team_code_from_player_html(html: str) -> str:
  # Try to locate a team code in links embedded in the HTML.
  # Example: /en/euroleague/teams/real-madrid/mad/
  match = re.search(r"/en/euroleague/teams/[^/]+/([a-z0-9]{2,4})/", html)
  if match:
    return match.group(1).upper()
  match = re.search(r"/en/euroleague/teams/[^/]+/roster/([a-z0-9]{2,4})/", html)
  if match:
    return match.group(1).upper()
  return ""


def _extract_first_media_image_url(html: str) -> str:
  # EuroLeague pages commonly embed images in JSON/Schema blocks.
  # Prefer media-cdn.* assets over the generic og:image.
  match = re.search(
    r"(https://media-cdn\.[^\s\"']+?\.(?:png|jpg|jpeg|webp|svg))",
    html,
    flags=re.IGNORECASE,
  )
  return match.group(1) if match else ""


def _iter_jsonld_objects(soup: "BeautifulSoup") -> list[dict[str, Any]]:
  objects: list[dict[str, Any]] = []
  for script in soup.find_all("script", attrs={"type": "application/ld+json"}):
    raw = script.string
    if not raw:
      continue
    try:
      parsed = json.loads(raw)
    except json.JSONDecodeError:
      continue

    if isinstance(parsed, list):
      for item in parsed:
        if isinstance(item, dict):
          objects.append(item)
    elif isinstance(parsed, dict):
      objects.append(parsed)

  return objects


def _extract_jsonld_images(soup: "BeautifulSoup") -> list[tuple[str, str]]:
  images: list[tuple[str, str]] = []
  for obj in _iter_jsonld_objects(soup):
    if obj.get("@type") == "ImageObject":
      url = str(obj.get("url", "")).strip()
      desc = str(obj.get("description", "")).strip()
      if url:
        images.append((url, desc))
  return images


def _pick_best_image_url(
  *,
  soup: "BeautifulSoup",
  html: str,
  prefer_description_contains: str,
  fallback_og: str,
) -> str:
  prefer = prefer_description_contains.strip().lower()

  def is_generic(u: str) -> bool:
    return (not u) or u.endswith("/euroleague.png")

  def crop_dims(u: str) -> tuple[int, int] | None:
    # Matches crop=512:512 or crop=512%3A512
    m = re.search(r"crop=(\d+)(?:%3A|:)(\d+)", u)
    if not m:
      return None
    try:
      return int(m.group(1)), int(m.group(2))
    except ValueError:
      return None

  def score(u: str, desc: str) -> tuple[int, int, int, int, int]:
    lu = u.lower()
    ld = desc.lower()
    if is_generic(u):
      return (0, 0, 0, 0, 0)
    if "euroleague logo" in ld:
      return (0, 0, 0, 0, 0)

    type_bonus = 0
    if lu.endswith(".svg") or ".svg?" in lu:
      type_bonus = 3
    elif lu.endswith(".png") or ".png?" in lu:
      type_bonus = 2
    elif lu.endswith(".jpg") or ".jpg?" in lu or lu.endswith(".jpeg") or ".jpeg?" in lu:
      type_bonus = 1

    cdn_bonus = 0
    if "incrowdsports.com" in lu:
      cdn_bonus = 3
    elif "cortextech.io" in lu:
      cdn_bonus = 2

    square_bonus = 0
    dims = crop_dims(u)
    if dims is not None:
      w, h = dims
      if w == h and w >= 256:
        square_bonus = 3
      elif h > 0 and (w / h) > 2.0:
        square_bonus = -2

    prefer_bonus = 1 if (prefer and prefer in ld) else 0
    return (1, prefer_bonus, square_bonus, type_bonus, cdn_bonus)

  candidates: list[tuple[str, str]] = []
  candidates.extend(_extract_jsonld_images(soup))
  if fallback_og:
    candidates.append((fallback_og, prefer_description_contains))
  for u in _extract_all_media_image_urls(html):
    candidates.append((u, ""))

  best_url = ""
  best_score = (0, 0, 0, 0, 0)
  for u, d in candidates:
    s = score(u, d)
    if s > best_score:
      best_score = s
      best_url = u

  return best_url or _extract_first_media_image_url(html) or fallback_og


def _extract_all_media_image_urls(html: str) -> list[str]:
  urls = re.findall(
    r"(https://media-cdn\.[^\s\"']+?\.(?:png|jpg|jpeg|webp|svg)(?:\?[^\s\"']*)?)",
    html,
    flags=re.IGNORECASE,
  )
  # Preserve order while de-duping.
  seen: set[str] = set()
  ordered: list[str] = []
  for u in urls:
    if u in seen:
      continue
    seen.add(u)
    ordered.append(u)
  return ordered


def _pick_best_player_image_url(
  *,
  soup: "BeautifulSoup",
  html: str,
  player_name: str,
  player_id: str,
) -> str:
  # Many player pages embed a direct headshot URL.
  photo_match = re.search(r"\"photo\"\s*:\s*\"(https:[^\"]+)\"", html)
  if photo_match:
    return photo_match.group(1).replace("\\/", "/")

  candidates: list[str] = []

  for url, _ in _extract_jsonld_images(soup):
    candidates.append(url)
  og = _extract_og_meta(soup, "og:image")
  if og:
    candidates.append(og)
  candidates.extend(_extract_all_media_image_urls(html))

  def is_generic(u: str) -> bool:
    return (not u) or u.endswith("/euroleague.png")

  def crop_dims(u: str) -> tuple[int, int] | None:
    m = re.search(r"crop=(\d+)(?:%3A|:)(\d+)", u)
    if not m:
      return None
    try:
      return int(m.group(1)), int(m.group(2))
    except ValueError:
      return None

  def score(u: str) -> tuple[int, int, int, int]:
    lu = u.lower()
    if is_generic(u):
      return (0, 0, 0, 0)

    ext_bonus = 3
    if lu.endswith(".svg") or ".svg?" in lu:
      ext_bonus = 0
    elif lu.endswith(".png") or ".png?" in lu:
      ext_bonus = 3
    elif lu.endswith(".jpg") or ".jpg?" in lu or lu.endswith(".jpeg") or ".jpeg?" in lu:
      ext_bonus = 2

    cdn_bonus = 0
    if "incrowdsports.com" in lu:
      cdn_bonus = 3
    elif "cortextech.io" in lu:
      cdn_bonus = 2

    shape_bonus = 0
    dims = crop_dims(u)
    if dims is not None:
      w, h = dims
      if h > 0:
        ratio = w / h
        # Player headshots tend to be portrait crops. Prefer those.
        if h > w and 0.4 <= ratio <= 0.9:
          shape_bonus = 4
        # Square crops are often team logos/crests on these pages.
        elif w == h:
          shape_bonus = -1
        # Very wide crops are typically banners.
        elif ratio > 2.0:
          shape_bonus = -4

    id_bonus = 1 if (player_id and player_id in lu) else 0
    name_bonus = 1 if (player_name and player_name.lower().split(" ")[0] in lu) else 0
    return (1, shape_bonus + ext_bonus, cdn_bonus, id_bonus + name_bonus)

  best = ""
  best_score = (0, 0, 0, 0)
  for c in candidates:
    s = score(c)
    if s > best_score:
      best_score = s
      best = c

  return best


def _pick_best_team_logo_url(*, soup: "BeautifulSoup", html: str, team_name: str) -> str:
  # Team roster pages often embed the crest explicitly.
  crest_match = re.search(r"\"crest\"\s*:\s*\"(https:[^\"]+)\"", html)
  if crest_match:
    return crest_match.group(1).replace("\\/", "/")

  logo_match = re.search(r"\"logo\"\s*:\s*\"(https:[^\"]+)\"", html)
  if logo_match:
    return logo_match.group(1).replace("\\/", "/")

  candidates: list[str] = []

  for url, _ in _extract_jsonld_images(soup):
    candidates.append(url)

  og = _extract_og_meta(soup, "og:image")
  if og:
    candidates.append(og)

  candidates.extend(_extract_all_media_image_urls(html))

  def crop_dims(u: str) -> tuple[int, int] | None:
    m = re.search(r"crop=(\d+)(?:%3A|:)(\d+)", u)
    if not m:
      return None
    try:
      return int(m.group(1)), int(m.group(2))
    except ValueError:
      return None

  def score(u: str) -> tuple[int, int, int, int]:
    lu = u.lower()
    if (not u) or u.endswith("/euroleague.png"):
      return (0, 0, 0, 0)

    ext_bonus = 0
    if lu.endswith(".svg") or ".svg?" in lu:
      ext_bonus = 3
    elif lu.endswith(".png") or ".png?" in lu:
      ext_bonus = 2
    elif lu.endswith(".jpg") or ".jpg?" in lu or lu.endswith(".jpeg") or ".jpeg?" in lu:
      ext_bonus = 1

    cdn_bonus = 0
    if "incrowdsports.com" in lu:
      cdn_bonus = 3
    elif "cortextech.io" in lu:
      cdn_bonus = 2

    square_bonus = 0
    dims = crop_dims(u)
    if dims is not None:
      w, h = dims
      if w == h and w >= 256:
        square_bonus = 5
      elif h > 0 and (w / h) > 2.0:
        square_bonus = -4

    name_bonus = 0
    if team_name and team_name.strip().lower() in u.lower():
      name_bonus = 1

    return (1, square_bonus, ext_bonus, cdn_bonus + name_bonus)

  best = ""
  best_score = (0, 0, 0, 0)
  for c in candidates:
    s = score(c)
    if s > best_score:
      best_score = s
      best = c

  return best


def _extract_player_ids_from_roster_html(html: str) -> set[str]:
  # Roster pages contain links like:
  # /en/euroleague/players/alberto-abalde/003733/
  ids = set(re.findall(r"/en/euroleague/players/[^/]+/(\d{4,})/", html))
  return ids


def _extract_player_urls_from_roster_html(html: str) -> set[str]:
  urls = set(
    urljoin(EUROLEAGUE_BASE_URL, path)
    for path in set(re.findall(r"(/en/euroleague/players/[^/]+/\d{4,}/)", html))
  )
  return urls


def scrape_team_player_map(*, teams: list[dict[str, Any]]) -> dict[str, str]:
  player_id_to_team_id: dict[str, str] = {}
  for team in teams:
    team_id = str(team.get("id", ""))
    roster_url = str(team.get("rosterUrl", ""))
    if not team_id or not roster_url:
      continue

    roster_html = _get_html(roster_url)
    for player_id in _extract_player_ids_from_roster_html(roster_html):
      player_id_to_team_id.setdefault(player_id, team_id)

  return player_id_to_team_id


def scrape_players_from_rosters(
  *,
  teams: list[dict[str, Any]],
  max_players: int | None = None,
) -> list[dict[str, Any]]:
  player_urls: list[str] = []
  seen: set[str] = set()

  for team in teams:
    roster_url = str(team.get("rosterUrl", ""))
    if not roster_url:
      continue
    roster_html = _get_html(roster_url)
    for url in sorted(_extract_player_urls_from_roster_html(roster_html)):
      if url in seen:
        continue
      seen.add(url)
      player_urls.append(url)
      if max_players is not None and len(player_urls) >= max_players:
        break
    if max_players is not None and len(player_urls) >= max_players:
      break

  players: list[dict[str, Any]] = []
  for url in player_urls:
    details = scrape_player_details(url)
    if details is not None:
      players.append(details)

  return players


def scrape_teams(*, max_teams: int | None = None) -> list[dict[str, Any]]:
  soup = _get_soup(EUROLEAGUE_TEAMS_URL)

  teams: list[dict[str, Any]] = []
  seen_codes: set[str] = set()

  for a in soup.find_all("a", href=True):
    href = str(a["href"])
    if "/en/euroleague/teams/" not in href:
      continue
    if "/roster/" not in href:
      continue

    # Example: /en/euroleague/teams/real-madrid/roster/mad/
    match = re.search(r"/en/euroleague/teams/[^/]+/roster/([a-z0-9]+)/?", href)
    if not match:
      continue

    code = match.group(1).upper()
    if code in seen_codes:
      continue

    name = a.get_text(" ", strip=True)
    if not name:
      continue

    roster_url = _absolute_url(href)
    roster_html = _get_html(roster_url)
    roster_soup = _get_soup(roster_url)
    logo_url = _pick_best_team_logo_url(
      soup=roster_soup,
      html=roster_html,
      team_name=name,
    )
    record = _extract_record_from_text(roster_soup.get_text(" ", strip=True))

    teams.append(
      {
        "id": code,
        "name": name,
        "logoUrl": logo_url,
        "record": record,
        "rosterUrl": roster_url,
      }
    )
    seen_codes.add(code)

    if max_teams is not None and len(teams) >= max_teams:
      break

  return teams


def _extract_team_code_from_player_page(soup: "BeautifulSoup") -> str:
  # Prefer explicit team links like: /en/euroleague/teams/real-madrid/mad/
  for a in soup.find_all("a", href=True):
    href = str(a["href"])
    match = re.search(r"/en/euroleague/teams/[^/]+/([a-z0-9]{2,4})/?", href)
    if match:
      return match.group(1).upper()
    match = re.search(r"/en/euroleague/teams/[^/]+/roster/([a-z0-9]{2,4})/?", href)
    if match:
      return match.group(1).upper()
  return ""


def scrape_player_details(player_url: str) -> dict[str, Any] | None:
  html = _get_html(player_url)
  soup = _get_soup(player_url)

  name = (
    _extract_og_meta(soup, "og:title")
    .replace("| EuroLeague", "")
    .strip()
  )
  if not name:
    return None

  # player id from url: .../players/<slug>/<id>/
  match = re.search(r"/players/[^/]+/(\d{4,})/", player_url)
  if not match:
    return None
  player_id = match.group(1)

  text = soup.get_text(" ", strip=True)
  season_pts = _extract_first_float(r"([0-9]+(?:\.[0-9]+)?)\s*PTS", text) or 0.0

  # Position appears near the header in a stable pattern:
  # "Guard" / "Forward" / "Center" before "Nationality".
  position = "PG"
  pos_match = re.search(r"\b(Guard|Forward|Center)\b\s*Nationality\b", text, flags=re.IGNORECASE)
  if pos_match:
    position = _normalize_player_position(pos_match.group(1))

  team_id = _extract_team_code_from_player_html(html) or _extract_team_code_from_player_page(soup)
  image_url = _pick_best_player_image_url(
    soup=soup,
    html=html,
    player_name=name,
    player_id=player_id,
  )

  return {
    "id": player_id,
    "name": name,
    "teamId": team_id,
    "position": position,
    "imageUrl": image_url,
    "seasonAvgPts": round(float(season_pts), 1),
    "last5AvgPts": round(float(season_pts), 1),
  }


def scrape_players(*, max_players: int | None = None) -> list[dict[str, Any]]:
  soup = _get_soup(EUROLEAGUE_PLAYERS_URL)

  player_urls: list[str] = []
  seen: set[str] = set()
  for a in soup.find_all("a", href=True):
    href = str(a["href"])
    if "/en/euroleague/players/" not in href:
      continue
    if not re.search(r"/en/euroleague/players/[^/]+/\d{4,}/", href):
      continue

    url = _absolute_url(href)
    if url in seen:
      continue

    seen.add(url)
    player_urls.append(url)
    if max_players is not None and len(player_urls) >= max_players:
      break

  players: list[dict[str, Any]] = []
  for url in player_urls:
    details = scrape_player_details(url)
    if details is not None:
      players.append(details)

  return players


def get_standings(raw_json_path: str | Path = "scraper/raw_input.json") -> pd.DataFrame:
  import pandas as pd

  raw = _read_json(Path(raw_json_path))
  rows = raw.get("standings", [])
  return pd.DataFrame(rows)


def get_player_stats(raw_json_path: str | Path = "scraper/raw_input.json") -> pd.DataFrame:
  import pandas as pd

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
  player_game_logs: "pd.DataFrame",
  *,
  opponent_team_id_col: str = "opponent_team_id",
  position_col: str = "position",
  points_col: str = "points",
  game_id_col: str = "game_id",
) -> dict[str, dict[str, float]]:
  import pandas as pd

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
  requested_path = Path(raw_json_path)
  if requested_path.exists():
    raw = _read_json(requested_path)
  else:
    fallback_path = Path("resources/data.json")
    if fallback_path.exists():
      raw = _read_json(fallback_path)
    else:
      raise FileNotFoundError(
        f"Raw input not found: {requested_path}. "
        f"Also missing fallback: {fallback_path}."
      )

  teams = raw.get("teams", [])
  schedule = raw.get("schedule", [])
  players = raw.get("players", [])

  import pandas as pd

  player_game_logs_df = pd.DataFrame(raw.get("player_game_logs", []))
  defense_vs_position = calculate_defense_vs_position(player_game_logs_df)

  return {
    "teams": teams,
    "players": players,
    "defense_vs_position": defense_vs_position,
    "schedule": schedule,
  }


def _generate_mock_schedule(teams: list[dict[str, Any]]) -> list[dict[str, Any]]:
  """Generate a mock schedule for all teams."""
  import datetime
  import itertools
  
  schedule = []
  team_ids = [t.get("id", "") for t in teams if t.get("id")]
  
  # Create simple round-robin schedule
  start_date = datetime.datetime.now() + datetime.timedelta(days=1)
  
  for i, (team_a, team_b) in enumerate(itertools.combinations(team_ids, 2)):
    game_date = start_date + datetime.timedelta(days=(i % 30))
    schedule.append({
      "homeTeamId": team_a,
      "awayTeamId": team_b,
      "gameDate": game_date.isoformat(),
      "gameId": f"{team_a}_vs_{team_b}_{i}",
    })
  
  return schedule


def _generate_mock_defense_stats(
  teams: list[dict[str, Any]],
  players: list[dict[str, Any]],
) -> dict[str, dict[str, float]]:
  """Generate mock defense stats for all teams by position."""
  import random
  
  POSITIONS = ["PG", "SG", "SF", "PF", "C"]
  defense_vs_position = {}
  
  # Calculate league average by position
  position_stats = {pos: {"total": 0.0, "count": 0} for pos in POSITIONS}
  
  for player in players:
    pos = player.get("position", "C")
    avg_pts = player.get("seasonAvgPts", 10.0)
    position_stats[pos]["total"] += avg_pts
    position_stats[pos]["count"] += 1
  
  # Set defaults for missing positions
  league_avg = {}
  for pos in POSITIONS:
    stats = position_stats[pos]
    if stats["count"] > 0:
      league_avg[pos] = stats["total"] / stats["count"]
    else:
      league_avg[pos] = 12.0
  
  # Generate defense stats for each team with intentional variation
  for i, team in enumerate(teams):
    team_id = team.get("id", "")
    if not team_id:
      continue
    
    team_defense = {}
    
    for pos in POSITIONS:
      # Create varied defense stats
      team_pos_idx = i * 5 + POSITIONS.index(pos)
      
      if team_pos_idx % 4 == 0:
        # Weak defender (allows 25-50% more)
        factor = random.uniform(1.25, 1.5)
      elif team_pos_idx % 4 == 1:
        # Strong defender (allows 50-75%)
        factor = random.uniform(0.5, 0.75)
      elif team_pos_idx % 4 == 2:
        # Average
        factor = random.uniform(0.9, 1.1)
      else:
        # Slightly above average
        factor = random.uniform(1.05, 1.2)
      
      allowed_pts = league_avg.get(pos, 12.0) * factor
      allowed_pts = max(3.0, min(25.0, allowed_pts))
      
      team_defense[pos] = round(allowed_pts, 1)
    
    defense_vs_position[team_id] = team_defense
  
  return defense_vs_position


def build_euro_data_live(*, max_teams: int | None = None, max_players: int | None = None) -> dict[str, Any]:
  teams = scrape_teams(max_teams=max_teams)

  player_id_to_team_id = scrape_team_player_map(teams=teams)

  # Prefer roster-based players so teamId is guaranteed.
  players = scrape_players_from_rosters(teams=teams, max_players=max_players)
  if not players:
    players = scrape_players(max_players=max_players)

  # Ensure all players have a teamId that exists.
  team_ids = {t.get("id", "") for t in teams}
  for p in players:
    pid = str(p.get("id", ""))
    mapped = player_id_to_team_id.get(pid, "")
    if mapped:
      p["teamId"] = mapped
    if p.get("teamId") not in team_ids:
      p["teamId"] = ""

  for t in teams:
    t.pop("rosterUrl", None)

  # Generate mock schedule and defense stats
  schedule = _generate_mock_schedule(teams)
  defense_vs_position = _generate_mock_defense_stats(teams, players)

  return {
    "teams": teams,
    "players": players,
    "defense_vs_position": defense_vs_position,
    "schedule": schedule,
  }


def save_to_json(data: dict[str, Any], *, output_path: str | Path) -> Path:
  path = Path(output_path)
  path.parent.mkdir(parents=True, exist_ok=True)
  path.write_text(json.dumps(data, indent=2), encoding="utf-8")
  return path


def save_euro_data(
  *,
  raw_json_path: str | Path = "scraper/raw_input.json",
  output_json_path: str | Path = "scraper/euro_data.json",
) -> Path:
  output_path = Path(output_json_path)
  output_path.parent.mkdir(parents=True, exist_ok=True)

  data = build_euro_data(raw_json_path)
  return save_to_json(data, output_path=output_path)


def scrape_basketball_reference_euroleague(*, url: str) -> dict[str, Any]:
  response = requests.get(url, timeout=30)
  response.raise_for_status()

  try:
    from bs4 import BeautifulSoup  # type: ignore
  except ImportError:  # pragma: no cover
    return {
      "source": url,
      "title": None,
      "note": (
        "BeautifulSoup is not installed. Install with: pip install beautifulsoup4"
      ),
    }

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
    "--live",
    action="store_true",
    help="Scrape live data from euroleaguebasketball.net instead of local raw JSON.",
  )
  parser.add_argument(
    "--max-teams",
    type=int,
    default=None,
    help="Limit number of teams scraped (useful for debugging).",
  )
  parser.add_argument(
    "--max-players",
    type=int,
    default=None,
    help="Limit number of players scraped (useful for debugging).",
  )
  parser.add_argument(
    "--raw",
    default="scraper/raw_input.json",
    help="Path to local raw JSON input (placeholder for hidden EuroLeague API).",
  )
  parser.add_argument(
    "--out",
    default="resources/data.json",
    help="Output path for processed data.json (relative to repo root).",
  )

  args = parser.parse_args(argv)

  print("Fetching fresh EuroLeague data...")
  try:
    if args.live:
      data = build_euro_data_live(max_teams=args.max_teams, max_players=args.max_players)
    else:
      data = build_euro_data(args.raw)
  except ImportError as e:
    raise SystemExit(
      "Missing dependency for scraping. Install with: pip install beautifulsoup4\n"
      f"Details: {e}"
    )

  print(
    f"Scraped {len(data.get('teams', []))} teams and {len(data.get('players', []))} players."
  )
  save_to_json(data, output_path=args.out)
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
