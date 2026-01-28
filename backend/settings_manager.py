"""
Settings Manager - Persistent settings storage using SQLite.
"""

import sqlite3
import json
from typing import Any, Dict, Optional
from contextlib import contextmanager


# Default settings with their types and values
DEFAULT_SETTINGS = {
    'default_rounds': '5',
    'default_time_control': '90+30',
    'export_folder': '',
    'ui_scale': '100',
    'backup_folder': 'backups',
    'auto_backup': 'true',
    'undo_stack_size': '10',
    'font_size': '14'
}


class SettingsManager:
    """
    Persist settings to SQLite.
    """
    
    def __init__(self, db_path: str):
        self.db_path = db_path
        self._init_table()
        self._ensure_defaults()
    
    @contextmanager
    def _get_connection(self):
        """Context manager for database connections."""
        conn = sqlite3.connect(self.db_path)
        try:
            yield conn
            conn.commit()
        except Exception as e:
            conn.rollback()
            raise e
        finally:
            conn.close()
    
    def _init_table(self) -> None:
        """Create the settings table if it doesn't exist."""
        with self._get_connection() as conn:
            conn.execute("""
                CREATE TABLE IF NOT EXISTS app_settings (
                    key TEXT PRIMARY KEY,
                    value TEXT NOT NULL
                )
            """)
    
    def _ensure_defaults(self) -> None:
        """Ensure all default settings exist in the database."""
        with self._get_connection() as conn:
            for key, default_value in DEFAULT_SETTINGS.items():
                # Insert only if not exists
                conn.execute("""
                    INSERT OR IGNORE INTO app_settings (key, value) VALUES (?, ?)
                """, (key, default_value))
    
    def get(self, key: str, default: Optional[str] = None) -> str:
        """Get a setting value by key."""
        with self._get_connection() as conn:
            cursor = conn.execute(
                "SELECT value FROM app_settings WHERE key = ?", (key,)
            )
            row = cursor.fetchone()
            if row:
                return row[0]
            return default if default is not None else DEFAULT_SETTINGS.get(key, '')
    
    def get_int(self, key: str, default: int = 0) -> int:
        """Get a setting value as an integer."""
        try:
            return int(self.get(key, str(default)))
        except ValueError:
            return default
    
    def get_bool(self, key: str, default: bool = False) -> bool:
        """Get a setting value as a boolean."""
        value = self.get(key, str(default).lower())
        return value.lower() in ('true', '1', 'yes', 'on')
    
    def set(self, key: str, value: Any) -> None:
        """Set a setting value."""
        str_value = str(value).lower() if isinstance(value, bool) else str(value)
        with self._get_connection() as conn:
            conn.execute("""
                INSERT OR REPLACE INTO app_settings (key, value) VALUES (?, ?)
            """, (key, str_value))
    
    def get_all(self) -> Dict[str, str]:
        """Get all settings as a dictionary."""
        with self._get_connection() as conn:
            cursor = conn.execute("SELECT key, value FROM app_settings")
            return {row[0]: row[1] for row in cursor.fetchall()}
    
    def reset_defaults(self) -> None:
        """Reset all settings to default values."""
        with self._get_connection() as conn:
            conn.execute("DELETE FROM app_settings")
            for key, value in DEFAULT_SETTINGS.items():
                conn.execute(
                    "INSERT INTO app_settings (key, value) VALUES (?, ?)",
                    (key, value)
                )
    
    def delete(self, key: str) -> None:
        """Delete a setting by key."""
        with self._get_connection() as conn:
            conn.execute("DELETE FROM app_settings WHERE key = ?", (key,))
