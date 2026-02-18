"""
Permissions - Access control and permission management
Implements kernel-level permission controls
"""

from typing import Any, Dict, List, Optional, Set
from enum import Enum


class PermissionLevel(Enum):
    """Permission levels"""
    NONE = 0
    READ = 1
    EXECUTE = 2
    WRITE = 3
    ADMIN = 4


class Permission:
    """Represents a single permission"""
    
    def __init__(self, name: str, level: PermissionLevel):
        self.name = name
        self.level = level
    
    def __repr__(self):
        return f"Permission({self.name}, {self.level.name})"


class Permissions:
    """Permission management for modules and actions"""
    
    def __init__(self):
        self._user_permissions: Dict[str, Set[str]] = {}
        self._module_permissions: Dict[str, Set[str]] = {}
        self._whitelist: Dict[str, Set[str]] = {}
        self._blacklist: Dict[str, Set[str]] = {}
    
    def set_user_permissions(self, user: str, permissions: List[str]) -> None:
        """Set permissions for a user"""
        self._user_permissions[user] = set(permissions)
    
    def add_user_permission(self, user: str, permission: str) -> None:
        """Add a permission to a user"""
        if user not in self._user_permissions:
            self._user_permissions[user] = set()
        self._user_permissions[user].add(permission)
    
    def get_user_permissions(self, user: str) -> Set[str]:
        """Get all permissions for a user"""
        return self._user_permissions.get(user, set())
    
    def has_permission(self, user: str, permission: str) -> bool:
        """Check if user has a specific permission"""
        if permission in self._blacklist.get(user, set()):
            return False
        
        user_perms = self.get_user_permissions(user)
        
        if permission in user_perms:
            return True
        
        return permission in self._whitelist.get(user, set())
    
    def set_module_permission(self, module: str, permission: str) -> None:
        """Set a permission for a module"""
        if module not in self._module_permissions:
            self._module_permissions[module] = set()
        self._module_permissions[module].add(permission)
    
    def get_module_permissions(self, module: str) -> Set[str]:
        """Get all permissions for a module"""
        return self._module_permissions.get(module, set())
    
    def whitelist(self, user: str, permissions: List[str]) -> None:
        """Add permissions to whitelist for user"""
        self._whitelist[user] = set(permissions)
    
    def blacklist(self, user: str, permissions: List[str]) -> None:
        """Add permissions to blacklist for user"""
        self._blacklist[user] = set(permissions)
    
    def check_access(
        self,
        user: str,
        module: str,
        action: str,
        context: Optional[Dict] = None
    ) -> bool:
        """Check if user can access module/action"""
        permission = f"{module}:{action}"
        
        if self.has_permission(user, permission):
            return True
        
        if self.has_permission(user, f"{module}:*"):
            return True
        
        if self.has_permission(user, "*"):
            return True
        
        return False
    
    def require_permission(
        self,
        user: str,
        permission: str,
        context: Optional[Dict] = None
    ) -> None:
        """Raise exception if user lacks permission"""
        if not self.has_permission(user, permission):
            raise PermissionError(f"Permission denied: {permission}")
    
    def get_all_permissions(self) -> Dict:
        """Get all permission configurations"""
        return {
            "users": {k: list(v) for k, v in self._user_permissions.items()},
            "modules": {k: list(v) for k, v in self._module_permissions.items()},
            "whitelists": {k: list(v) for k, v in self._whitelist.items()},
            "blacklists": {k: list(v) for k, v in self._blacklist.items()}
        }


permissions = Permissions()
