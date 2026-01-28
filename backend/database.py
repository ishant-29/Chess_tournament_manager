import sqlite3
import os
from contextlib import contextmanager

import sys

if getattr(sys, 'frozen', False):
    PROJECT_ROOT = os.path.dirname(sys.executable)
else:
    PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

DB_PATH = os.path.join(PROJECT_ROOT, "tournament.db")

class Database:
    def __init__(self, db_path=DB_PATH):
        self.db_path = db_path
        self.init_db()

    @contextmanager
    def get_connection(self):
        conn = sqlite3.connect(self.db_path)
        conn.execute("PRAGMA foreign_keys = ON;")
        conn.execute("PRAGMA journal_mode=WAL;")
        try:
            yield conn
            conn.commit()
        except Exception as e:
            conn.rollback()
            raise e
        finally:
            conn.close()

    def init_db(self):
        """Prepare database."""
        schema = """
        CREATE TABLE IF NOT EXISTS tournaments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            type TEXT NOT NULL CHECK(type IN ('SWISS', 'ROUND_ROBIN')),
            total_rounds INTEGER NOT NULL,
            current_round INTEGER DEFAULT 0,
            status TEXT DEFAULT 'SETUP' CHECK(status IN ('SETUP', 'ACTIVE', 'FINISHED')),
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            venue TEXT
        );

        CREATE TABLE IF NOT EXISTS players (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tournament_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            rating INTEGER DEFAULT 0,
            fide_id TEXT,
            club TEXT,
            status TEXT DEFAULT 'ACTIVE' CHECK(status IN ('ACTIVE', 'WITHDRAWN')),
            withdraw_round INTEGER,
            FOREIGN KEY (tournament_id) REFERENCES tournaments(id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS rounds (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tournament_id INTEGER NOT NULL,
            round_number INTEGER NOT NULL,
            status TEXT DEFAULT 'IN_PROGRESS' CHECK(status IN ('NOT_STARTED', 'IN_PROGRESS', 'LOCKED')),
            locked_at TIMESTAMP,
            pairing_mode TEXT DEFAULT 'AUTO' CHECK(pairing_mode IN ('AUTO', 'MANUAL')),
            FOREIGN KEY (tournament_id) REFERENCES tournaments(id) ON DELETE CASCADE,
            UNIQUE(tournament_id, round_number)
        );

        CREATE TABLE IF NOT EXISTS pairings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            round_id INTEGER NOT NULL,
            white_player_id INTEGER,
            black_player_id INTEGER,
            result TEXT DEFAULT '*' CHECK(result IN ('1-0', '0-1', '0.5-0.5', '*', 'BYE', 'FORFEIT')),
            FOREIGN KEY (round_id) REFERENCES rounds(id) ON DELETE CASCADE,
            FOREIGN KEY (white_player_id) REFERENCES players(id),
            FOREIGN KEY (black_player_id) REFERENCES players(id)
        );
        """
        with self.get_connection() as conn:
            conn.executescript(schema)
            # Migrations
            try:
                conn.execute("ALTER TABLE players ADD COLUMN status TEXT DEFAULT 'ACTIVE' CHECK(status IN ('ACTIVE', 'WITHDRAWN'))")
            except sqlite3.OperationalError: pass

            try:
                conn.execute("ALTER TABLE players ADD COLUMN withdraw_round INTEGER")
            except sqlite3.OperationalError: pass
            
            try:
                conn.execute("ALTER TABLE rounds ADD COLUMN locked_at TIMESTAMP")
            except sqlite3.OperationalError: pass
            
            try:
                conn.execute("ALTER TABLE rounds ADD COLUMN pairing_mode TEXT DEFAULT 'AUTO'")
            except sqlite3.OperationalError: pass

            try:
                conn.execute("ALTER TABLE tournaments ADD COLUMN venue TEXT")
            except sqlite3.OperationalError: pass

            # Remove stale points column if present (we calculate on fly now)
            try:
                cursor = conn.execute("PRAGMA table_info(players)")
                columns = [info[1] for info in cursor.fetchall()]
                if 'points' in columns:
                    print("Updating schema: Removing legacy points column...")
                    
                    conn.execute("ALTER TABLE players RENAME TO players_old")
                    
                    conn.execute("""
                        CREATE TABLE players (
                            id INTEGER PRIMARY KEY AUTOINCREMENT,
                            tournament_id INTEGER NOT NULL,
                            name TEXT NOT NULL,
                            rating INTEGER DEFAULT 0,
                            fide_id TEXT,
                            club TEXT,
                            status TEXT DEFAULT 'ACTIVE' CHECK(status IN ('ACTIVE', 'WITHDRAWN')),
                            withdraw_round INTEGER,
                            FOREIGN KEY (tournament_id) REFERENCES tournaments(id) ON DELETE CASCADE
                        );
                    """)
                    
                    conn.execute("""
                        INSERT INTO players (id, tournament_id, name, rating, fide_id, club, status, withdraw_round)
                        SELECT id, tournament_id, name, rating, fide_id, club, status, withdraw_round FROM players_old
                    """)
                    
                    conn.execute("DROP TABLE players_old")
                    print("Schema update complete.")
            except Exception as e:
                print(f"Migration warning: {e}")

    def withdraw_player(self, player_id: int, current_round: int):
        """Marks a player as withdrawn from the tournament."""
        with self.get_connection() as conn:
            conn.execute(
                "UPDATE players SET status = 'WITHDRAWN', withdraw_round = ? WHERE id = ?",
                (current_round, player_id)
            )

    def execute_query(self, query, params=()):
        with self.get_connection() as conn:
            cursor = conn.execute(query, params)
            return cursor.fetchall()
            
            
    def execute_non_query(self, query, params=()):
        with self.get_connection() as conn:
            cursor = conn.execute(query, params)
            return cursor.lastrowid
