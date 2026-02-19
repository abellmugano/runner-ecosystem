"""
Example Module - Official example module demonstrating module pattern
"""

from typing import Any, Dict
from module_template import BaseModule


class ExampleModule(BaseModule):
    """Example module showing proper module implementation"""
    
    def __init__(self):
        super().__init__()
        self._config = {}
        self._execution_count = 0
    
    def get_manifest(self) -> Dict:
        return {
            "name": "example_module",
            "version": "1.0.0",
            "description": "Example module demonstrating the module pattern",
            "author": "Runner Ecosystem",
            "dependencies": [],
            "actions": [
                "echo",
                "add",
                "status",
                "configure"
            ],
            "kernel_version": "1.0.0"
        }
    
    def initialize(self, config: Dict) -> bool:
        self._config = config
        self._initialized = True
        return True
    
    def execute(self, action: str, params: Dict, context: Dict) -> Dict:
        self._execution_count += 1
        
        action_map = {
            "echo": self._echo,
            "add": self._add,
            "status": self._status,
            "configure": self._configure
        }
        
        if action not in action_map:
            return {
                "success": False,
                "error": f"Unknown action: {action}"
            }
        
        return action_map[action](params, context)
    
    def _echo(self, params: Dict, context: Dict) -> Dict:
        message = params.get("message", "Hello from example module!")
        return {
            "success": True,
            "action": "echo",
            "result": message,
            "execution_count": self._execution_count
        }
    
    def _add(self, params: Dict, context: Dict) -> Dict:
        a = params.get("a", 0)
        b = params.get("b", 0)
        
        if not isinstance(a, (int, float)) or not isinstance(b, (int, float)):
            return {
                "success": False,
                "error": "Parameters 'a' and 'b' must be numbers"
            }
        
        return {
            "success": True,
            "action": "add",
            "result": a + b,
            "execution_count": self._execution_count
        }
    
    def _status(self, params: Dict, context: Dict) -> Dict:
        return {
            "success": True,
            "action": "status",
            "initialized": self._initialized,
            "config": self._config,
            "execution_count": self._execution_count,
            "manifest": self.get_manifest()
        }
    
    def _configure(self, params: Dict, context: Dict) -> Dict:
        for key, value in params.items():
            self._config[key] = value
        
        return {
            "success": True,
            "action": "configure",
            "updated_config": self._config
        }


class CalculatorModule(BaseModule):
    """Another example: Simple calculator module"""
    
    def __init__(self):
        super().__init__()
        self._history = []
    
    def get_manifest(self) -> Dict:
        return {
            "name": "calculator_module",
            "version": "1.0.0",
            "description": "Simple calculator module",
            "author": "Runner Ecosystem",
            "dependencies": [],
            "actions": ["add", "subtract", "multiply", "divide", "history"]
        }
    
    def initialize(self, config: Dict) -> bool:
        self._initialized = True
        return True
    
    def execute(self, action: str, params: Dict, context: Dict) -> Dict:
        ops = {
            "add": lambda a, b: a + b,
            "subtract": lambda a, b: a - b,
            "multiply": lambda a, b: a * b,
            "divide": lambda a, b: a / b if b != 0 else None
        }
        
        if action == "history":
            return {
                "success": True,
                "history": self._history
            }
        
        if action not in ops:
            return {
                "success": False,
                "error": f"Unknown action: {action}"
            }
        
        a = params.get("a", 0)
        b = params.get("b", 0)
        
        result = ops[action](a, b)
        
        if result is None:
            return {
                "success": False,
                "error": "Division by zero"
            }
        
        self._history.append({
            "action": action,
            "a": a,
            "b": b,
            "result": result
        })
        
        return {
            "success": True,
            "result": result
        }


if __name__ == "__main__":
    module = ExampleModule()
    
    print("=== Example Module Test ===")
    
    module.initialize({"debug": True})
    print(f"Initialized: {module.is_initialized()}")
    
    result = module.execute("echo", {"message": "Hello!"}, {})
    print(f"Echo: {result}")
    
    result = module.execute("add", {"a": 5, "b": 3}, {})
    print(f"Add: {result}")
    
    result = module.execute("status", {}, {})
    print(f"Status: {result}")
