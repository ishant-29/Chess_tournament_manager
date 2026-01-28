from typing import List
from ..models import Player

class RoundRobinEngine:
    def pair_round(self, players: List[Player], round_num: int) -> List[dict]:
        """
        Berger Table pairing logic.
        """
        n = len(players)
        has_bye = False
        
        # Adjust for Berger algorithm (needs even number)
        # CRITICAL FIX: Sort players by ID to ensure consistent position in the table 
        # regardless of standings/points changes.
        players = sorted(players, key=lambda p: p.id)

        if n % 2 != 0:
            players = players + [None] 
            n += 1
            has_bye = True
            
        # Standard Berger Rotation
        # Fix first player, rotate the rest
        # 0     1       2
        # (N-1) (N-2) ...
        
        # Rotation logic
        cycle = players[1:]
        # Rotate cycle for round_num - 1 times
        # Function to rotate list l by k
        k = (round_num - 1) % len(cycle)
        rotated_cycle = cycle[-k:] + cycle[:-k]
        
        full_list = [players[0]] + rotated_cycle
        
        half = n // 2
        top = full_list[:half]
        bottom = full_list[half:][::-1] # Reverse bottom to match
        
        round_pairings = list(zip(top, bottom))
        
        final_pairings = []
        
        for idx, (p1, p2) in enumerate(round_pairings):
            # Alternating colors
            # Player 0 (fixed) alternates
            # Others alternate based on position
            
            white = p1
            black = p2
            
            if idx == 0:
                if round_num % 2 == 0:
                    white, black = black, white
            else:
                if round_num % 2 == 0:
                    white, black = black, white
                    
            # Skip games with withdrawn players
            if (white and white.status == 'WITHDRAWN') or (black and black.status == 'WITHDRAWN'):
                continue

            # Handle Bye
            if white is None:
                final_pairings.append({'white': black, 'black': None, 'result': 'BYE'})
            elif black is None:
                final_pairings.append({'white': white, 'black': None, 'result': 'BYE'})
            else:
                final_pairings.append({'white': white, 'black': black})
                
        return final_pairings
