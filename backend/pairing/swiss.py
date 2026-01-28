import random
from typing import List, Tuple, Dict, Set, Optional
from ..models import Player, Pairing

class SwissEngine:
    def __init__(self):
        pass

    def pair_round(self, players: List[Player], past_pairings: List[Pairing], round_num: int) -> List[dict]:
        """
        Standard Dutch Swiss pairing.
        Returns pairings list.
        """

        # Exclude withdrawn players
        active_players = [p for p in players if p.status != 'WITHDRAWN']
        print(f"Pairing {len(active_players)} active players")
        players = active_players

        # Sort by points (primary) and rating (secondary)
        players.sort(key=lambda p: (p.points, p.rating), reverse=True)

        # Load history to avoid repeat matchups
        played_games: Set[frozenset] = set()
        from collections import defaultdict
        player_colors: Dict[int, List[str]] = defaultdict(list)
        # Initialize for active players to ensure they exist even if empty history
        for p in players:
            player_colors[p.id] = []
        
        
        for p in past_pairings:
            if p.white_player_id and p.black_player_id:
                played_games.add(frozenset([p.white_player_id, p.black_player_id]))
                player_colors[p.white_player_id].append('W')
                player_colors[p.black_player_id].append('B')
            elif p.result == 'BYE':
                if p.white_player_id: player_colors[p.white_player_id].append('BYE') # Simplify bye tracking

        print(f"History loaded. Played pairs: {len(played_games)}")


        # Handle Bye for odd number of players
        bye_player = None
        if len(players) % 2 != 0:
            # Find lowest scoring player who hasn't had a bye
            for i in range(len(players) - 1, -1, -1):
                p = players[i]
                if 'BYE' not in player_colors[p.id]:
                    bye_player = players.pop(i)
                    break
            # If everyone had a bye (rare/impossible in standard length), just pick lowest
            if not bye_player and players:
                bye_player = players.pop()

        pairings = []

        # Group by Score
        score_groups = {}
        for p in players:
            score = p.points
            if score not in score_groups:
                score_groups[score] = []
            score_groups[score].append(p)
        
        sorted_scores = sorted(score_groups.keys(), reverse=True)
        
        leftovers = []
        
        for score in sorted_scores:
            group = score_groups[score]
            # Add leftovers from previous higher score group
            # Insert them at the top (highest rating of floaters usually)
            if leftovers:
                group = leftovers + group
                leftovers = []
            
            while len(group) >= 2:
                p1 = group.pop(0)
                
                found_opponent = None
                found_idx = -1
                
                # Scan all candidates
                for i, p2 in enumerate(group):
                    # PRIORITIZE DIFFERENT CLUBS
                    # 1. Try to find an opponent from a different club first
                    if p1.club and p2.club and p1.club == p2.club:
                        # Same club - skip for now, unless we can't find anyone else
                        continue
                        
                    found_opponent = p2
                    found_idx = i
                    break
                
                # If no different-club opponent found, fallback to any valid opponent (Same Club)
                if not found_opponent:
                     for i, p2 in enumerate(group):
                        found_opponent = p2
                        found_idx = i
                        break
                
                if found_opponent:
                    group.pop(found_idx)
                    w, b = self._assign_colors(p1, found_opponent, player_colors)
                    pairings.append({'white': w, 'black': b})
                else:
                    # No valid opponent in this group for p1
                    # p1 must float down
                    leftovers.append(p1)
            
            # If 1 player remains in group, they float
            if group:
                leftovers.extend(group)
        
        # Handle final leftovers (BYE)
        if leftovers:
            p = leftovers.pop(0)
            pairings.append({'white': p, 'black': None, 'result': 'BYE'})
            # If any more leftovers (shouldn't happen if odd check was done, but logic might produce >1 floater at end)
            for p_extra in leftovers:
                 pairings.append({'white': p_extra, 'black': None, 'result': 'BYE'})

        if bye_player:
            pairings.append({'white': bye_player, 'black': None, 'result': 'BYE'})
            
        return pairings

    def _get_color_balance(self, history: List[str]) -> int:
        """Returns >0 if needs Black, <0 if needs White"""
        w = history.count('W')
        b = history.count('B')
        return w - b

    def _assign_colors(self, p1, p2, history_dict):
        bal1 = self._get_color_balance(history_dict[p1.id])
        bal2 = self._get_color_balance(history_dict[p2.id])
        
        # p1 needs Black (bal1 > 0), p2 needs White (bal2 < 0) -> Natural
        if bal1 > bal2:
            return p2, p1 # p2 is White
        elif bal2 > bal1:
            return p1, p2 # p1 is White
        else:
            # Alternating history
            hist1 = history_dict[p1.id]
            last1 = hist1[-1] if hist1 else 'B' # Default to White if new (so last was 'B')
            
            if last1 == 'W':
                return p2, p1
            else:
                return p1, p2
