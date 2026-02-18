"""
Environment - Execution environment detection and management
Identifies and manages execution environment information
"""

from typing import Any, Dict, List, Optional
from datetime import datetime
import platform
import os
import socket


class Environment:
    """Execution environment information"""
    
    DETECTED_ENVIRONMENTS = ["production", "staging", "test", "development", "local"]
    
    def __init__(self):
        self._environment = None
        self._hostname = socket.gethostname()
        self._platform = platform.system()
        self._platform_version = platform.version()
        self._python_version = platform.python_version()
        self._start_time = datetime.utcnow()
        self._metadata = {}
    
    def detect(self) -> str:
        """Detect current environment"""
        if self._environment:
            return self._environment
        
        env_var = os.environ.get("RUNNER_ENVIRONMENT", "").lower()
        
        if env_var and env_var in self.DETECTED_ENVIRONMENTS:
            self._environment = env_var
            return self._environment
        
        if os.environ.get("CI") or os.environ.get("GITHUB_ACTIONS"):
            if os.environ.get("RUNNER_ENV") == "production":
                self._environment = "production"
            else:
                self._environment = "test"
        elif os.environ.get("DEBUG"):
            self._environment = "development"
        else:
            self._environment = "local"
        
        return self._environment
    
    def set_environment(self, env: str):
        """Set environment manually"""
        if env.lower() in self.DETECTED_ENVIRONMENTS:
            self._environment = env.lower()
        else:
            raise ValueError(f"Unknown environment: {env}")
    
    def get_environment(self) -> str:
        """Get current environment"""
        if not self._environment:
            self.detect()
        return self._environment
    
    def is_production(self) -> bool:
        return self.get_environment() == "production"
    
    def is_staging(self) -> bool:
        return self.get_environment() == "staging"
    
    def is_test(self) -> bool:
        return self.get_environment() == "test"
    
    def is_development(self) -> bool:
        return self.get_environment() == "development"
    
    def is_local(self) -> bool:
        return self.get_environment() == "local"
    
    def get_info(self) -> Dict:
        """Get full environment information"""
        return {
            "environment": self.get_environment(),
            "hostname": self._hostname,
            "platform": {
                "system": self._platform,
                "version": self._platform_version,
                "python_version": self._python_version
            },
            "start_time": self._start_time.isoformat(),
            "uptime_seconds": (datetime.utcnow() - self._start_time).total_seconds(),
            "metadata": self._metadata
        }
    
    def set_metadata(self, key: str, value: Any):
        """Set environment metadata"""
        self._metadata[key] = value
    
    def get_metadata(self, key: str, default: Any = None) -> Any:
        """Get environment metadata"""
        return self._metadata.get(key, default)
    
    def get_all_metadata(self) -> Dict:
        """Get all metadata"""
        return self._metadata.copy()
    
    def clear_metadata(self):
        """Clear all metadata"""
        self._metadata = {}


class EnvironmentContext:
    """Context manager for environment operations"""
    
    def __init__(self, environment: Environment):
        self._env = environment
    
    def __enter__(self):
        return self._env
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        pass


environment = Environment()
