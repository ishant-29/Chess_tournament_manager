"""
Backup Manager - Database snapshot utilities.
"""

import os
import shutil
import sqlite3
from datetime import datetime
from typing import List, Dict, Optional
from dataclasses import dataclass


@dataclass
class BackupInfo:
    """Information about a backup file."""
    filename: str
    filepath: str
    created_at: str
    size_bytes: int
    size_display: str
    
    def to_dict(self) -> dict:
        return {
            'filename': self.filename,
            'filepath': self.filepath,
            'created_at': self.created_at,
            'size_bytes': self.size_bytes,
            'size_display': self.size_display
        }


class BackupManager:
    """
    Handles database backups and restoration.
    """
    
    BACKUP_PREFIX = "backup_"
    BACKUP_EXTENSION = ".db"
    
    @staticmethod
    def _format_size(size_bytes: int) -> str:
        """Format bytes to human-readable size."""
        for unit in ['B', 'KB', 'MB', 'GB']:
            if size_bytes < 1024:
                return f"{size_bytes:.1f} {unit}"
            size_bytes /= 1024
        return f"{size_bytes:.1f} TB"
    
    @staticmethod
    def _generate_backup_filename() -> str:
        """Generate a timestamped backup filename."""
        timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        return f"{BackupManager.BACKUP_PREFIX}{timestamp}{BackupManager.BACKUP_EXTENSION}"
    
    def create_backup(self, db_path: str, backup_folder: str) -> str:
        """
        Create a backup of the database.
        
        Args:
            db_path: Path to the source database file
            backup_folder: Directory to store the backup
            
        Returns:
            Full path to the created backup file
            
        Raises:
            FileNotFoundError: If source database doesn't exist
            OSError: If backup folder cannot be created
        """
        if not os.path.exists(db_path):
            raise FileNotFoundError(f"Database not found: {db_path}")
        
        # Ensure backup folder exists
        os.makedirs(backup_folder, exist_ok=True)
        
        # Generate backup filename and path
        backup_filename = self._generate_backup_filename()
        backup_path = os.path.join(backup_folder, backup_filename)
        
        # Use SQLite backup API for consistency (handles in-progress transactions)
        source_conn = sqlite3.connect(db_path)
        backup_conn = sqlite3.connect(backup_path)
        
        try:
            source_conn.backup(backup_conn)
        finally:
            source_conn.close()
            backup_conn.close()
        
        return backup_path
    
    def restore_backup(self, backup_file: str, db_path: str) -> bool:
        """
        Restore a database from a backup file.
        
        Args:
            backup_file: Path to the backup file
            db_path: Path to the target database
            
        Returns:
            True if restoration was successful
            
        Raises:
            FileNotFoundError: If backup file doesn't exist
            ValueError: If backup file is invalid
        """
        if not os.path.exists(backup_file):
            raise FileNotFoundError(f"Backup file not found: {backup_file}")
        
        # Validate backup before restoring
        if not self.validate_backup(backup_file):
            raise ValueError(f"Invalid or corrupted backup file: {backup_file}")
        
        # Create a temporary backup of current database (safety net)
        temp_backup = None
        if os.path.exists(db_path):
            temp_backup = db_path + ".temp_restore_backup"
            shutil.copy2(db_path, temp_backup)
        
        try:
            # Use SQLite backup API
            source_conn = sqlite3.connect(backup_file)
            target_conn = sqlite3.connect(db_path)
            
            try:
                source_conn.backup(target_conn)
            finally:
                source_conn.close()
                target_conn.close()
            
            # Remove temp backup on success
            if temp_backup and os.path.exists(temp_backup):
                os.remove(temp_backup)
            
            return True
            
        except Exception as e:
            # Restore from temp backup on failure
            if temp_backup and os.path.exists(temp_backup):
                shutil.copy2(temp_backup, db_path)
                os.remove(temp_backup)
            raise e
    
    def list_backups(self, backup_folder: str) -> List[BackupInfo]:
        """
        List all backup files in the backup folder.
        
        Args:
            backup_folder: Directory containing backups
            
        Returns:
            List of BackupInfo objects, sorted by date (newest first)
        """
        backups = []
        
        if not os.path.exists(backup_folder):
            return backups
        
        for filename in os.listdir(backup_folder):
            if filename.startswith(self.BACKUP_PREFIX) and filename.endswith(self.BACKUP_EXTENSION):
                filepath = os.path.join(backup_folder, filename)
                
                # Extract timestamp from filename
                try:
                    timestamp_str = filename[len(self.BACKUP_PREFIX):-len(self.BACKUP_EXTENSION)]
                    created_dt = datetime.strptime(timestamp_str, "%Y-%m-%d_%H-%M-%S")
                    created_at = created_dt.strftime("%Y-%m-%d %H:%M:%S")
                except ValueError:
                    created_at = "Unknown"
                
                # Get file size
                size_bytes = os.path.getsize(filepath)
                
                backups.append(BackupInfo(
                    filename=filename,
                    filepath=filepath,
                    created_at=created_at,
                    size_bytes=size_bytes,
                    size_display=self._format_size(size_bytes)
                ))
        
        # Sort by created_at descending (newest first)
        backups.sort(key=lambda x: x.created_at, reverse=True)
        return backups
    
    def validate_backup(self, backup_file: str) -> bool:
        """
        Validate that a backup file is a valid SQLite database.
        
        Args:
            backup_file: Path to the backup file
            
        Returns:
            True if the file is a valid SQLite database with expected tables
        """
        if not os.path.exists(backup_file):
            return False
        
        try:
            conn = sqlite3.connect(backup_file)
            cursor = conn.cursor()
            
            # Check for expected tables
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
            tables = {row[0] for row in cursor.fetchall()}
            
            conn.close()
            
            # Must have at least the core tables
            required_tables = {'tournaments', 'players', 'rounds', 'pairings'}
            return required_tables.issubset(tables)
            
        except sqlite3.Error:
            return False
    
    def delete_backup(self, backup_file: str) -> bool:
        """
        Delete a backup file.
        
        Args:
            backup_file: Path to the backup file
            
        Returns:
            True if deletion was successful
        """
        if os.path.exists(backup_file):
            os.remove(backup_file)
            return True
        return False
