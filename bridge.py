import sys
import os
import csv
from datetime import datetime
import json
from PyQt5.QtCore import QObject, pyqtSlot, pyqtSignal, pyqtProperty, QVariant, QAbstractListModel, Qt


def get_app_path():
    if getattr(sys, 'frozen', False):
        return os.path.dirname(sys.executable)
    return os.getcwd()

APP_STATE_FILE = os.path.join(get_app_path(), "app_state.json")

# Backend imports
from backend.database import Database, DB_PATH
from backend.models import Player, Tournament, Round, Pairing
from backend.pairing.swiss import SwissEngine
from backend.pairing.round_robin import RoundRobinEngine
from backend.undo_manager import UndoManager, UndoAction
from backend.settings_manager import SettingsManager
from backend.backup_manager import BackupManager

class BackendBridge(QObject):
    # UI Signals
    tournamentChanged = pyqtSignal()
    playersChanged = pyqtSignal()
    pairingsChanged = pyqtSignal()
    standingsChanged = pyqtSignal()
    roundsChanged = pyqtSignal()
    notification = pyqtSignal(str, str)
    
    # Feature signals
    playerUpdated = pyqtSignal()
    settingsChanged = pyqtSignal()
    undoAvailable = pyqtSignal(bool, str)
    backupCreated = pyqtSignal(str)
    backupRestored = pyqtSignal()

    def __init__(self):
        super().__init__()
        self.db = Database()
        self.swiss_engine = SwissEngine()
        self.rr_engine = RoundRobinEngine()
        
        self.undo_manager = UndoManager(max_size=10)
        self.settings_manager = SettingsManager(self.db.db_path)
        self.backup_manager = BackupManager()
        
        # Load undo stack size from settings
        undo_size = self.settings_manager.get_int('undo_stack_size', 10)
        self.undo_manager.max_size = undo_size
        
        self._current_tournament = None
        self._players = []
        self._pairings = []
        self._standings = []
        self._round_status = ""
        self._viewing_round = 0  # Track which round is being viewed

        # Try to recover previous session
        self._restore_app_state()

    def _restore_app_state(self):
        try:
            if os.path.exists(APP_STATE_FILE):
                with open(APP_STATE_FILE, 'r') as f:
                    state = json.load(f)
                    last_tid = state.get('last_tournament_id')
                    last_round = state.get('last_viewing_round')
                    
                    if last_tid:
                        print(f"Restoring last session: Tournament {last_tid}")
                        self.loadTournament(last_tid)
                        
                        if last_round and self._current_tournament:
                            if last_round <= self._current_tournament.current_round:
                                self.setViewRound(last_round)
        except Exception as e:
            print(f"Failed to restore state: {e}")

    def _save_app_state(self):
        try:
            state = {
                'last_tournament_id': self._current_tournament.id if self._current_tournament else None,
                'last_viewing_round': self._viewing_round
            }
            with open(APP_STATE_FILE, 'w') as f:
                json.dump(state, f)
        except Exception as e:
            print(f"Failed to save state: {e}")

    # --- Properties ---
    @pyqtProperty(QVariant, notify=tournamentChanged)
    def currentTournament(self):
        if self._current_tournament:
            return vars(self._current_tournament)
        return None

    @pyqtProperty(int, notify=tournamentChanged)
    def viewingRoundNumber(self):
        if self._viewing_round > 0:
            return self._viewing_round
        if self._current_tournament:
            return self._current_tournament.current_round
        return 0

    @pyqtProperty(bool, notify=tournamentChanged)
    def isViewingPastRound(self):
        if not self._current_tournament: return False
        return self._viewing_round > 0 and self._viewing_round < self._current_tournament.current_round
        
    @pyqtProperty(bool, notify=roundsChanged)
    def isRoundLocked(self):
        # Check if the currently viewed round is locked
        if not self._current_tournament: return False
        r_num = self._viewing_round if self._viewing_round > 0 else self._current_tournament.current_round
        
        # Query status
        rdata = self.db.execute_query("SELECT status FROM rounds WHERE tournament_id = ? AND round_number = ?", 
                                      (self._current_tournament.id, r_num))
        if rdata and rdata[0][0] == 'LOCKED':
            return True
        return False

    @pyqtProperty(list, notify=playersChanged)
    def playerList(self):
        return [vars(p) for p in self._players]

    @pyqtProperty(list, notify=pairingsChanged)
    def pairingList(self):
        return [vars(p) for p in self._pairings]

    @pyqtProperty(list, notify=standingsChanged)
    def standingsList(self):
        return [vars(p) for p in self._standings]

    # --- Slots (Public Methods) ---

    # --- Slots ---

    @pyqtSlot(str, str, int, str)
    def createTournament(self, name, t_type, rounds, venue):
        try:
            query = "INSERT INTO tournaments (name, type, total_rounds, status, venue) VALUES (?, ?, ?, 'SETUP', ?)"
            tid = self.db.execute_non_query(query, (name, t_type, rounds, venue))
            self.loadTournament(tid)
            self.notification.emit("Success", f"Tournament '{name}' created!")
        except Exception as e:
            self.notification.emit("Error", str(e))

    @pyqtSlot(int)
    def loadTournament(self, tid):
        try:
            data = self.db.execute_query("SELECT * FROM tournaments WHERE id = ?", (tid,))
            if data:
                row = data[0]
                # row: id, name, type, total, current, status, created
                self._current_tournament = Tournament(
                    id=row[0], name=row[1], type=row[2], total_rounds=row[3],
                    current_round=row[4], status=row[5], created_at=row[6],
                    venue=row[7]
                )
                self._viewing_round = self._current_tournament.current_round # Reset view to current
                
                self.tournamentChanged.emit()
                self.refreshPlayers()
                self.updateStandings()
                self.roundsChanged.emit() # Ensure round status/mode is refreshed
                # Load pairings for the *viewed* round (which is current)
                if self._current_tournament.current_round > 0:
                    self.loadPairings(self._current_tournament.current_round)
                
                self._save_app_state()
                
                # Fix: If tournament looks done but status says active, update it
                if self._current_tournament.status == 'ACTIVE' and self._current_tournament.current_round == self._current_tournament.total_rounds:
                    # Check if the final round is actually locked
                    rdata = self.db.execute_query("SELECT status FROM rounds WHERE tournament_id = ? AND round_number = ?", 
                                                  (self._current_tournament.id, self._current_tournament.current_round))
                    if rdata and rdata[0][0] == 'LOCKED':
                        print(f"Auto-correcting status for Tournament {self._current_tournament.id} to FINISHED")
                        self.db.execute_non_query("UPDATE tournaments SET status = 'FINISHED' WHERE id = ?", (self._current_tournament.id,))
                        self._current_tournament.status = 'FINISHED'
                        self.tournamentChanged.emit()
        except Exception as e:
            print(e)
            self.notification.emit("Error", "Failed to load tournament")

    @pyqtSlot(int)
    def setViewRound(self, round_num):
        if not self._current_tournament: return
        if round_num < 1 or round_num > self._current_tournament.current_round:
            return
            
        self._viewing_round = round_num
        self._save_app_state()
        self.loadPairings(self._viewing_round)
        self.tournamentChanged.emit() # Update UI headers
        self.roundsChanged.emit() # Update locked status
        

    @pyqtSlot(str, int, str, str)
    def addPlayer(self, name, rating, fide_id, club):
        if not self._current_tournament:
            return

        try:
            query = "INSERT INTO players (tournament_id, name, rating, fide_id, club) VALUES (?, ?, ?, ?, ?)"
            self.db.execute_non_query(query, (self._current_tournament.id, name, rating, fide_id, club))
            self.refreshPlayers()
            self.notification.emit("Success", "Player added")
        except Exception as e:
            self.notification.emit("Error", str(e))

    @pyqtSlot(int)
    def deletePlayer(self, pid):
        if not self._current_tournament: return
        
        # Check if player has any pairings
        p_count = self.db.execute_query(
            "SELECT COUNT(*) FROM pairings WHERE white_player_id = ? OR black_player_id = ?", 
            (pid, pid)
        )[0][0]
        
        if p_count > 0:
            self.notification.emit("Error", "Cannot delete player who has played matches. Withdraw instead.")
            return

        try:
            self.db.execute_non_query("DELETE FROM players WHERE id=?", (pid,))
            self.refreshPlayers()
            self.notification.emit("Success", "Player deleted")
        except Exception as e:
            self.notification.emit("Error", f"Failed to delete player: {e}")

    @pyqtProperty(bool, notify=roundsChanged)
    def isPairingModeManual(self):
        if not self._current_tournament: return False
        r_num = self._viewing_round if self._viewing_round > 0 else self._current_tournament.current_round
        
        rdata = self.db.execute_query("SELECT pairing_mode FROM rounds WHERE tournament_id = ? AND round_number = ?", 
                                      (self._current_tournament.id, r_num))
        if rdata and rdata[0][0] == 'MANUAL':
            return True
        return False

    @pyqtSlot(str, int, int)
    def saveManualPairing(self, result_placeholder, w_id, b_id):
        # Adds a single manual pairing to the CURRENT manual round
        if not self._current_tournament: return
        
        # Verify valid round
        r_num = self._current_tournament.current_round
        rdata = self.db.execute_query("SELECT id, pairing_mode FROM rounds WHERE tournament_id = ? AND round_number = ?", 
                                      (self._current_tournament.id, r_num))
        if not rdata or rdata[0][1] != 'MANUAL':
            self.notification.emit("Error", "Current round is not in Manual Mode")
            return
        
        rid = rdata[0][0]
        
        try:
             # Basic insert
             self.db.execute_non_query(
                "INSERT INTO pairings (round_id, white_player_id, black_player_id, result) VALUES (?, ?, ?, ?)",
                (rid, w_id if w_id > 0 else None, b_id if b_id > 0 else None, result_placeholder)
            )
             self.loadPairings(r_num)
             self.pairingsChanged.emit() # Refresh
        except Exception as e:
            self.notification.emit("Error", f"Manual add failed: {e}")

    @pyqtSlot(int)
    def deletePairing(self, pairing_id):
        try:
            self.db.execute_non_query("DELETE FROM pairings WHERE id=?", (pairing_id,))
            self.loadPairings(self._current_tournament.current_round)
            self.notification.emit("Success", "Pairing removed")
        except Exception as e:
            self.notification.emit("Error", str(e))

    @pyqtSlot(str)
    def setupNextRound(self, mode):
        if not self._current_tournament: return
        
        tid = self._current_tournament.id
        current_round = self._current_tournament.current_round
        
        # Rule: Cannot start next round if current is not LOCKED (unless it's round 0)
        if current_round > 0:
            # Check status
            rdata = self.db.execute_query("SELECT status FROM rounds WHERE tournament_id = ? AND round_number = ?",
                                          (tid, current_round))
            if not rdata or rdata[0][0] != 'LOCKED':
                self.notification.emit("Error", "Current round must be LOCKED before starting next round.")
                return

        next_round = current_round + 1
        
        if next_round > self._current_tournament.total_rounds:
            self.notification.emit("Info", "Tournament Finished!")
            return

        # 1. Create Round Record
        try:
            rid = self.db.execute_non_query(
                "INSERT INTO rounds (tournament_id, round_number, status, pairing_mode) VALUES (?, ?, 'IN_PROGRESS', ?)",
                (tid, next_round, mode)
            )
        except Exception as e:
             self.notification.emit("Error", f"Failed to create round: {e}")
             return
        
        # 2. Update Tournament State (Move current pointer)
        self.db.execute_non_query(
            "UPDATE tournaments SET current_round = ?, status = 'ACTIVE' WHERE id = ?",
            (next_round, tid)
        )
        self.loadTournament(tid) # Refresh state

        if mode == 'MANUAL':
            # Manual Mode: Round created, but no pairings. 
            # UI checks isPairingModeManual + empty pairings list -> Shows Editor
            self.notification.emit("Success", f"Round {next_round} Initialized (Manual Mode)")
            self.loadPairings(next_round) # Will be empty
            return

        # AUTO Pairing Logic
        try:
            self.refreshPlayers()
            
            # Retrieve past pairings for history
            past_pairings_data = self.db.execute_query(
                """
                SELECT p.id, p.round_id, p.white_player_id, p.black_player_id, p.result 
                FROM pairings p 
                JOIN rounds r ON p.round_id = r.id 
                WHERE r.tournament_id = ?
                """,
                (tid,)
            )
            
            past_objs = []
            for p in past_pairings_data:
                # schema of p: id, round_id, w_id, b_id, res
                past_objs.append(Pairing(id=p[0], round_id=p[1], white_player_id=p[2], black_player_id=p[3], result=p[4]))

            generated = []
            if self._current_tournament.type == 'SWISS':
                generated = self.swiss_engine.pair_round(self._players, past_objs, next_round)
            else:
                generated = self.rr_engine.pair_round(self._players, next_round)
            
            # 3. Save Pairings to DB
            for gp in generated:
                w = gp['white'].id if gp.get('white') else None
                b = gp['black'].id if gp.get('black') else None
                res = gp.get('result', '*')
                self.db.execute_non_query(
                    "INSERT INTO pairings (round_id, white_player_id, black_player_id, result) VALUES (?, ?, ?, ?)",
                    (rid, w, b, res)
                )

            # Reload
            self.loadPairings(next_round)
            self.notification.emit("Success", f"Round {next_round} pairings generated (Auto)")

        except Exception as e:
            self.notification.emit("Error", f"Pairing Failed: {e}")
            import traceback
            traceback.print_exc()

    @pyqtSlot(int, str)
    def setResult(self, pairing_id, result):
        # Allow editing ONLY if the round is IN_PROGRESS (which means Unlocked or Current)
        # We need to find which round this pairing belongs to
        pdata = self.db.execute_query("SELECT round_id FROM pairings WHERE id=?", (pairing_id,))
        if not pdata: return
        rid = pdata[0][0]
        
        rdata = self.db.execute_query("SELECT status FROM rounds WHERE id=?", (rid,))
        if not rdata: return
        status = rdata[0][0]
        
        if status == 'LOCKED':
            self.notification.emit("Error", "Round is LOCKED. Unlock to edit results.")
            return

        self.db.execute_non_query("UPDATE pairings SET result = ? WHERE id = ?", (result, pairing_id))
        self.updateStandings() # Auto update standings (NOTE: If unlocked, these results won't count yet)
        
        # Reload if we are viewing this round
        if self._current_tournament and self.viewingRoundNumber > 0:
             self.loadPairings(self.viewingRoundNumber)

    @pyqtSlot(int)
    def lockRound(self, round_num):
        if not self._current_tournament: return
        
        try:
            # Update status to LOCKED and set timestamp
            import datetime
            now = datetime.datetime.now().isoformat()
            
            self.db.execute_non_query(
                "UPDATE rounds SET status = 'LOCKED', locked_at = ? WHERE tournament_id = ? AND round_number = ?",
                (now, self._current_tournament.id, round_num)
            )
            
            self.refreshPlayers() # Triggers FULL recalculation including this round
            self.roundsChanged.emit() # Notify UI
            
            # Check if this was the last round
            if round_num == self._current_tournament.total_rounds:
                self.db.execute_non_query(
                    "UPDATE tournaments SET status = 'FINISHED' WHERE id = ?",
                    (self._current_tournament.id,)
                )
                self.loadTournament(self._current_tournament.id) # Refresh
                self.notification.emit("Success", f"Round {round_num} Locked. Tournament Completed! 🏆")
            else:
                self.notification.emit("Success", f"Round {round_num} Locked & Standings Updated")
            
        except Exception as e:
            self.notification.emit("Error", f"Failed to lock round: {e}")

    @pyqtSlot(int)
    def unlockRound(self, round_num):
        if not self._current_tournament: return
        
        try:
            # Update status to IN_PROGRESS
            self.db.execute_non_query(
                "UPDATE rounds SET status = 'IN_PROGRESS', locked_at = NULL WHERE tournament_id = ? AND round_number = ?",
                (self._current_tournament.id, round_num)
            )
            
            self.refreshPlayers() # Triggers FULL recalculation (Excluding this round now!)
            self.roundsChanged.emit() # Notify UI
            self.notification.emit("Warning", f"Round {round_num} Unlocked. Values temporarily excluded from standings.")
            
        except Exception as e:
            self.notification.emit("Error", f"Failed to unlock round: {e}") 
    
    # --- Helpers ---
    def refreshPlayers(self):
        if not self._current_tournament: return
        
        # 1. Fetch raw players (No ordering by points yet)
        # 1. Fetch raw players (No ordering by points yet)
        # Note: Columns are id, tournament_id, name, rating, fide_id, club, status, withdraw_round
        # Check current schema order vs select *
        data = self.db.execute_query("SELECT id, tournament_id, name, rating, fide_id, club, status, withdraw_round FROM players WHERE tournament_id = ?", (self._current_tournament.id,))
        
        self._players = []
        player_map = {}
        
        for row in data:
            p = Player(
                id=row[0], tournament_id=row[1], name=row[2], rating=row[3],
                fide_id=row[4], club=row[5], 
                status=row[6], withdraw_round=row[7]
            )
            # Transient fields initialized to 0.0 in __post_init__ or default
            # (Which they are in the updated model)
            
            self._players.append(p)
            player_map[p.id] = p
            
        # 2. Recalculate Points from Scratch (In-Memory)
        self._recalculatepoints(player_map)
        
        # 3. Sort players (Points Descending, then Name Ascending)
        self._players.sort(key=lambda x: (-x.points, x.name))
        
        # 4. Update Standings & Signals
        self._standings = self._players
        self.playersChanged.emit()
        self.standingsChanged.emit()

    def _recalculatepoints(self, player_map):
        if not self._current_tournament: return

        # Fetch ALL pairings for this tournament, but JOIN rounds to check status
        tid = self._current_tournament.id
        all_pairings = self.db.execute_query(
            "SELECT p.white_player_id, p.black_player_id, p.result FROM pairings p JOIN rounds r ON p.round_id = r.id WHERE r.tournament_id = ? AND r.status = 'LOCKED'",
            (tid,)
        )
        
        # print(f"DEBUG: Recalculating points for {len(all_pairings)} locked games")
        
        for w_id, b_id, res in all_pairings:
            # Skip if result is not set
            if res == '*': continue
            
            # Logic: Win=1, Draw=0.5, Loss=0, Bye=1
            w_points = 0.0
            b_points = 0.0
            
            if res == '1-0':
                w_points = 1.0
            elif res == '0-1':
                b_points = 1.0
            elif res == '0.5-0.5':
                w_points = 0.5
                b_points = 0.5
            elif res == 'BYE':
                w_points = 1.0
                b_points = 1.0 
            
            # Apply to map
            if w_id and w_id in player_map:
                player_map[w_id].points += w_points
            
            if b_id and b_id in player_map:
                player_map[b_id].points += b_points

    @pyqtSlot()
    def updateStandings(self):
        # Just refresh, which handles recalculation
        self.refreshPlayers()

    def loadPairings(self, round_num):
        if not self._current_tournament: return
        # Get round ID
        rdata = self.db.execute_query("SELECT id FROM rounds WHERE tournament_id = ? AND round_number = ?", (self._current_tournament.id, round_num))
        if not rdata: return
        rid = rdata[0][0]
        
        pdata = self.db.execute_query(
            """
            SELECT p.id, p.white_player_id, wp.name, p.black_player_id, bp.name, p.result
            FROM pairings p
            LEFT JOIN players wp ON p.white_player_id = wp.id
            LEFT JOIN players bp ON p.black_player_id = bp.id
            WHERE p.round_id = ?
            """, (rid,)
        )
        
        self._pairings = []
        for row in pdata:
            # Manually constructing model with names
            p = Pairing(
                id=row[0], round_id=rid, white_player_id=row[1], black_player_id=row[3], result=row[5]
            )
            p.white_player_name = row[2] if row[2] else "BYE"
            p.black_player_name = row[4] if row[4] else "BYE"
            self._pairings.append(p)
        self.pairingsChanged.emit()

    # Replaced updateStandings with the one above, so this block effectively removes the old one.

    @pyqtProperty(list, notify=tournamentChanged)
    def recentTournaments(self):
        data = self.db.execute_query("SELECT id, name, type, status, created_at, total_rounds, current_round, venue FROM tournaments ORDER BY created_at DESC")
        result = []
        for row in data:
            result.append({
                "id": row[0],
                "name": row[1],
                "type": row[2],
                "status": row[3],
                "date": row[4],
                "total_rounds": row[5],
                "current_round": row[6],
                "venue": row[7]
            })
        return result

    @pyqtSlot(int)
    def deleteTournament(self, tid):
        try:
            self.db.execute_non_query("DELETE FROM tournaments WHERE id = ?", (tid,))
            self.notification.emit("Success", "Tournament deleted")
            self.tournamentChanged.emit() # Refresh list
        except Exception as e:
            self.notification.emit("Error", str(e))
            
    @pyqtSlot()
    def getRecentTournaments(self):
        # Trigger an update if needed, though property binding handles it mostly
        self.tournamentChanged.emit()

    @pyqtSlot(int)
    def withdrawPlayer(self, player_id):
        if not self._current_tournament: return
        
        try:
            current_round = self._current_tournament.current_round
            self.db.withdraw_player(player_id, current_round)
            self.refreshPlayers()
            self.notification.emit("Success", "Player withdrawn from tournament")
        except Exception as e:
            self.notification.emit("Error", f"Failed to withdraw player: {e}")

    @pyqtSlot(int)
    def printRoundReport(self, round_num):
        if not self._current_tournament: return
        try:
            from backend.reports import ReportGenerator
            import os
            import subprocess
            import platform

            # Get Round ID
            rdata = self.db.execute_query("SELECT id FROM rounds WHERE tournament_id = ? AND round_number = ?", 
                                          (self._current_tournament.id, round_num))
            if not rdata:
                self.notification.emit("Error", "Round not found")
                return
            rid = rdata[0][0]

            # Generate Report
            # Ensure reports directory exists
            reports_dir = os.path.join(get_app_path(), 'reports')
            if not os.path.exists(reports_dir):
                os.makedirs(reports_dir)
                
            filename = f"Round_{round_num}_Results.pdf"
            filepath = os.path.join(reports_dir, filename)
            
            generator = ReportGenerator(self.db.db_path)
            generator.generate_round_report(rid, filepath)
            
            self.notification.emit("Success", f"Report generated: {filepath}")
            
            # Open the file
            if platform.system() == 'Windows':
                os.startfile(filepath)
            elif platform.system() == 'Darwin':
                subprocess.call(('open', filepath))
            else:
                subprocess.call(('xdg-open', filepath))
                
        except Exception as e:
            self.notification.emit("Error", f"Report generation failed: {e}")
            import traceback
            traceback.print_exc()

    @pyqtSlot()
    def printStandingsReport(self):
        if not self._current_tournament: return
        try:
            from backend.reports import ReportGenerator
            import os
            import subprocess
            import platform

            # Ensure reports directory exists
            reports_dir = os.path.join(get_app_path(), 'reports')
            if not os.path.exists(reports_dir):
                os.makedirs(reports_dir)
                
            filename = f"Tournament_{self._current_tournament.id}_Standings.pdf"
            filepath = os.path.join(reports_dir, filename)
            
            generator = ReportGenerator(self.db.db_path)
            generator.generate_standings_report(self._current_tournament.id, filepath)
            
            self.notification.emit("Success", f"Standings report generated: {filepath}")
            
            # Open the file
            if platform.system() == 'Windows':
                os.startfile(filepath)
            elif platform.system() == 'Darwin':
                subprocess.call(('open', filepath))
            else:
                subprocess.call(('xdg-open', filepath))
                
        except Exception as e:
            self.notification.emit("Error", f"Standings report failed: {e}")
            import traceback
            traceback.print_exc()

    @pyqtSlot()
    def printPlayerList(self):
        if not self._current_tournament: return
        try:
            from backend.reports import ReportGenerator
            import os
            import subprocess
            import platform

            # Ensure reports directory exists
            reports_dir = os.path.join(get_app_path(), 'reports')
            if not os.path.exists(reports_dir):
                os.makedirs(reports_dir)
                
            filename = f"Tournament_{self._current_tournament.id}_PlayerList.pdf"
            filepath = os.path.join(reports_dir, filename)
            
            generator = ReportGenerator(self.db.db_path)
            generator.generate_player_list(self._current_tournament.id, filepath)
            
            self.notification.emit("Success", f"Player list generated: {filepath}")
            
            # Open the file
            if platform.system() == 'Windows':
                os.startfile(filepath)
            elif platform.system() == 'Darwin':
                subprocess.call(('open', filepath))
            else:
                subprocess.call(('xdg-open', filepath))
                
        except Exception as e:
            self.notification.emit("Error", f"Player list report failed: {e}")
            import traceback
            traceback.print_exc()

    # ============================================================
    # Features: Player Editing, Undo, Settings, Backup, etc.
    # ============================================================

    def _emit_undo_status(self):
        """Update UI on undo availability."""
        can_undo = self.undo_manager.can_undo()
        description = self.undo_manager.peek() or ""
        self.undoAvailable.emit(can_undo, description)

    # --- Undo Properties ---
    @pyqtProperty(bool, notify=undoAvailable)
    def canUndo(self):
        return self.undo_manager.can_undo()

    @pyqtProperty(str, notify=undoAvailable)
    def lastUndoAction(self):
        return self.undo_manager.peek() or ""

    # --- Edit Player ---
    @pyqtSlot(int, str, str)
    def updatePlayer(self, player_id, name, club):
        """Update player name and/or club. Does not affect results."""
        if not self._current_tournament:
            return
        
        try:
            # Get current player data for undo
            data = self.db.execute_query(
                "SELECT name, club FROM players WHERE id = ?", (player_id,)
            )
            if not data:
                self.notification.emit("Error", "Player not found")
                return
            
            old_name, old_club = data[0]
            
            # Update the database
            self.db.execute_non_query(
                "UPDATE players SET name = ?, club = ? WHERE id = ?",
                (name, club, player_id)
            )
            
            # Push to undo stack
            self.undo_manager.push(UndoAction(
                action_type='UPDATE',
                table_name='players',
                record_id=player_id,
                old_data={'name': old_name, 'club': old_club},
                new_data={'name': name, 'club': club},
                description=f"Edit player '{old_name}'"
            ))
            
            # Refresh and notify
            self.refreshPlayers()
            self.playerUpdated.emit()
            self._emit_undo_status()
            self.notification.emit("Success", f"Player updated")
            
        except Exception as e:
            self.notification.emit("Error", f"Failed to update player: {e}")

    # --- Edit Tournament ---
    @pyqtSlot(str, str, int)
    def updateTournament(self, name, venue, total_rounds):
        """Update details. Rounds can only be changed if not started."""
        if not self._current_tournament:
            return
        
        try:
            tid = self._current_tournament.id
            current_round = self._current_tournament.current_round
            
            # Get current data for undo
            old_name = self._current_tournament.name
            old_venue = self._current_tournament.venue or ""
            old_rounds = self._current_tournament.total_rounds
            
            # Validate: rounds can only be changed if tournament hasn't started
            if total_rounds != old_rounds and current_round > 0:
                self.notification.emit("Error", "Cannot change round count after tournament has started")
                return
            
            # Update the database
            self.db.execute_non_query(
                "UPDATE tournaments SET name = ?, venue = ?, total_rounds = ? WHERE id = ?",
                (name, venue, total_rounds, tid)
            )
            
            # Push to undo stack
            self.undo_manager.push(UndoAction(
                action_type='UPDATE',
                table_name='tournaments',
                record_id=tid,
                old_data={'name': old_name, 'venue': old_venue, 'total_rounds': old_rounds},
                new_data={'name': name, 'venue': venue, 'total_rounds': total_rounds},
                description=f"Edit tournament '{old_name}'"
            ))
            
            # Reload tournament
            self.loadTournament(tid)
            self._emit_undo_status()
            self.notification.emit("Success", "Tournament updated")
            
        except Exception as e:
            self.notification.emit("Error", f"Failed to update tournament: {e}")

    # --- Clone Tournament ---
    @pyqtSlot(int, str, str, int)
    def cloneTournament(self, source_tid, new_name, venue, rounds):
        """Creates a new tournament based on an existing one, copying players."""
        try:
            # 1. Get source tournament details (to verify and maybe copy type if needed, though usually type is passed or same)
            # Actually, we should probably get the type from the source if not provided, or just assume same type.
            # Let's look up the source type.
            src_data = self.db.execute_query("SELECT type FROM tournaments WHERE id = ?", (source_tid,))
            if not src_data:
                self.notification.emit("Error", "Source tournament not found")
                return
            t_type = src_data[0][0]

            # 2. Create new tournament
            query = "INSERT INTO tournaments (name, type, total_rounds, status, venue) VALUES (?, ?, ?, 'SETUP', ?)"
            new_tid = self.db.execute_non_query(query, (new_name, t_type, rounds, venue))

            # 3. Copy Players
            # Get players from source
            players = self.db.execute_query(
                "SELECT name, rating, fide_id, club FROM players WHERE tournament_id = ?", 
                (source_tid,)
            )
            
            # Insert into new tournament
            count = 0
            for p in players:
                # p: name, rating, fide_id, club
                self.db.execute_non_query(
                    "INSERT INTO players (tournament_id, name, rating, fide_id, club, status) VALUES (?, ?, ?, ?, ?, 'ACTIVE')",
                    (new_tid, p[0], p[1], p[2], p[3])
                )
                count += 1
            
            self.notification.emit("Success", f"Cloned '{new_name}' with {count} players")
            self.loadTournament(new_tid)
            
        except Exception as e:
            self.notification.emit("Error", f"Failed to clone tournament: {e}")
            import traceback
            traceback.print_exc()

    # --- Undo ---
    @pyqtSlot()
    def undo(self):
        """Undo the last action."""
        if not self.undo_manager.can_undo():
            self.notification.emit("Info", "Nothing to undo")
            return
        
        action = self.undo_manager.pop()
        if not action:
            return
        
        try:
            if action.table_name == 'players':
                if action.action_type == 'UPDATE':
                    # Restore old values
                    self.db.execute_non_query(
                        "UPDATE players SET name = ?, club = ? WHERE id = ?",
                        (action.old_data['name'], action.old_data.get('club', ''), action.record_id)
                    )
                elif action.action_type == 'ADD':
                    # Delete the added player
                    self.db.execute_non_query(
                        "DELETE FROM players WHERE id = ?", (action.record_id,)
                    )
                elif action.action_type == 'DELETE':
                    # Re-insert the deleted player
                    self.db.execute_non_query(
                        "INSERT INTO players (id, tournament_id, name, rating, fide_id, club, status) VALUES (?, ?, ?, ?, ?, ?, ?)",
                        (action.record_id, action.old_data['tournament_id'], action.old_data['name'],
                         action.old_data.get('rating', 0), action.old_data.get('fide_id', ''),
                         action.old_data.get('club', ''), action.old_data.get('status', 'ACTIVE'))
                    )
                self.refreshPlayers()
                
            elif action.table_name == 'tournaments':
                if action.action_type == 'UPDATE':
                    self.db.execute_non_query(
                        "UPDATE tournaments SET name = ?, venue = ?, total_rounds = ? WHERE id = ?",
                        (action.old_data['name'], action.old_data.get('venue', ''),
                         action.old_data['total_rounds'], action.record_id)
                    )
                    self.loadTournament(action.record_id)
                    
            elif action.table_name == 'pairings':
                if action.action_type == 'UPDATE':
                    self.db.execute_non_query(
                        "UPDATE pairings SET result = ? WHERE id = ?",
                        (action.old_data['result'], action.record_id)
                    )
                    self.updateStandings()
                    if self._current_tournament:
                        self.loadPairings(self.viewingRoundNumber)
            
            self._emit_undo_status()
            self.notification.emit("Success", f"Undone: {action.description}")
            
        except Exception as e:
            self.notification.emit("Error", f"Undo failed: {e}")

    # --- Settings ---
    @pyqtProperty(QVariant, notify=settingsChanged)
    def allSettings(self):
        """Get all settings as a dictionary."""
        return self.settings_manager.get_all()

    @pyqtSlot(str, str)
    def updateSetting(self, key, value):
        """Update a single setting."""
        try:
            self.settings_manager.set(key, value)
            
            # Apply certain settings immediately
            if key == 'undo_stack_size':
                self.undo_manager.max_size = int(value)
            
            self.settingsChanged.emit()
            self.notification.emit("Success", "Setting updated")
        except Exception as e:
            self.notification.emit("Error", f"Failed to update setting: {e}")

    @pyqtSlot()
    def resetSettings(self):
        """Reset all settings to defaults."""
        try:
            self.settings_manager.reset_defaults()
            self.undo_manager.max_size = 10
            self.settingsChanged.emit()
            self.notification.emit("Success", "Settings reset to defaults")
        except Exception as e:
            self.notification.emit("Error", f"Failed to reset settings: {e}")

    @pyqtSlot(str, result=str)
    def getSetting(self, key):
        """Get a single setting value."""
        return self.settings_manager.get(key, "")

    # --- Backup & Restore ---
    @pyqtSlot()
    def createBackup(self):
        """Create a manual backup of the database."""
        try:
            backup_folder = self.settings_manager.get('backup_folder', 'backups')
            # Make backup folder absolute if relative
            if not os.path.isabs(backup_folder):
                backup_folder = os.path.join(os.path.dirname(self.db.db_path), backup_folder)
            
            backup_path = self.backup_manager.create_backup(self.db.db_path, backup_folder)
            self.backupCreated.emit(backup_path)
            self.notification.emit("Success", f"Backup created: {os.path.basename(backup_path)}")
        except Exception as e:
            self.notification.emit("Error", f"Backup failed: {e}")

    @pyqtSlot(str)
    def restoreBackup(self, backup_path):
        """Restore from a backup file."""
        try:
            # Validate first
            if not self.backup_manager.validate_backup(backup_path):
                self.notification.emit("Error", "Invalid or corrupted backup file")
                return
            
            self.backup_manager.restore_backup(backup_path, self.db.db_path)
            
            # Reinitialize database connection
            self.db = Database()
            self._current_tournament = None
            self._players = []
            self._pairings = []
            self._standings = []
            
            self.backupRestored.emit()
            self.tournamentChanged.emit()
            self.notification.emit("Success", "Backup restored successfully. Please reload your tournament.")
        except Exception as e:
            self.notification.emit("Error", f"Restore failed: {e}")

    @pyqtProperty(list, notify=backupCreated)
    def backupList(self):
        """Get list of available backups."""
        backup_folder = self.settings_manager.get('backup_folder', 'backups')
        if not os.path.isabs(backup_folder):
            backup_folder = os.path.join(os.path.dirname(self.db.db_path), backup_folder)
        
        backups = self.backup_manager.list_backups(backup_folder)
        return [b.to_dict() for b in backups]

    # --- Import/Export Players (CSV) ---
    @pyqtSlot(str)
    def exportPlayersCSV(self, filepath):
        """Export current tournament players to CSV."""
        if not self._current_tournament:
            self.notification.emit("Error", "No tournament loaded")
            return
        
        try:
            with open(filepath, 'w', newline='', encoding='utf-8') as f:
                writer = csv.writer(f)
                writer.writerow(['Name', 'Club', 'Rating', 'Status'])
                
                for player in self._players:
                    writer.writerow([
                        player.name,
                        player.club or '',
                        player.rating,
                        player.status
                    ])
            
            self.notification.emit("Success", f"Exported {len(self._players)} players to CSV")
        except Exception as e:
            self.notification.emit("Error", f"Export failed: {e}")

    @pyqtSlot(str, result=QVariant)
    def previewImportCSV(self, filepath):
        """Preview players from CSV file before importing."""
        try:
            players = []
            with open(filepath, 'r', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                for row in reader:
                    name = row.get('Name', row.get('name', '')).strip()
                    if not name:
                        continue
                    players.append({
                        'name': name,
                        'club': row.get('Club', row.get('club', '')).strip(),
                        'rating': int(row.get('Rating', row.get('rating', 0)) or 0)
                    })
            
            # Check for duplicates with existing players
            existing_names = {p.name.lower() for p in self._players}
            for p in players:
                p['duplicate'] = p['name'].lower() in existing_names
            
            return players
        except Exception as e:
            self.notification.emit("Error", f"Failed to read CSV: {e}")
            return []

    @pyqtSlot(str)
    def importPlayersCSV(self, filepath):
        """Import players from CSV file."""
        if not self._current_tournament:
            self.notification.emit("Error", "No tournament loaded")
            return
        
        if self._current_tournament.current_round > 0:
            self.notification.emit("Error", "Cannot import players after tournament has started")
            return
        
        try:
            imported_count = 0
            skipped_count = 0
            existing_names = {p.name.lower() for p in self._players}
            
            with open(filepath, 'r', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                for row in reader:
                    name = row.get('Name', row.get('name', '')).strip()
                    if not name:
                        continue
                    
                    # Skip duplicates
                    if name.lower() in existing_names:
                        skipped_count += 1
                        continue
                    
                    club = row.get('Club', row.get('club', '')).strip()
                    rating = int(row.get('Rating', row.get('rating', 0)) or 0)
                    
                    self.db.execute_non_query(
                        "INSERT INTO players (tournament_id, name, rating, club) VALUES (?, ?, ?, ?)",
                        (self._current_tournament.id, name, rating, club)
                    )
                    imported_count += 1
                    existing_names.add(name.lower())
            
            self.refreshPlayers()
            msg = f"Imported {imported_count} players"
            if skipped_count > 0:
                msg += f" ({skipped_count} duplicates skipped)"
            self.notification.emit("Success", msg)
            
        except Exception as e:
            self.notification.emit("Error", f"Import failed: {e}")
