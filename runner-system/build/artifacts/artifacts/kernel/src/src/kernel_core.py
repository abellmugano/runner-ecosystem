"""
Kernel Core - Official execution contract
Defines the standard interface for all module executions
"""

from typing import Any, Dict, Optional
from datetime import datetime
import json


class ExecutionResult:
    """Standardized execution result format"""
    
    def __init__(
        self,
        success: bool,
        data: Any = None,
        error: Optional[str] = None,
        metadata: Optional[Dict] = None
    ):
        self.success = success
        self.data = data
        self.error = error
        self.metadata = metadata or {}
        self.timestamp = datetime.utcnow().isoformat()
    
    def to_dict(self) -> Dict:
        return {
            "success": self.success,
            "data": self.data,
            "error": self.error,
            "metadata": self.metadata,
            "timestamp": self.timestamp
        }
    
    def to_json(self) -> str:
        return json.dumps(self.to_dict())
    
    @classmethod
    def ok(cls, data: Any = None, metadata: Optional[Dict] = None) -> "ExecutionResult":
        return cls(success=True, data=data, metadata=metadata)
    
    @classmethod
    def error(cls, error: str, metadata: Optional[Dict] = None) -> "ExecutionResult":
        return cls(success=False, error=error, metadata=metadata)


class KernelCore:
    """
    Main kernel interface for module execution
    Implements the official execution contract
    """
    
    VERSION = "1.0.0"
    
    def __init__(self):
        self.modules = {}
        self.execution_count = 0
    
    def register_module(self, name: str, module_class: type) -> bool:
        """Register a module with the kernel"""
        if not name or not isinstance(name, str):
            return False
        if name in self.modules:
            return False
        self.modules[name] = module_class
        return True
    
    def execute(
        self,
        module_name: str,
        action: str,
        params: Optional[Dict] = None,
        context: Optional[Dict] = None
    ) -> ExecutionResult:
        """Execute a module action through the kernel"""
        self.execution_count += 1
        
        if module_name not in self.modules:
            return ExecutionResult.error(f"Module not found: {module_name}")
        
        try:
            module = self.modules[module_name]()
            
            if not hasattr(module, action):
                return ExecutionResult.error(f"Action not found: {action}")
            
            method = getattr(module, action)
            result = method(params or {}, context or {})
            
            return ExecutionResult.ok(data=result, metadata={
                "module": module_name,
                "action": action,
                "execution_id": self.execution_count
            })
            
        except Exception as e:
            return ExecutionResult.error(str(e), metadata={
                "module": module_name,
                "action": action,
                "execution_id": self.execution_count
            })
    
    def get_status(self) -> Dict:
        """Get kernel status"""
        return {
            "version": self.VERSION,
            "registered_modules": list(self.modules.keys()),
            "execution_count": self.execution_count
        }


kernel_instance = KernelCore()
