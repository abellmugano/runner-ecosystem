"""
Version Control - Module version management
Manages version control for modules
"""

from typing import Dict, List, Optional, Tuple
from datetime import datetime
import re


class Version:
    """Semantic version representation"""
    
    def __init__(self, version_string: str):
        self.original = version_string
        self.major, self.minor, self.patch = self._parse(version_string)
    
    def _parse(self, version_string: str) -> Tuple[int, int, int]:
        """Parse semantic version string"""
        match = re.match(r'^(\d+)\.(\d+)\.(\d+)(?:-(.+))?$', version_string)
        if not match:
            raise ValueError(f"Invalid version string: {version_string}")
        return int(match.group(1)), int(match.group(2)), int(match.group(3))
    
    def __str__(self):
        return f"{self.major}.{self.minor}.{self.patch}"
    
    def __repr__(self):
        return f"Version('{str(self)}')"
    
    def __eq__(self, other):
        if not isinstance(other, Version):
            return False
        return (self.major, self.minor, self.patch) == (other.major, other.minor, other.patch)
    
    def __lt__(self, other):
        if not isinstance(other, Version):
            return NotImplemented
        return (self.major, self.minor, self.patch) < (other.major, other.minor, other.patch)
    
    def __le__(self, other):
        return self == other or self < other
    
    def __gt__(self, other):
        return other < self
    
    def __ge__(self, other):
        return self == other or self > other
    
    def __hash__(self):
        return hash((self.major, self.minor, self.patch))
    
    def to_tuple(self) -> Tuple[int, int, int]:
        return (self.major, self.minor, self.patch)


class VersionControl:
    """Version control for modules"""
    
    def __init__(self):
        self._versions: Dict[str, List[Dict]] = {}
        self._current_versions: Dict[str, str] = {}
    
    def register_version(
        self,
        module: str,
        version: str,
        metadata: Optional[Dict] = None
    ) -> bool:
        """Register a new version"""
        try:
            v = Version(version)
        except ValueError:
            return False
        
        if module not in self._versions:
            self._versions[module] = []
        
        version_entry = {
            "version": str(v),
            "timestamp": datetime.utcnow().isoformat(),
            "metadata": metadata or {}
        }
        
        for existing in self._versions[module]:
            if existing["version"] == str(v):
                return False
        
        self._versions[module].append(version_entry)
        self._current_versions[module] = str(v)
        
        return True
    
    def get_versions(self, module: str) -> List[Dict]:
        """Get all versions of a module"""
        return self._versions.get(module, [])
    
    def get_current_version(self, module: str) -> Optional[str]:
        """Get current version of a module"""
        return self._current_versions.get(module)
    
    def set_current_version(self, module: str, version: str) -> bool:
        """Set current version"""
        if module not in self._versions:
            return False
        
        versions = [v["version"] for v in self._versions[module]]
        if version not in versions:
            return False
        
        self._current_versions[module] = version
        return True
    
    def is_compatible(
        self,
        required_version: str,
        current_version: str
    ) -> bool:
        """Check if versions are compatible"""
        try:
            required = Version(required_version)
            current = Version(current_version)
            
            if required.major == current.major:
                return True
            
            return False
        except ValueError:
            return False
    
    def get_latest_version(self, module: str) -> Optional[str]:
        """Get latest version"""
        versions = self._versions.get(module, [])
        if not versions:
            return None
        
        sorted_versions = sorted(
            versions,
            key=lambda v: Version(v["version"]),
            reverse=True
        )
        return sorted_versions[0]["version"]
    
    def compare_versions(self, v1: str, v2: str) -> int:
        """Compare two versions: -1, 0, 1"""
        try:
            version1 = Version(v1)
            version2 = Version(v2)
            
            if version1 < version2:
                return -1
            elif version1 > version2:
                return 1
            return 0
        except ValueError:
            return 0
    
    def increment_major(self, module: str) -> Optional[str]:
        """Increment major version"""
        return self._increment(module, "major")
    
    def increment_minor(self, module: str) -> Optional[str]:
        """Increment minor version"""
        return self._increment(module, "minor")
    
    def increment_patch(self, module: str) -> Optional[str]:
        """Increment patch version"""
        return self._increment(module, "patch")
    
    def _increment(self, module: str, part: str) -> Optional[str]:
        """Increment version"""
        current = self.get_current_version(module)
        if not current:
            return None
        
        v = Version(current)
        
        if part == "major":
            v.major += 1
            v.minor = 0
            v.patch = 0
        elif part == "minor":
            v.minor += 1
            v.patch = 0
        else:
            v.patch += 1
        
        new_version = str(v)
        self.register_version(module, new_version)
        return new_version
    
    def get_module_count(self) -> int:
        """Get number of modules"""
        return len(self._versions)
    
    def clear(self):
        """Clear all versions"""
        self._versions = {}
        self._current_versions = {}


version_control = VersionControl()
