#!/usr/bin/env python3
"""
Agent Kernel CLI - Command Line Interface
Runner Ecosystem - Kernel Agent

This CLI provides interface to the Kernel agent functionality.
"""

import sys
import os
import json
import argparse

# Add src to path for imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

from kernel_core import KernelCore, ExecutionResult
from input_validator import validate_input, ValidationError
from error_handler import error_handler
from permissions import permissions


def cmd_execute(args):
    """Execute a module via Kernel"""
    try:
        # Parse inputs
        module_name = args.module
        
        input_data = {}
        if args.input:
            input_data = json.loads(args.input)
        
        user_context = {}
        if args.user:
            user_context = json.loads(args.user)
        
        # Validate input
        request = {
            "module": module_name,
            "action": input_data.get("action", "run"),
            "params": input_data.get("params", {}),
            "context": user_context
        }
        
        validate_input(request)
        
        # Check permissions
        if user_context.get("user"):
            permission = f"{module_name}:execute"
            if not permissions.has_permission(user_context["user"], permission):
                print(json.dumps({
                    "success": False,
                    "error": f"Permission denied: {permission}"
                }), file=sys.stderr)
                return 1
        
        # Load and execute module
        kernel = KernelCore()
        
        # Import the module dynamically
        module_path = os.path.join(os.path.dirname(__file__), 'src')
        
        # Try to load from agent-modules as example
        try:
            sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'agent-modules', 'src'))
            from example_module import ExampleModule
            kernel.register_module("example_module", ExampleModule)
        except Exception:
            pass
        
        # Execute
        result = kernel.execute(
            module_name,
            input_data.get("action", "run"),
            input_data.get("params", {}),
            user_context
        )
        
        # Output result
        print(json.dumps(result.to_dict(), indent=2))
        return 0 if result.success else 1
        
    except ValidationError as e:
        print(json.dumps({
            "success": False,
            "error": f"Validation error: {str(e)}"
        }), file=sys.stderr)
        return 1
    except Exception as e:
        print(json.dumps({
            "success": False,
            "error": f"Execution error: {str(e)}"
        }), file=sys.stderr)
        return 1


def cmd_validate_module(args):
    """Validate a module structure"""
    try:
        module_path = args.module_path
        
        if not os.path.exists(module_path):
            print(json.dumps({
                "valid": False,
                "error": f"Module path does not exist: {module_path}"
            }), file=sys.stderr)
            return 1
        
        manifest_path = os.path.join(module_path, "manifest.json")
        
        if not os.path.exists(manifest_path):
            print(json.dumps({
                "valid": False,
                "error": "manifest.json not found"
            }), file=sys.stderr)
            return 1
        
        # Load and validate manifest
        with open(manifest_path, 'r') as f:
            manifest = json.load(f)
        
        required_fields = ["name", "version", "description", "author"]
        missing = [f for f in required_fields if f not in manifest]
        
        if missing:
            print(json.dumps({
                "valid": False,
                "error": f"Missing required fields: {missing}"
            }), file=sys.stderr)
            return 1
        
        print(json.dumps({
            "valid": True,
            "manifest": manifest
        }, indent=2))
        return 0
        
    except Exception as e:
        print(json.dumps({
            "valid": False,
            "error": str(e)
        }), file=sys.stderr)
        return 1


def main():
    parser = argparse.ArgumentParser(
        description="Agent Kernel CLI - Kernel execution and validation"
    )
    subparsers = parser.add_subparsers(dest="command", help="Available commands")
    
    # Execute command
    execute_parser = subparsers.add_parser("execute", help="Execute a module")
    execute_parser.add_argument("--module", required=True, help="Module name to execute")
    execute_parser.add_argument("--input", help="JSON input data")
    execute_parser.add_argument("--user", help="JSON user context")
    
    # Validate-module command
    validate_parser = subparsers.add_parser("validate-module", help="Validate a module")
    validate_parser.add_argument("--module-path", required=True, help="Path to module")
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return 1
    
    if args.command == "execute":
        return cmd_execute(args)
    elif args.command == "validate-module":
        return cmd_validate_module(args)
    
    return 0


if __name__ == "__main__":
    sys.exit(main())
