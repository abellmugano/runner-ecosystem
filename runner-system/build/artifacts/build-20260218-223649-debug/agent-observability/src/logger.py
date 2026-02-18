"""
Logger - Logging system for the Runner Ecosystem
Implements comprehensive logging for executions and modules
"""

from typing import Any, Dict, List, Optional
from datetime import datetime
import json
import os


class LogLevel:
    """Log levels"""
    DEBUG = "DEBUG"
    INFO = "INFO"
    WARNING = "WARNING"
    ERROR = "ERROR"
    CRITICAL = "CRITICAL"


class LogEntry:
    """Single log entry"""
    
    def __init__(
        self,
        level: str,
        message: str,
        module: Optional[str] = None,
        execution_id: Optional[str] = None,
        metadata: Optional[Dict] = None
    ):
        self.timestamp = datetime.utcnow().isoformat()
        self.level = level
        self.message = message
        self.module = module
        self.execution_id = execution_id
        self.metadata = metadata or {}
    
    def to_dict(self) -> Dict:
        return {
            "timestamp": self.timestamp,
            "level": self.level,
            "message": self.message,
            "module": self.module,
            "execution_id": self.execution_id,
            "metadata": self.metadata
        }
    
    def to_json(self) -> str:
        return json.dumps(self.to_dict())


class Logger:
    """Main logger class"""
    
    def __init__(self, name: str = "runner"):
        self.name = name
        self.entries: List[LogEntry] = []
        self._log_file = None
    
    def set_log_file(self, filepath: str):
        """Set log file path"""
        self._log_file = filepath
        os.makedirs(os.path.dirname(filepath), exist_ok=True)
    
    def _add_entry(self, entry: LogEntry):
        self.entries.append(entry)
        
        if self._log_file:
            try:
                with open(self._log_file, 'a') as f:
                    f.write(entry.to_json() + '\n')
            except Exception:
                pass
    
    def debug(self, message: str, module: Optional[str] = None, 
              execution_id: Optional[str] = None, metadata: Optional[Dict] = None):
        """Log debug message"""
        self._add_entry(LogEntry(LogLevel.DEBUG, message, module, execution_id, metadata))
    
    def info(self, message: str, module: Optional[str] = None,
             execution_id: Optional[str] = None, metadata: Optional[Dict] = None):
        """Log info message"""
        self._add_entry(LogEntry(LogLevel.INFO, message, module, execution_id, metadata))
    
    def warning(self, message: str, module: Optional[str] = None,
                execution_id: Optional[str] = None, metadata: Optional[Dict] = None):
        """Log warning message"""
        self._add_entry(LogEntry(LogLevel.WARNING, message, module, execution_id, metadata))
    
    def error(self, message: str, module: Optional[str] = None,
              execution_id: Optional[str] = None, metadata: Optional[Dict] = None):
        """Log error message"""
        self._add_entry(LogEntry(LogLevel.ERROR, message, module, execution_id, metadata))
    
    def critical(self, message: str, module: Optional[str] = None,
                 execution_id: Optional[str] = None, metadata: Optional[Dict] = None):
        """Log critical message"""
        self._add_entry(LogEntry(LogLevel.CRITICAL, message, module, execution_id, metadata))
    
    def log(self, level: str, message: str, module: Optional[str] = None,
            execution_id: Optional[str] = None, metadata: Optional[Dict] = None):
        """Log message with custom level"""
        self._add_entry(LogEntry(level, message, module, execution_id, metadata))
    
    def get_entries(
        self,
        level: Optional[str] = None,
        module: Optional[str] = None,
        since: Optional[datetime] = None
    ) -> List[LogEntry]:
        """Get filtered log entries"""
        filtered = self.entries
        
        if level:
            filtered = [e for e in filtered if e.level == level]
        
        if module:
            filtered = [e for e in filtered if e.module == module]
        
        if since:
            filtered = [e for e in filtered 
                        if datetime.fromisoformat(e.timestamp) >= since]
        
        return filtered
    
    def get_entries_dict(self, **kwargs) -> List[Dict]:
        """Get filtered log entries as dicts"""
        return [e.to_dict() for e in self.get_entries(**kwargs)]
    
    def clear(self):
        """Clear all entries"""
        self.entries = []
    
    def count(self, level: Optional[str] = None) -> int:
        """Count entries, optionally filtered by level"""
        if level:
            return len([e for e in self.entries if e.level == level])
        return len(self.entries)


logger = Logger()
