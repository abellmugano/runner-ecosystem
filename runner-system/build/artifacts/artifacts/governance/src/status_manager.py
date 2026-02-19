"""
Status Manager - Module status management
Controls module status transitions
"""

from typing import Dict, List, Optional
from datetime import datetime


class StatusTransition:
    """Represents a status transition"""
    
    def __init__(
        self,
        module: str,
        from_status: str,
        to_status: str,
        reason: str,
        timestamp: Optional[str] = None
    ):
        self.module = module
        self.from_status = from_status
        self.to_status = to_status
        self.reason = reason
        self.timestamp = timestamp or datetime.utcnow().isoformat()
    
    def to_dict(self) -> Dict:
        return {
            "module": self.module,
            "from_status": self.from_status,
            "to_status": self.to_status,
            "reason": self.reason,
            "timestamp": self.timestamp
        }


class StatusManager:
    """Manages module status transitions"""
    
    VALID_STATUSES = ["active", "experimental", "deprecated", "disabled"]
    
    ALLOWED_TRANSITIONS = {
        "experimental": ["active", "disabled"],
        "active": ["deprecated", "disabled"],
        "deprecated": ["disabled", "active"],
        "disabled": ["active", "experimental"]
    }
    
    def __init__(self):
        self._transitions: List[StatusTransition] = []
        self._current_status: Dict[str, str] = {}
    
    def set_status(
        self,
        module: str,
        status: str,
        reason: str = ""
    ) -> bool:
        """Set module status"""
        if status not in self.VALID_STATUSES:
            return False
        
        old_status = self._current_status.get(module, "experimental")
        
        if old_status != status:
            if not self._is_transition_allowed(old_status, status):
                return False
            
            transition = StatusTransition(
                module=module,
                from_status=old_status,
                to_status=status,
                reason=reason
            )
            self._transitions.append(transition)
        
        self._current_status[module] = status
        return True
    
    def _is_transition_allowed(self, from_status: str, to_status: str) -> bool:
        """Check if transition is allowed"""
        if from_status == to_status:
            return True
        
        allowed = self.ALLOWED_TRANSITIONS.get(from_status, [])
        return to_status in allowed
    
    def get_status(self, module: str) -> Optional[str]:
        """Get current status of module"""
        return self._current_status.get(module)
    
    def get_modules_by_status(self, status: str) -> List[str]:
        """Get all modules with given status"""
        return [
            module for module, s in self._current_status.items()
            if s == status
        ]
    
    def get_transition_history(
        self,
        module: Optional[str] = None
    ) -> List[StatusTransition]:
        """Get transition history"""
        if module:
            return [t for t in self._transitions if t.module == module]
        return self._transitions
    
    def can_transition(self, from_status: str, to_status: str) -> bool:
        """Check if transition is possible"""
        return self._is_transition_allowed(from_status, to_status)
    
    def get_allowed_transitions(self, status: str) -> List[str]:
        """Get allowed transitions from status"""
        return self.ALLOWED_TRANSITIONS.get(status, [])
    
    def validate_status(self, status: str) -> bool:
        """Validate status value"""
        return status in self.VALID_STATUSES
    
    def reset(self):
        """Reset status manager"""
        self._transitions = []
        self._current_status = {}


status_manager = StatusManager()
