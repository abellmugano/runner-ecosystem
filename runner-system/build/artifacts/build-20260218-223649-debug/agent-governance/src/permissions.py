"""
Permissions - Governance permissions control
Manages module and user permissions for governance
"""

from typing import Any, Dict, List, Optional, Set
from datetime import datetime


class GovernancePermission:
    """Permission types for governance"""
    
    READ = "governance:read"
    WRITE = "governance:write"
    REGISTER = "governance:register"
    UNREGISTER = "governance:unregister"
    MANAGE_STATUS = "governance:status"
    MANAGE_VERSION = "governance:version"
    ADMIN = "governance:admin"


class PermissionGrant:
    """Permission grant record"""
    
    def __init__(
        self,
        principal: str,
        permission: str,
        granted_by: str,
        granted_at: Optional[str] = None,
        expires_at: Optional[str] = None
    ):
        self.principal = principal
        self.permission = permission
        self.granted_by = granted_by
        self.granted_at = granted_at or datetime.utcnow().isoformat()
        self.expires_at = expires_at
    
    def is_expired(self) -> bool:
        """Check if grant is expired"""
        if not self.expires_at:
            return False
        return datetime.utcnow().isoformat() > self.expires_at
    
    def to_dict(self) -> Dict:
        return {
            "principal": self.principal,
            "permission": self.permission,
            "granted_by": self.granted_by,
            "granted_at": self.granted_at,
            "expires_at": self.expires_at
        }


class GovernancePermissions:
    """Governance permissions manager"""
    
    def __init__(self):
        self._grants: List[PermissionGrant] = []
        self._whitelist: Dict[str, Set[str]] = {}
        self._blacklist: Dict[str, Set[str]] = {}
    
    def grant_permission(
        self,
        principal: str,
        permission: str,
        granted_by: str,
        expires_at: Optional[str] = None
    ) -> bool:
        """Grant a permission"""
        grant = PermissionGrant(principal, permission, granted_by, expires_at=expires_at)
        self._grants.append(grant)
        return True
    
    def revoke_permission(self, principal: str, permission: str) -> bool:
        """Revoke a permission"""
        for grant in self._grants:
            if grant.principal == principal and grant.permission == permission:
                self._grants.remove(grant)
                return True
        return False
    
    def has_permission(self, principal: str, permission: str) -> bool:
        """Check if principal has permission"""
        if principal in self._blacklist:
            if permission in self._blacklist[principal]:
                return False
        
        if principal in self._whitelist:
            if permission in self._whitelist[principal]:
                return True
        
        for grant in self._grants:
            if grant.principal == principal:
                if grant.permission == permission and not grant.is_expired():
                    return True
                if grant.permission == GovernancePermission.ADMIN:
                    return True
        
        return False
    
    def add_to_whitelist(self, principal: str, permissions: List[str]):
        """Add permissions to whitelist"""
        if principal not in self._whitelist:
            self._whitelist[principal] = set()
        self._whitelist[principal].update(permissions)
    
    def add_to_blacklist(self, principal: str, permissions: List[str]):
        """Add permissions to blacklist"""
        if principal not in self._blacklist:
            self._blacklist[principal] = set()
        self._blacklist[principal].update(permissions)
    
    def remove_from_whitelist(self, principal: str, permissions: List[str]):
        """Remove permissions from whitelist"""
        if principal in self._whitelist:
            self._whitelist[principal].difference_update(permissions)
    
    def remove_from_blacklist(self, principal: str, permissions: List[str]):
        """Remove permissions from blacklist"""
        if principal in self._blacklist:
            self._blacklist[principal].difference_update(permissions)
    
    def get_grants(self, principal: Optional[str] = None) -> List[PermissionGrant]:
        """Get permission grants"""
        if principal:
            return [g for g in self._grants if g.principal == principal]
        return self._grants
    
    def get_whitelist(self, principal: str) -> Set[str]:
        """Get whitelist for principal"""
        return self._whitelist.get(principal, set())
    
    def get_blacklist(self, principal: str) -> Set[str]:
        """Get blacklist for principal"""
        return self._blacklist.get(principal, set())
    
    def check_permission(self, principal: str, permission: str) -> bool:
        """Check and raise if no permission"""
        if not self.has_permission(principal, permission):
            raise PermissionError(f"Permission denied: {permission}")
        return True
    
    def clear(self):
        """Clear all permissions"""
        self._grants = []
        self._whitelist = {}
        self._blacklist = {}


governance_permissions = GovernancePermissions()
