"""
Tests for Module System Agent
"""

import unittest
import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

from module_template import BaseModule, ModuleTemplate, ModuleManifest, create_module_class
from module_validator import ModuleValidator, ValidationResult
from example_module import ExampleModule, CalculatorModule


class TestModuleManifest(unittest.TestCase):
    """Test module manifest"""
    
    def test_valid_manifest(self):
        manifest_data = {
            "name": "test_module",
            "version": "1.0.0",
            "description": "Test module",
            "author": "Test Author"
        }
        manifest = ModuleManifest(manifest_data)
        self.assertEqual(manifest.name, "test_module")
        self.assertEqual(manifest.version, "1.0.0")
    
    def test_invalid_manifest_missing_field(self):
        manifest_data = {
            "name": "test_module",
            "version": "1.0.0"
        }
        with self.assertRaises(ValueError):
            ModuleManifest(manifest_data)
    
    def test_manifest_properties(self):
        manifest_data = {
            "name": "test_module",
            "version": "1.0.0",
            "description": "Test module",
            "author": "Test Author",
            "dependencies": ["dep1", "dep2"],
            "actions": ["run", "stop"]
        }
        manifest = ModuleManifest(manifest_data)
        self.assertEqual(manifest.dependencies, ["dep1", "dep2"])
        self.assertEqual(manifest.actions, ["run", "stop"])


class TestModuleTemplate(unittest.TestCase):
    """Test module template"""
    
    def setUp(self):
        self.template = ModuleTemplate()
    
    def test_validate_manifest(self):
        result = self.template.validate_manifest()
        self.assertTrue(result)
    
    def test_initialize(self):
        result = self.template.initialize({"config": "value"})
        self.assertTrue(result)
        self.assertTrue(self.template.is_initialized())
    
    def test_execute_run(self):
        result = self.template.execute("run", {"key": "value"}, {})
        self.assertTrue(result["success"])
    
    def test_execute_validate(self):
        result = self.template.execute("validate", {}, {})
        self.assertTrue(result["valid"])
    
    def test_execute_status(self):
        self.template.initialize({})
        result = self.template.execute("status", {}, {})
        self.assertTrue(result["initialized"])
    
    def test_execute_unknown_action(self):
        result = self.template.execute("unknown", {}, {})
        self.assertIn("error", result)


class TestCreateModuleClass(unittest.TestCase):
    """Test dynamic module creation"""
    
    def test_create_module_class(self):
        manifest = {
            "name": "dynamic_module",
            "version": "1.0.0",
            "description": "Dynamic module",
            "author": "Test"
        }
        
        module_class = create_module_class(manifest)
        module = module_class()
        
        self.assertEqual(module.get_manifest()["name"], "dynamic_module")
        
        result = module.execute("test", {}, {})
        self.assertTrue(result["success"])


class TestModuleValidator(unittest.TestCase):
    """Test module validator"""
    
    def test_validate_manifest_valid(self):
        manifest = {
            "name": "valid_module",
            "version": "1.0.0",
            "description": "Valid module",
            "author": "Test"
        }
        result = ModuleValidator.validate_manifest(manifest)
        self.assertTrue(result.valid)
    
    def test_validate_manifest_missing_field(self):
        manifest = {
            "name": "invalid_module",
            "version": "1.0.0"
        }
        result = ModuleValidator.validate_manifest(manifest)
        self.assertFalse(result.valid)
    
    def test_validate_manifest_invalid_name(self):
        manifest = {
            "name": "123_invalid",
            "version": "1.0.0",
            "description": "Invalid",
            "author": "Test"
        }
        result = ModuleValidator.validate_manifest(manifest)
        self.assertFalse(result.valid)
    
    def test_validate_manifest_version_warning(self):
        manifest = {
            "name": "valid_module",
            "version": "1.0",
            "description": "Invalid version format",
            "author": "Test"
        }
        result = ModuleValidator.validate_manifest(manifest)
        self.assertTrue(result.valid)
        self.assertTrue(len(result.warnings) > 0)
    
    def test_validate_module_class(self):
        result = ModuleValidator.validate_module_class(ExampleModule)
        self.assertTrue(result.valid)
    
    def test_validate_module_class_missing_method(self):
        class InvalidModule:
            def run(self):
                pass
        
        result = ModuleValidator.validate_module_class(InvalidModule)
        self.assertFalse(result.valid)
    
    def test_validate_module_instance(self):
        module = ExampleModule()
        result = ModuleValidator.validate_module_instance(module)
        self.assertTrue(result.valid)
    
    def test_kernel_compatibility(self):
        manifest = {
            "name": "test",
            "version": "1.0.0",
            "description": "Test",
            "author": "Test",
            "kernel_version": "1.0.0"
        }
        result = ModuleValidator.validate_kernel_compatibility(manifest, "1.0.0")
        self.assertTrue(result.valid)


class TestExampleModule(unittest.TestCase):
    """Test example module"""
    
    def setUp(self):
        self.module = ExampleModule()
    
    def test_manifest(self):
        manifest = self.module.get_manifest()
        self.assertEqual(manifest["name"], "example_module")
        self.assertEqual(manifest["version"], "1.0.0")
    
    def test_initialize(self):
        result = self.module.initialize({"setting": "value"})
        self.assertTrue(result)
        self.assertTrue(self.module.is_initialized())
    
    def test_echo_action(self):
        result = self.module.execute("echo", {"message": "test"}, {})
        self.assertTrue(result["success"])
        self.assertEqual(result["result"], "test")
    
    def test_add_action(self):
        result = self.module.execute("add", {"a": 10, "b": 5}, {})
        self.assertTrue(result["success"])
        self.assertEqual(result["result"], 15)
    
    def test_add_action_invalid_params(self):
        result = self.module.execute("add", {"a": "a", "b": 5}, {})
        self.assertFalse(result["success"])
    
    def test_status_action(self):
        self.module.initialize({})
        result = self.module.execute("status", {}, {})
        self.assertTrue(result["success"])
        self.assertTrue(result["initialized"])
    
    def test_configure_action(self):
        result = self.module.execute("configure", {"key": "value"}, {})
        self.assertTrue(result["success"])
        self.assertEqual(result["updated_config"]["key"], "value")


class TestCalculatorModule(unittest.TestCase):
    """Test calculator module"""
    
    def setUp(self):
        self.calc = CalculatorModule()
    
    def test_add(self):
        result = self.calc.execute("add", {"a": 5, "b": 3}, {})
        self.assertEqual(result["result"], 8)
    
    def test_subtract(self):
        result = self.calc.execute("subtract", {"a": 10, "b": 3}, {})
        self.assertEqual(result["result"], 7)
    
    def test_multiply(self):
        result = self.calc.execute("multiply", {"a": 4, "b": 5}, {})
        self.assertEqual(result["result"], 20)
    
    def test_divide(self):
        result = self.calc.execute("divide", {"a": 10, "b": 2}, {})
        self.assertEqual(result["result"], 5)
    
    def test_divide_by_zero(self):
        result = self.calc.execute("divide", {"a": 10, "b": 0}, {})
        self.assertFalse(result["success"])
    
    def test_history(self):
        self.calc.execute("add", {"a": 1, "b": 2}, {})
        self.calc.execute("add", {"a": 3, "b": 4}, {})
        
        result = self.calc.execute("history", {}, {})
        self.assertEqual(len(result["history"]), 2)


if __name__ == "__main__":
    unittest.main()
