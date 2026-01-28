from .database import Database
from .models import Player

class TieBreaks:
    def __init__(self, db: Database):
        self.db = db

    def update_tiebreaks(self, tournament_id: int):
        """Recalculate Buchholz and Sonneborn-Berger for all players in the tournament."""
        players_data = self.db.execute_query(
            "SELECT id, points FROM players WHERE tournament_id = ?", (tournament_id,)
        )
        players = {row[0]: row[1] for row in players_data} # id -> points

        for player_id in players.keys():
            buchholz = 0.0
            sb_score = 0.0
            
            # Get all opponents
            # As White
            opponents_white = self.db.execute_query(
                """
                SELECT p.black_player_id, p.result FROM pairings p
                JOIN rounds r ON p.round_id = r.id
                WHERE r.tournament_id = ? AND p.white_player_id = ? AND p.black_player_id IS NOT NULL
                """, (tournament_id, player_id)
            )
            
            # As Black
            opponents_black = self.db.execute_query(
                """
                SELECT p.white_player_id, p.result FROM pairings p
                JOIN rounds r ON p.round_id = r.id
                WHERE r.tournament_id = ? AND p.black_player_id = ? AND p.white_player_id IS NOT NULL
                """, (tournament_id, player_id)
            )

            all_games = []
            for opp_id, res in opponents_white:
                all_games.append({'opp_id': opp_id, 'result': res, 'role': 'white'})
            for opp_id, res in opponents_black:
                all_games.append({'opp_id': opp_id, 'result': res, 'role': 'black'})
            
            for game in all_games:
                opp_id = game['opp_id']
                opp_points = players.get(opp_id, 0.0)
                
                # Buchholz: Sum of opponents' scores
                buchholz += opp_points
                
                # Sonneborn-Berger: 
                # Sum of scores of opponents beaten + 
                # 0.5 * Sum of scores of opponents drawn
                result = game['result']
                role = game['role']
                
                score_vs_opp = 0.0
                if result == '1-0':
                    score_vs_opp = 1.0 if role == 'white' else 0.0
                elif result == '0-1':
                    score_vs_opp = 0.0 if role == 'white' else 1.0
                elif result == '0.5-0.5':
                    score_vs_opp = 0.5
                elif result == 'BYE': # Bye usually doesn't count for SB in some variations, but treating as win vs virtual 0-point opponent
                     pass # Simplified: Bye adds nothing to SB usually as opp score is 0
                
                if score_vs_opp == 1.0:
                    sb_score += opp_points
                elif score_vs_opp == 0.5:
                    sb_score += 0.5 * opp_points
            
            self.db.execute_non_query(
                "UPDATE players SET buchholz = ?, sonneborn_berger = ?, tiebreak_score = ? WHERE id = ?",
                (buchholz, sb_score, buchholz, player_id)
            )
            print(f"DEBUG: Updated player {player_id} - Points: {players.get(player_id)}, BH: {buchholz}, SB: {sb_score}")

