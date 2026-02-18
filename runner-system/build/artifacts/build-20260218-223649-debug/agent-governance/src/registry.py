"""
Registry - Module registry management
Maintains official registry of all modules
"""

from typing import Any, Dict, List, Optional
from datetime import datetime
import json
import os


class ModuleStatus:
    """Module status types"""
    ACTIVE = "active"
    EXPERIMENTAL = "experimental"
    DEPRECATED = "deprecated"
    DISABLED = "disabled"


class RegistryEntry:
    """Registry entry for a module"""
    
    def __init__(
        self,
        name: str,
        version: str,
        status: str,
        manifest: Dict,
        registered_at: Optional[str] = None
    ):
        self.name = name
        self.version = version
        self.status = status
        self.manifest = manifest
        self.registered_at = registered_at or datetime.utcnow().isoformat()
        self.updated_at = self.registered_at
    
    def update_version(self, version: str):
        """Update module version"""
        self.version = version
        self.updated_at = datetime.utcnow().isoformat()
    
    def update_status(self, status: str):
        """Update module status"""
        self.status = status
        self.updated_at = datetime.utcnow().isoformat()
    
    def to_dict(self) -> Dict:
        return {
            "name": self.name,
            "version": self.version,
            "status": self.status,
            "manifest": self.manifest,
            "registered_at": self.registered_at,
            "updated_at": self.updated_at
        }
    
    @classmethod
    def from_dict(cls, data: Dict) -> "RegistryEntry":
        return cls(
            name=data["name"],
            version=data["version"],
            status=data["status"],
            manifest=data["manifest"],
            registered_at=data.get("registered_at")
        )


class Registry:
    """Module registry"""
    
    def __init__(self):
        self._entries: Dict[str, RegistryEntry] = {}
        self._registry_file = None
    
    def set_registry_file(self, filepath: str):
        """Set registry file path"""
        self._registry_file = filepath
        os.makedirs(os.path.dirname(filepath), exist_ok=True)
        
        if os.path.exists(filepath):
            self._load()
    
    def _load(self):
        """Load registry from file"""
        try:
            with open(self._registry_file, 'r') as f:
                data = json.load(f)
                for name, entry_data in data.items():
                    self._entries[name] = RegistryEntry.from_dict(entry_data)
        except Exception:
            pass
    
    def _save(self):
        """Save registry to file"""
        if not self._registry_file:
            return
        
        try:
            data = {name: entry.to_dict() for name, entry in self._entries.items()}
            with open(self._registry_file, 'w') as f:
                json.dump(data, f, indent=2)
        except Exception:
            pass
    
    def register(
        self,
        name: str,
        version: str,
        manifest: Dict,
        status: str = ModuleStatus.ACTIVE
    ) -> bool:
        """Register a module"""
        if name in self._entries:
            return False
        
        entry = RegistryEntry(name, version, status, manifest)
        self._entries[name] = entry
        self._save()
        return True
    
    def unregister(self, name: str) -> bool:
        """Unregister a module"""
        if name not in self._entries:
            return False
        
        del self._entries[name]
        self._save()
        return True
    
    def update_status(self, name: str, status: str) -> bool:
        """Update module status"""
        if name not in self._entries:
            return False
        
        self._entries[name].update_status(status)
        self._save()
        return True
    
    def update_version(self, name: str, version: str) -> bool:
        """Update module version"""
        if name not in self._entries:
            return False
        
        self._entries[name].update_version(version)
        self._save()
        return True
    
    def get(self, name: str) -> Optional[RegistryEntry]:
        """Get module entry"""
        return self._entries.get(name)
    
    def get_by_status(self, status: str) -> List[RegistryEntry]:
        """Get modules by status"""
        return [e for e in self._entries.values() if e.status == status]
    
    def list_all(self) -> List[RegistryEntry]:
        """List all registered modules"""
        return list(self._entries.values())
    
    def list_names(self) -> List[str]:
        """List all module names"""
        return list(self._entries.keys())
    
    def exists(self, name: str) -> bool:
        """Check if module exists"""
        return name in self._entries
    
    def is_active(self, name: str) -> bool:
        """Check if module is active"""
        entry = self._entries.get(name)
        return entry and entry.status == ModuleStatus.ACTIVE
    
    def count(self, status: Optional[str] = None) -> int:
        """Count modules"""
        if status:
            return len(self.get_by_status(status))
        return len(self._entries)
    
    def clear(self):
        """Clear registry"""
        self._entries = {}


registry = Registry()
