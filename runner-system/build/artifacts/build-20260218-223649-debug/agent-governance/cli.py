#!/usr/bin/env python3
"""
Agent Governance CLI - Command Line Interface
Runner Ecosystem - Governance Agent

This CLI provides interface to module registry and status management.
"""

import sys
import os
import json
import argparse

# Add src to path for imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

from registry import registry, ModuleStatus
from status_manager import status_manager
from version_control import version_control
from permissions import governance_permissions, GovernancePermission


def cmd_register(args):
    """Register a module in the registry"""
    try:
        name = args.name
        version = args.version
        status = args.status or "active"
        
        manifest = {
            "name": name,
            "version": version,
            "description": f"Module {name}",
            "author": "System"
        }
        
        result = registry.register(name, version, manifest, status)
        
        if result:
            print(json.dumps({
                "success": True,
                "registered": True,
                "name": name,
                "version": version,
                "status": status
            }))
            return 0
        else:
            print(json.dumps({
                "success": False,
                "error": f"Module already registered: {name}"
            }), file=sys.stderr)
            return 1
            
    except Exception as e:
        print(json.dumps({
            "success": False,
            "error": str(e)
        }), file=sys.stderr)
        return 1


def cmd_get(args):
    """Get module information"""
    try:
        name = args.name
        
        entry = registry.get(name)
        
        if entry:
            print(json.dumps(entry.to_dict(), indent=2))
            return 0
        else:
            print(json.dumps({
                "success": False,
                "error": f"Module not found: {name}"
            }), file=sys.stderr)
            return 1
            
    except Exception as e:
        print(json.dumps({
            "success": False,
            "error": str(e)
        }), file=sys.stderr)
        return 1


def cmd_list_modules(args):
    """List modules"""
    try:
        status_filter = args.status
        
        if status_filter:
            modules = registry.get_by_status(status_filter)
        else:
            modules = registry.list_all()
        
        result = [m.to_dict() for m in modules]
        
        print(json.dumps(result, indent=2))
        return 0
        
    except Exception as e:
        print(json.dumps({
            "success": False,
            "error": str(e)
        }), file=sys.stderr)
        return 1


def cmd_set_status(args):
    """Set module status"""
    try:
        name = args.name
        status = args.status
        
        # Validate status
        valid_statuses = ["active", "experimental", "deprecated", "disabled"]
        if status not in valid_statuses:
            print(json.dumps({
                "success": False,
                "error": f"Invalid status: {status}"
            }), file=sys.stderr)
            return 1
        
        # Set status via status_manager
        result = status_manager.set_status(name, status, "CLI update")
        
        # Also update registry
        registry.update_status(name, status)
        
        print(json.dumps({
            "success": True,
            "name": name,
            "status": status
        }))
        return 0
        
    except Exception as e:
        print(json.dumps({
            "success": False,
            "error": str(e)
        }), file=sys.stderr)
        return 1


def main():
    parser = argparse.ArgumentParser(
        description="Agent Governance CLI - Registry and status management"
    )
    subparsers = parser.add_subparsers(dest="command", help="Available commands")
    
    # Register command
    register_parser = subparsers.add_parser("register", help="Register a module")
    register_parser.add_argument("--name", required=True, help="Module name")
    register_parser.add_argument("--version", required=True, help="Module version")
    register_parser.add_argument("--status", help="Module status")
    
    # Get command
    get_parser = subparsers.add_parser("get", help="Get module info")
    get_parser.add_argument("--name", required=True, help="Module name")
    
    # List command
    list_parser = subparsers.add_parser("list", help="List modules")
    list_parser.add_argument("--status", help="Filter by status")
    
    # Set-status command
    setstatus_parser = subparsers.add_parser("set-status", help="Set module status")
    setstatus_parser.add_argument("--name", required=True, help="Module name")
    setstatus_parser.add_argument("--status", required=True, help="New status")
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return 1
    
    if args.command == "register":
        return cmd_register(args)
    elif args.command == "get":
        return cmd_get(args)
    elif args.command == "list":
        return cmd_list_modules(args)
    elif args.command == "set-status":
        return cmd_set_status(args)
    
    return 0


if __name__ == "__main__":
    sys.exit(main())
