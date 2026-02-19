#!/usr/bin/env python3
"""
Agent Modules CLI - Command Line Interface
Runner Ecosystem - Modules Agent

This CLI provides interface to module listing and validation.
"""

import sys
import os
import json
import argparse

# Add src to path for imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

from module_validator import ModuleValidator


def cmd_list(args):
    """List available modules"""
    try:
        modules = []
        
        # Check each agent
        agent_path = os.path.dirname(__file__)
        agents = ["agent-kernel", "agent-modules", "agent-observability", "agent-governance"]
        
        for agent in agents:
            agent_dir = os.path.join(agent_path, "..", agent)
            manifest_path = os.path.join(agent_dir, "manifest.json")
            
            if os.path.exists(manifest_path):
                with open(manifest_path, 'r') as f:
                    manifest = json.load(f)
                    modules.append({
                        "name": manifest.get("name"),
                        "version": manifest.get("version"),
                        "description": manifest.get("description"),
                        "author": manifest.get("author"),
                        "path": agent
                    })
        
        if args.format == "json":
            print(json.dumps(modules, indent=2))
        else:
            print("Available Modules:")
            print("-" * 60)
            for m in modules:
                print(f"  {m['name']:<30} v{m['version']}")
                print(f"    {m['description']}")
                print(f"    Path: {m['path']}")
                print()
        
        return 0
        
    except Exception as e:
        print(json.dumps({
            "success": False,
            "error": str(e)
        }), file=sys.stderr)
        return 1


def cmd_validate(args):
    """Validate a module structure"""
    try:
        module_path = args.path
        
        if not os.path.exists(module_path):
            print(json.dumps({
                "valid": False,
                "error": f"Path does not exist: {module_path}"
            }), file=sys.stderr)
            return 1
        
        # Validate using ModuleValidator
        result = ModuleValidator.validate_all(module_path)
        
        print(json.dumps(result.to_dict(), indent=2))
        return 0 if result.valid else 1
        
    except Exception as e:
        print(json.dumps({
            "valid": False,
            "error": str(e)
        }), file=sys.stderr)
        return 1


def main():
    parser = argparse.ArgumentParser(
        description="Agent Modules CLI - Module listing and validation"
    )
    subparsers = parser.add_subparsers(dest="command", help="Available commands")
    
    # List command
    list_parser = subparsers.add_parser("list", help="List available modules")
    list_parser.add_argument(
        "--format", 
        choices=["text", "json"], 
        default="text",
        help="Output format"
    )
    
    # Validate command
    validate_parser = subparsers.add_parser("validate", help="Validate a module")
    validate_parser.add_argument("--path", required=True, help="Path to module")
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return 1
    
    if args.command == "list":
        return cmd_list(args)
    elif args.command == "validate":
        return cmd_validate(args)
    
    return 0


if __name__ == "__main__":
    sys.exit(main())
