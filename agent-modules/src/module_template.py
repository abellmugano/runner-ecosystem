"""
Module Template - Mandatory pattern for all modules
All modules must inherit from this template
"""

from typing import Any, Dict, Optional
from abc import ABC, abstractmethod
import json


class ModuleManifest:
    """Module manifest structure"""
    
    REQUIRED_FIELDS = [
        "name",
        "version",
        "description",
        "author"
    ]
    
    def __init__(self, data: Dict):
        self._data = data
        self._validate()
    
    def _validate(self):
        for field in self.REQUIRED_FIELDS:
            if field not in self._data:
                raise ValueError(f"Missing required field: {field}")
    
    @property
    def name(self) -> str:
        return self._data.get("name", "")
    
    @property
    def version(self) -> str:
        return self._data.get("version", "")
    
    @property
    def description(self) -> str:
        return self._data.get("description", "")
    
    @property
    def author(self) -> str:
        return self._data.get("author", "")
    
    @property
    def dependencies(self) -> list:
        return self._data.get("dependencies", [])
    
    @property
    def actions(self) -> list:
        return self._data.get("actions", [])
    
    def to_dict(self) -> Dict:
        return self._data.copy()


class BaseModule(ABC):
    """Base class for all modules"""
    
    def __init__(self):
        self._manifest = None
        self._initialized = False
    
    @abstractmethod
    def get_manifest(self) -> Dict:
        """Return module manifest"""
        pass
    
    @abstractmethod
    def initialize(self, config: Dict) -> bool:
        """Initialize the module"""
        pass
    
    @abstractmethod
    def execute(self, action: str, params: Dict, context: Dict) -> Dict:
        """Execute an action"""
        pass
    
    def validate_manifest(self) -> bool:
        """Validate manifest structure"""
        try:
            self._manifest = ModuleManifest(self.get_manifest())
            return True
        except ValueError:
            return False
    
    def is_initialized(self) -> bool:
        return self._initialized
    
    def get_info(self) -> Dict:
        return {
            "manifest": self._manifest.to_dict() if self._manifest else {},
            "initialized": self._initialized
        }


class ModuleTemplate(BaseModule):
    """Template for creating new modules"""
    
    def get_manifest(self) -> Dict:
        return {
            "name": "module_template",
            "version": "1.0.0",
            "description": "Template module",
            "author": "Runner Ecosystem",
            "dependencies": [],
            "actions": ["run", "validate", "status"]
        }
    
    def initialize(self, config: Dict) -> bool:
        self._initialized = True
        return True
    
    def execute(self, action: str, params: Dict, context: Dict) -> Dict:
        if action == "run":
            return self._run(params, context)
        elif action == "validate":
            return self._validate_action(params, context)
        elif action == "status":
            return self._status(params, context)
        else:
            return {"error": f"Unknown action: {action}"}
    
    def _run(self, params: Dict, context: Dict) -> Dict:
        return {
            "success": True,
            "message": "Module executed successfully",
            "data": params
        }
    
    def _validate_action(self, params: Dict, context: Dict) -> Dict:
        return {
            "valid": True,
            "manifest": self.get_manifest()
        }
    
    def _status(self, params: Dict, context: Dict) -> Dict:
        return {
            "initialized": self._initialized,
            "info": self.get_info()
        }


def create_module_class(manifest: Dict) -> type:
    """Factory function to create module class from manifest"""
    
    class DynamicModule(BaseModule):
        def __init__(self):
            super().__init__()
            self._manifest_data = manifest
        
        def get_manifest(self) -> Dict:
            return self._manifest_data
        
        def initialize(self, config: Dict) -> bool:
            self._initialized = True
            return True
        
        def execute(self, action: str, params: Dict, context: Dict) -> Dict:
            return {
                "success": True,
                "action": action,
                "params": params
            }
    
    return DynamicModule
