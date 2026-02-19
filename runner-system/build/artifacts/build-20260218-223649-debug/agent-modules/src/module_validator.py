"""
Module Validator - Validates module structure and compatibility
Ensures modules conform to kernel contract
"""

from typing import Any, Dict, List, Optional, Tuple
import re
import json
import os


class ValidationResult:
    """Result of module validation"""
    
    def __init__(self, valid: bool, errors: Optional[List[str]] = None):
        self.valid = valid
        self.errors = errors or []
        self.warnings = []
    
    def add_error(self, error: str):
        self.errors.append(error)
        self.valid = False
    
    def add_warning(self, warning: str):
        self.warnings.append(warning)
    
    def to_dict(self) -> Dict:
        return {
            "valid": self.valid,
            "errors": self.errors,
            "warnings": self.warnings
        }


class ModuleValidator:
    """Validates module structure and compatibility"""
    
    MANIFEST_REQUIRED = ["name", "version", "description", "author"]
    
    @staticmethod
    def validate_manifest(manifest: Dict) -> ValidationResult:
        """Validate module manifest"""
        result = ValidationResult(True)
        
        for field in ModuleValidator.MANIFEST_REQUIRED:
            if field not in manifest:
                result.add_error(f"Missing required field: {field}")
        
        if "name" in manifest:
            name = manifest["name"]
            if not re.match(r'^[a-zA-Z][a-zA-Z0-9_-]*$', name):
                result.add_error(f"Invalid module name: {name}")
        
        if "version" in manifest:
            version = manifest["version"]
            if not re.match(r'^\d+\.\d+\.\d+$', version):
                result.add_warning(f"Version should follow semver: {version}")
        
        if "dependencies" in manifest:
            if not isinstance(manifest["dependencies"], list):
                result.add_error("Dependencies must be a list")
        
        return result
    
    @staticmethod
    def validate_module_class(module_class: type) -> ValidationResult:
        """Validate module class structure"""
        result = ValidationResult(True)
        
        required_methods = ["get_manifest", "initialize", "execute"]
        for method in required_methods:
            if not hasattr(module_class, method):
                result.add_error(f"Missing required method: {method}")
            elif not callable(getattr(module_class, method)):
                result.add_error(f"Method {method} is not callable")
        
        return result
    
    @staticmethod
    def validate_module_instance(module_instance: Any) -> ValidationResult:
        """Validate module instance"""
        result = ValidationResult(True)
        
        if not hasattr(module_instance, "get_manifest"):
            result.add_error("Module missing get_manifest method")
            return result
        
        try:
            manifest = module_instance.get_manifest()
            manifest_result = ModuleValidator.validate_manifest(manifest)
            if not manifest_result.valid:
                for error in manifest_result.errors:
                    result.add_error(error)
        except Exception as e:
            result.add_error(f"Failed to get manifest: {str(e)}")
        
        return result
    
    @staticmethod
    def validate_kernel_compatibility(
        module_manifest: Dict,
        kernel_version: str
    ) -> ValidationResult:
        """Validate kernel compatibility"""
        result = ValidationResult(True)
        
        if "kernel_version" in module_manifest:
            required = module_manifest["kernel_version"]
            if not ModuleValidator._version_compatible(required, kernel_version):
                result.add_warning(
                    f"Module requires kernel {required}, current is {kernel_version}"
                )
        
        return result
    
    @staticmethod
    def _version_compatible(required: str, current: str) -> bool:
        """Check version compatibility"""
        required_parts = list(map(int, required.split('.')))
        current_parts = list(map(int, current.split('.')))
        
        for r, c in zip(required_parts, current_parts):
            if c < r:
                return False
        return True
    
    @staticmethod
    def validate_file_structure(base_path: str) -> ValidationResult:
        """Validate module file structure"""
        result = ValidationResult(True)
        
        required_files = ["manifest.json"]
        for filename in required_files:
            path = os.path.join(base_path, filename)
            if not os.path.exists(path):
                result.add_error(f"Missing required file: {filename}")
        
        src_path = os.path.join(base_path, "src")
        if os.path.exists(src_path):
            if not os.path.isdir(src_path):
                result.add_error("src must be a directory")
        
        return result
    
    @staticmethod
    def validate_all(module_path: str, kernel_version: str = "1.0.0") -> ValidationResult:
        """Perform full module validation"""
        result = ValidationResult(True)
        
        structure = ModuleValidator.validate_file_structure(module_path)
        if not structure.valid:
            for error in structure.errors:
                result.add_error(error)
            return result
        
        manifest_path = os.path.join(module_path, "manifest.json")
        if os.path.exists(manifest_path):
            with open(manifest_path, 'r') as f:
                manifest = json.load(f)
            
            manifest_result = ModuleValidator.validate_manifest(manifest)
            if not manifest_result.valid:
                for error in manifest_result.errors:
                    result.add_error(error)
            
            compat = ModuleValidator.validate_kernel_compatibility(
                manifest, kernel_version
            )
            for warning in compat.warnings:
                result.add_warning(warning)
        
        return result


def validate_module(module_path: str) -> ValidationResult:
    """Convenience function for module validation"""
    return ModuleValidator.validate_all(module_path)
