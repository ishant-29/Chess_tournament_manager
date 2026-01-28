"""
Undo Manager - Simple in-memory stack for reverting changes.
"""

from dataclasses import dataclass, field
from typing import Any, Optional, List, Dict
from datetime import datetime
import json


@dataclass
class UndoAction:
    """Represents a single undoable action."""
    action_type: str  # 'ADD', 'UPDATE', 'DELETE'
    table_name: str   # 'players', 'tournaments', 'pairings'
    record_id: int
    old_data: Dict[str, Any]  # State before the action (for reversal)
    new_data: Optional[Dict[str, Any]] = None  # State after action (for reference)
    description: str = ""  # Human-readable description
    timestamp: str = field(default_factory=lambda: datetime.now().isoformat())
    
    def to_dict(self) -> dict:
        return {
            'action_type': self.action_type,
            'table_name': self.table_name,
            'record_id': self.record_id,
            'old_data': self.old_data,
            'new_data': self.new_data,
            'description': self.description,
            'timestamp': self.timestamp
        }


class UndoManager:
    """
    Manages undo history.
    """
    
    def __init__(self, max_size: int = 10):
        self._stack: List[UndoAction] = []
        self._max_size = max_size
    
    @property
    def max_size(self) -> int:
        return self._max_size
    
    @max_size.setter
    def max_size(self, value: int):
        self._max_size = max(1, value)  # Minimum of 1
        # Trim stack if needed
        while len(self._stack) > self._max_size:
            self._stack.pop(0)
    
    def push(self, action: UndoAction) -> None:
        """Add an action to the undo stack."""
        self._stack.append(action)
        # Enforce max size (remove oldest)
        while len(self._stack) > self._max_size:
            self._stack.pop(0)
    
    def pop(self) -> Optional[UndoAction]:
        """Remove and return the most recent action, or None if empty."""
        if self._stack:
            return self._stack.pop()
        return None
    
    def peek(self) -> Optional[str]:
        """Return the description of the most recent action, or None if empty."""
        if self._stack:
            return self._stack[-1].description
        return None
    
    def peek_action(self) -> Optional[UndoAction]:
        """Return the most recent action without removing it."""
        if self._stack:
            return self._stack[-1]
        return None
    
    def can_undo(self) -> bool:
        """Check if there are any actions to undo."""
        return len(self._stack) > 0
    
    def clear(self) -> None:
        """Clear all actions from the stack."""
        self._stack.clear()
    
    def size(self) -> int:
        """Return the current number of actions in the stack."""
        return len(self._stack)
    
    def get_history(self) -> List[str]:
        """Return list of action descriptions (most recent first)."""
        return [action.description for action in reversed(self._stack)]
