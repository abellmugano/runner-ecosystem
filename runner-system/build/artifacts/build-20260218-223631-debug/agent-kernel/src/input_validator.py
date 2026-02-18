"""
Input Validator - Standardized input validation
Ensures all inputs conform to the kernel contract
"""

from typing import Any, Dict, List, Optional
import re


class ValidationError(Exception):
    """Raised when validation fails"""
    pass


class InputValidator:
    """Validates input according to kernel standards"""
    
    @staticmethod
    def validate_module_name(name: str) -> bool:
        """Validate module name format"""
        if not isinstance(name, str):
            raise ValidationError("Module name must be a string")
        if not name:
            raise ValidationError("Module name cannot be empty")
        if not re.match(r'^[a-zA-Z][a-zA-Z0-9_-]*$', name):
            raise ValidationError(
                "Module name must start with letter and contain only alphanumeric, underscore, or hyphen"
            )
        return True
    
    @staticmethod
    def validate_action(action: str) -> bool:
        """Validate action name format"""
        if not isinstance(action, str):
            raise ValidationError("Action must be a string")
        if not action:
            raise ValidationError("Action cannot be empty")
        if not re.match(r'^[a-zA-Z][a-zA-Z0-9_]*$', action):
            raise ValidationError(
                "Action must start with letter and contain only alphanumeric or underscore"
            )
        return True
    
    @staticmethod
    def validate_params(params: Any, required_keys: Optional[List[str]] = None) -> bool:
        """Validate parameters dictionary"""
        if not isinstance(params, dict):
            raise ValidationError("Parameters must be a dictionary")
        
        if required_keys:
            missing = set(required_keys) - set(params.keys())
            if missing:
                raise ValidationError(f"Missing required keys: {missing}")
        
        return True
    
    @staticmethod
    def validate_context(context: Optional[Dict]) -> bool:
        """Validate execution context"""
        if context is None:
            return True
        if not isinstance(context, dict):
            raise ValidationError("Context must be a dictionary")
        
        allowed_keys = {"user", "session", "request_id", "permissions", "environment"}
        extra_keys = set(context.keys()) - allowed_keys
        if extra_keys:
            raise ValidationError(f"Unknown context keys: {extra_keys}")
        
        return True
    
    @staticmethod
    def validate_execution_request(request: Dict) -> bool:
        """Validate complete execution request"""
        if not isinstance(request, dict):
            raise ValidationError("Request must be a dictionary")
        
        required = ["module", "action"]
        missing = set(required) - set(request.keys())
        if missing:
            raise ValidationError(f"Missing required fields: {missing}")
        
        InputValidator.validate_module_name(request["module"])
        InputValidator.validate_action(request["action"])
        InputValidator.validate_params(request.get("params", {}))
        InputValidator.validate_context(request.get("context"))
        
        return True


def validate_input(request: Dict) -> bool:
    """Convenience function for input validation"""
    return InputValidator.validate_execution_request(request)
