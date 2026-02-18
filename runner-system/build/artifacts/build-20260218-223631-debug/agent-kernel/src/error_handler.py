"""
Error Handler - Uniform error handling
Provides consistent error handling across all modules
"""

from typing import Any, Dict, Optional
from datetime import datetime
import traceback
import json


class ErrorCode:
    """Standard error codes"""
    UNKNOWN = "E000"
    VALIDATION = "E001"
    MODULE_NOT_FOUND = "E002"
    ACTION_NOT_FOUND = "E003"
    PERMISSION_DENIED = "E004"
    EXECUTION_FAILED = "E005"
    TIMEOUT = "E006"
    INVALID_INPUT = "E007"


class KernelError(Exception):
    """Base exception for kernel errors"""
    
    def __init__(
        self,
        message: str,
        code: str = ErrorCode.UNKNOWN,
        details: Optional[Dict] = None
    ):
        super().__init__(message)
        self.message = message
        self.code = code
        self.details = details or {}
        self.timestamp = datetime.utcnow().isoformat()
    
    def to_dict(self) -> Dict:
        return {
            "error": self.message,
            "code": self.code,
            "details": self.details,
            "timestamp": self.timestamp
        }


class ValidationError(KernelError):
    """Validation error"""
    def __init__(self, message: str, details: Optional[Dict] = None):
        super().__init__(message, ErrorCode.VALIDATION, details)


class ModuleNotFoundError(KernelError):
    """Module not found error"""
    def __init__(self, module_name: str):
        super().__init__(
            f"Module not found: {module_name}",
            ErrorCode.MODULE_NOT_FOUND,
            {"module": module_name}
        )


class ActionNotFoundError(KernelError):
    """Action not found error"""
    def __init__(self, module_name: str, action: str):
        super().__init__(
            f"Action not found: {action} in {module_name}",
            ErrorCode.ACTION_NOT_FOUND,
            {"module": module_name, "action": action}
        )


class PermissionDeniedError(KernelError):
    """Permission denied error"""
    def __init__(self, required_permission: str):
        super().__init__(
            f"Permission denied: {required_permission}",
            ErrorCode.PERMISSION_DENIED,
            {"required": required_permission}
        )


class ErrorHandler:
    """Centralized error handling"""
    
    def __init__(self):
        self.error_log = []
    
    def handle(
        self,
        exception: Exception,
        context: Optional[Dict] = None
    ) -> Dict:
        """Handle exception and return error response"""
        error_entry = {
            "timestamp": datetime.utcnow().isoformat(),
            "type": type(exception).__name__,
            "message": str(exception),
            "traceback": traceback.format_exc(),
            "context": context or {}
        }
        
        if isinstance(exception, KernelError):
            error_entry["code"] = exception.code
            error_entry["details"] = exception.details
        else:
            error_entry["code"] = ErrorCode.UNKNOWN
        
        self.error_log.append(error_entry)
        
        return {
            "success": False,
            "error": error_entry["message"],
            "code": error_entry.get("code", ErrorCode.UNKNOWN),
            "details": error_entry.get("details", {}),
            "timestamp": error_entry["timestamp"]
        }
    
    def get_error_history(self) -> list:
        """Get error history"""
        return self.error_log
    
    def clear_history(self):
        """Clear error history"""
        self.error_log = []


error_handler = ErrorHandler()
