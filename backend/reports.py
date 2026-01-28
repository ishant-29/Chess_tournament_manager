from reportlab.lib.pagesizes import A4
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.lib import colors
from .database import Database

class ReportGenerator:
    def __init__(self, db_path=None):
        self.db = Database(db_path) if db_path else Database()

    def generate_round_report(self, round_id: int, output_path: str):
        """Creates round PDF."""
        
        # Fetch Data
        round_data = self.db.execute_query(
            "SELECT r.round_number, t.name,t.venue, t.id FROM rounds r JOIN tournaments t ON r.tournament_id = t.id WHERE r.id = ?",
            (round_id,)
        )
        if not round_data:
            raise ValueError(f"Round {round_id} not found.")
        
        round_num, tourney_name, tourney_venue, tourney_id = round_data[0]
        
        pairings_data = self.db.execute_query(
            """
            SELECT p.id,
                   p.white_player_id, wp.name, wp.rating, wp.club,
                   p.black_player_id, bp.name, bp.rating, bp.club,
                   p.result
            FROM pairings p
            LEFT JOIN players wp ON p.white_player_id = wp.id
            LEFT JOIN players bp ON p.black_player_id = bp.id
            WHERE p.round_id = ?
            ORDER BY p.id ASC
            """,
            (round_id,)
        )
        
        # Build PDF structure
        doc = SimpleDocTemplate(output_path, pagesize=A4)
        elements = []
        styles = getSampleStyleSheet()
        
        # Header
        elements.append(Paragraph(f"{tourney_name}", styles['Title']))
        elements.append(Paragraph(f"{tourney_venue}", styles['Title']))
        elements.append(Paragraph(f"Round {round_num} Pairings / Results", styles['Heading2']))
        elements.append(Spacer(1, 20))
        
        # Table Data
        data = [['Board', 'White', 'Result', 'Black']]
        for idx, row in enumerate(pairings_data):
            p_id, w_id, w_name, w_rating, w_club, b_id, b_name, b_rating, b_club, result = row
            
            # Format names (include club name if available)
            white_str = w_name if w_name else "BYE"
            if w_name and w_club:
                white_str = f"{w_name} ({w_club})"
                
            black_str = b_name if b_name else "BYE"
            if b_name and b_club:
                black_str = f"{b_name} ({b_club})"
            
            if result == 'BYE':
                if w_name:
                    black_str = ""
                    result = "BYE"
                else:
                    white_str = ""
                    result = "BYE"
            
            # Use Paragraphs to support wrapping for long names/clubs
            w_para = Paragraph(white_str, styles['Normal'])
            b_para = Paragraph(black_str, styles['Normal'])
            
            board_num = str(idx + 1)
            data.append([board_num, w_para, result, b_para])
            
        # Table Style
        table = Table(data, colWidths=[40, 200, 60, 200])
        table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.lightgrey),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.black),
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
            ('BACKGROUND', (0, 1), (-1, -1), colors.white),
            ('GRID', (0, 0), (-1, -1), 1, colors.black),
            ('FONTSIZE', (0, 0), (-1, -1), 10),
            ('ALIGN',(1,1),(-1,-1),'LEFT'), # Align names left
            ('ALIGN',(3,1),(-1,-1),'LEFT'), # Align names left
            ('ALIGN',(2,1),(-1,-1),'CENTER'), # Center result
            ('ALIGN',(0,1),(-1,-1),'CENTER'), # Center board
        ]))
        
        elements.append(table)
        
        # Footer / Signature
        elements.append(Spacer(1, 40))
        elements.append(Paragraph("__________________________", styles['Normal']))
        elements.append(Paragraph("Chief Arbiter Signature", styles['Normal']))
        
        doc.build(elements)
        return output_path

    def generate_standings_report(self, tournament_id: int, output_path: str):
        """Creates standings PDF."""
        
        # 1. Fetch Tournament Info
        t_data = self.db.execute_query(
            "SELECT name,venue, current_round FROM tournaments WHERE id = ?", (tournament_id,)
        )
        if not t_data:
            raise ValueError(f"Tournament {tournament_id} not found.")
        t_name,t_venue, current_round = t_data[0]
        
        # 2. Fetch Players
        players_data = self.db.execute_query(
            "SELECT id, name, club FROM players WHERE tournament_id = ?", (tournament_id,)
        )
        
        player_map = {}
        for row in players_data:
            pid, name, club = row
            player_map[pid] = {
                "name": name,
                "club": club if club else "Independent",
                "points": 0.0
            }
            
        # 3. Calculate Points from Locked Rounds
        pairings = self.db.execute_query(
            """
            SELECT p.white_player_id, p.black_player_id, p.result 
            FROM pairings p 
            JOIN rounds r ON p.round_id = r.id 
            WHERE r.tournament_id = ? AND r.status = 'LOCKED'
            """, (tournament_id,)
        )
        
        for w_id, b_id, res in pairings:
            if res == '*': continue
            w_pts, b_pts = 0.0, 0.0
            if res == '1-0': w_pts = 1.0
            elif res == '0-1': b_pts = 1.0
            elif res == '0.5-0.5': w_pts, b_pts = 0.5, 0.5
            elif res == 'BYE': w_pts = 1.0; b_pts = 1.0 # Handle bye cases if any
            
            if w_id in player_map: player_map[w_id]["points"] += w_pts
            if b_id in player_map: player_map[b_id]["points"] += b_pts
            
        # 4. Sort by points
        sorted_players = sorted(player_map.values(), key=lambda x: x["points"], reverse=True)
        
        # 5. Build PDF
        doc = SimpleDocTemplate(output_path, pagesize=A4)
        elements = []
        styles = getSampleStyleSheet()
        
        elements.append(Paragraph(f"{t_name}", styles['Title']))
        elements.append(Paragraph(f"{t_venue}", styles['Title']))
        elements.append(Paragraph(f"Final Standings (Round {current_round})", styles['Heading2']))
        elements.append(Spacer(1, 20))
        
        data = [['Rank', 'Player Name', 'Club', 'Points']]
        for i, p in enumerate(sorted_players):
            name_para = Paragraph(p["name"], styles['Normal'])
            club_para = Paragraph(p["club"], styles['Normal'])
            data.append([str(i+1), name_para, club_para, str(p["points"])])
            
        table = Table(data, colWidths=[40, 220, 180, 60])
        table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.lightgrey),
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('GRID', (0, 0), (-1, -1), 1, colors.black),
            ('ALIGN', (1, 1), (1, -1), 'LEFT'),
            ('ALIGN', (2, 1), (2, -1), 'LEFT'),
        ]))
        
        elements.append(table)
        elements.append(Spacer(1, 40))
        elements.append(Paragraph("__________________________", styles['Normal']))
        elements.append(Paragraph("Chief Arbiter Signature", styles['Normal']))
        
        doc.build(elements)
        return output_path

    def generate_player_list(self, tournament_id: int, output_path: str):
        """Creates player list PDF."""
        
        # 1. Fetch Tournament Info
        t_data = self.db.execute_query(
            "SELECT name,venue FROM tournaments WHERE id = ?", (tournament_id,)
        )
        if not t_data:
            raise ValueError(f"Tournament {tournament_id} not found.")
        t_name,t_venue = t_data[0]
        
        # 2. Fetch Players (sorted by name)
        players_data = self.db.execute_query(
            "SELECT name, club FROM players WHERE tournament_id = ? ORDER BY name ASC", 
            (tournament_id,)
        )
        
        # 3. Build PDF
        doc = SimpleDocTemplate(output_path, pagesize=A4)
        elements = []
        styles = getSampleStyleSheet()
        
        elements.append(Paragraph(f"{t_name} ", styles['Title']))
        elements.append(Paragraph(f"{t_venue} ", styles['Title']))
        elements.append(Paragraph(f"Registered Players ({len(players_data)} total)", styles['Heading2']))
        elements.append(Spacer(1, 20))
        
        data = [['#', 'Player Name', 'Club/City']]
        for i, row in enumerate(players_data):
            name, club = row
            club_str = club if club else "Independent"
            
            name_para = Paragraph(name, styles['Normal'])
            club_para = Paragraph(club_str, styles['Normal'])
            
            data.append([str(i+1), name_para, club_para])
            
        table = Table(data, colWidths=[40, 250, 210])
        table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.lightgrey),
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('GRID', (0, 0), (-1, -1), 1, colors.black),
            ('ALIGN', (1, 1), (1, -1), 'LEFT'),
            ('ALIGN', (2, 1), (2, -1), 'LEFT'),
        ]))
        
        elements.append(table)
        elements.append(Spacer(1, 40))
        elements.append(Paragraph("__________________________", styles['Normal']))
        elements.append(Paragraph("Chief Arbiter Signature", styles['Normal']))
        
        doc.build(elements)
        return output_path
