from dataclasses import dataclass
from typing import Optional

@dataclass
class Tournament:
    id: int
    name: str
    type: str  # 'SWISS' or 'ROUND_ROBIN'
    total_rounds: int
    current_round: int
    status: str  # 'SETUP', 'ACTIVE', 'FINISHED'
    created_at: str
    venue: Optional[str] = None

@dataclass
class Player:
    id: int
    tournament_id: int
    name: str
    rating: int
    fide_id: Optional[str] = None
    club: Optional[str] = None
    status: str = 'ACTIVE' # 'ACTIVE', 'WITHDRAWN'
    withdraw_round: Optional[int] = None
    
    # Computed fields
    points: float = 0.0
    tiebreak_score: float = 0.0
    buchholz: float = 0.0
    sonneborn_berger: float = 0.0

@dataclass
class Round:
    id: int
    tournament_id: int
    round_number: int
    status: str  # 'NOT_STARTED', 'IN_PROGRESS', 'LOCKED'
    locked_at: Optional[str] = None
    pairing_mode: str = 'AUTO' # 'AUTO', 'MANUAL'

@dataclass
class Pairing:
    id: int
    round_id: int
    white_player_id: Optional[int]
    black_player_id: Optional[int]
    result: str  # '1-0', '0-1', '0.5-0.5', '*', 'BYE', 'FORFEIT'
    
    # Helper properties for UI display (not in DB)
    white_player_name: Optional[str] = ""
    black_player_name: Optional[str] = ""
