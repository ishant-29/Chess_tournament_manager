
import sys
import os

# Add project root to path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from backend.models import Player, Pairing
from backend.pairing.swiss import SwissEngine

def test_club_impact():
    print("--- Test: Club Priority in Pairing ---")
    
    # Create players
    # 2 from Club A, 2 from Club B
    # Sorted by Rating: A1(2000), A2(1950), B1(1900), B2(1850)
    # Standard Swiss (Rating order) would pair:
    #   A1 vs A2 (1 vs 2) -> Club A vs Club A
    #   B1 vs B2 (3 vs 4) -> Club B vs Club B
    #
    # With Club Priority, we expect:
    #   A1 (Club A) looks for non-Club A. Skips A2. Picks B1.
    #   A1 vs B1 (Club A vs Club B)
    #   Remaining: A2, B2
    #   A2 vs B2 (Club A vs Club B)
    
    players = [
        Player(id=1, tournament_id=1, name="Alice", rating=2000, club="Club A"),
        Player(id=2, tournament_id=1, name="Bob", rating=1950, club="Club A"),
        Player(id=3, tournament_id=1, name="Charlie", rating=1900, club="Club B"),
        Player(id=4, tournament_id=1, name="Dave", rating=1850, club="Club B")
    ]
    
    engine = SwissEngine()
    pairings = engine.pair_round(players, [], 1)
    
    for p in pairings:
        w = p['white']
        b = p['black']
        if not b:
            print(f"{w.name} ({w.club}) - BYE")
        else:
            print(f"{w.name} ({w.club}) vs {b.name} ({b.club})")
            
            # Assertion logic
            if w.club == b.club:
                print("  [FAIL] Same club pairing!")
            else:
                print("  [PASS] Different club pairing.")

if __name__ == "__main__":
    test_club_impact()
