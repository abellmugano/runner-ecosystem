"""
Tests for Kernel Agent
"""

import unittest
import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

from kernel_core import KernelCore, ExecutionResult
from input_validator import InputValidator, validate_input, ValidationError
from error_handler import (
    ErrorHandler, KernelError, ErrorCode,
    ValidationError as KernelValidationError,
    ModuleNotFoundError, ActionNotFoundError
)
from permissions import Permissions, PermissionLevel


class TestKernelCore(unittest.TestCase):
    """Test kernel core functionality"""
    
    def setUp(self):
        self.kernel = KernelCore()
    
    def test_kernel_version(self):
        self.assertEqual(self.kernel.VERSION, "1.0.0")
    
    def test_register_module(self):
        class TestModule:
            def run(self, params, context):
                return "test"
        
        result = self.kernel.register_module("test", TestModule)
        self.assertTrue(result)
        self.assertIn("test", self.kernel.modules)
    
    def test_register_duplicate_module(self):
        class TestModule:
            def run(self, params, context):
                return "test"
        
        self.kernel.register_module("test", TestModule)
        result = self.kernel.register_module("test", TestModule)
        self.assertFalse(result)
    
    def test_execute_module_not_found(self):
        result = self.kernel.execute("nonexistent", "run")
        self.assertFalse(result.success)
        self.assertIn("not found", result.error)
    
    def test_execute_success(self):
        class TestModule:
            def run(self, params, context):
                return {"message": "success"}
        
        self.kernel.register_module("test", TestModule)
        result = self.kernel.execute("test", "run", {"value": 1})
        
        self.assertTrue(result.success)
        self.assertEqual(result.data["message"], "success")
        self.assertIn("execution_id", result.metadata)
    
    def test_get_status(self):
        status = self.kernel.get_status()
        self.assertEqual(status["version"], "1.0.0")
        self.assertIn("registered_modules", status)


class TestExecutionResult(unittest.TestCase):
    """Test ExecutionResult class"""
    
    def test_ok_result(self):
        result = ExecutionResult.ok({"data": "value"})
        self.assertTrue(result.success)
        self.assertEqual(result.data["data"], "value")
    
    def test_error_result(self):
        result = ExecutionResult.error("Something went wrong")
        self.assertFalse(result.success)
        self.assertEqual(result.error, "Something went wrong")
    
    def test_to_dict(self):
        result = ExecutionResult.ok({"key": "value"})
        d = result.to_dict()
        self.assertTrue(d["success"])
        self.assertIn("timestamp", d)


class TestInputValidator(unittest.TestCase):
    """Test input validation"""
    
    def test_validate_module_name_valid(self):
        self.assertTrue(InputValidator.validate_module_name("test_module"))
        self.assertTrue(InputValidator.validate_module_name("TestModule123"))
    
    def test_validate_module_name_invalid(self):
        with self.assertRaises(ValidationError):
            InputValidator.validate_module_name("")
        with self.assertRaises(ValidationError):
            InputValidator.validate_module_name("123_invalid")
        with self.assertRaises(ValidationError):
            InputValidator.validate_module_name(None)
    
    def test_validate_action_valid(self):
        self.assertTrue(InputValidator.validate_action("run"))
        self.assertTrue(InputValidator.validate_action("execute_test"))
    
    def test_validate_action_invalid(self):
        with self.assertRaises(ValidationError):
            InputValidator.validate_action("")
    
    def test_validate_params(self):
        self.assertTrue(InputValidator.validate_params({"key": "value"}))
        self.assertTrue(InputValidator.validate_params({}, []))
        self.assertTrue(InputValidator.validate_params({"a": 1}, ["a"]))
        
        with self.assertRaises(ValidationError):
            InputValidator.validate_params("not a dict")
    
    def test_validate_execution_request(self):
        valid_request = {
            "module": "test",
            "action": "run",
            "params": {},
            "context": {}
        }
        self.assertTrue(validate_input(valid_request))
        
        with self.assertRaises(ValidationError):
            validate_input({})


class TestPermissions(unittest.TestCase):
    """Test permission system"""
    
    def setUp(self):
        self.perms = Permissions()
    
    def test_set_user_permissions(self):
        self.perms.set_user_permissions("user1", ["read", "write"])
        self.assertIn("read", self.perms.get_user_permissions("user1"))
    
    def test_has_permission(self):
        self.perms.set_user_permissions("user1", ["read"])
        self.assertTrue(self.perms.has_permission("user1", "read"))
        self.assertFalse(self.perms.has_permission("user1", "write"))
    
    def test_whitelist(self):
        self.perms.whitelist("user1", ["execute"])
        self.assertTrue(self.perms.has_permission("user1", "execute"))
    
    def test_blacklist(self):
        self.perms.set_user_permissions("user1", ["read", "write"])
        self.perms.blacklist("user1", ["write"])
        self.assertTrue(self.perms.has_permission("user1", "read"))
        self.assertFalse(self.perms.has_permission("user1", "write"))
    
    def test_check_access(self):
        self.perms.set_user_permissions("user1", ["test:run"])
        self.assertTrue(self.perms.check_access("user1", "test", "run"))
    
    def test_require_permission(self):
        self.perms.set_user_permissions("user1", ["read"])
        self.perms.require_permission("user1", "read")
        
        with self.assertRaises(PermissionError):
            self.perms.require_permission("user1", "write")


class TestErrorHandler(unittest.TestCase):
    """Test error handler"""
    
    def setUp(self):
        self.handler = ErrorHandler()
    
    def test_handle_kernel_error(self):
        error = ModuleNotFoundError("test")
        result = self.handler.handle(error)
        
        self.assertFalse(result["success"])
        self.assertEqual(result["code"], ErrorCode.MODULE_NOT_FOUND)
    
    def test_handle_generic_error(self):
        error = ValueError("test error")
        result = self.handler.handle(error)
        
        self.assertFalse(result["success"])
        self.assertEqual(result["code"], ErrorCode.UNKNOWN)
    
    def test_error_history(self):
        error = ValueError("test")
        self.handler.handle(error)
        
        history = self.handler.get_error_history()
        self.assertEqual(len(history), 1)
    
    def test_clear_history(self):
        error = ValueError("test")
        self.handler.handle(error)
        self.handler.clear_history()
        
        self.assertEqual(len(self.handler.get_error_history()), 0)


if __name__ == "__main__":
    unittest.main()
