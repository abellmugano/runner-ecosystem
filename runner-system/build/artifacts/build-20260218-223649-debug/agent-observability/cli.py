#!/usr/bin/env python3
"""
Agent Observability CLI - Command Line Interface
Runner Ecosystem - Observability Agent

This CLI provides interface to logging, history, and environment info.
"""

import sys
import os
import json
import argparse
from datetime import datetime

# Add src to path for imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

from logger import logger, LogLevel
from history import history
from environment import environment


def cmd_log(args):
    """Log a message"""
    try:
        level = args.level.upper()
        
        # Validate level
        valid_levels = ["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"]
        if level not in valid_levels:
            print(json.dumps({
                "success": False,
                "error": f"Invalid level: {level}"
            }), file=sys.stderr)
            return 1
        
        # Get logging function
        log_func = getattr(logger, level.lower(), logger.info)
        
        # Log message
        log_func(
            args.message,
            module=args.module,
            execution_id=args.execution_id
        )
        
        print(json.dumps({
            "success": True,
            "logged": True,
            "level": level,
            "message": args.message,
            "timestamp": datetime.utcnow().isoformat()
        }))
        return 0
        
    except Exception as e:
        print(json.dumps({
            "success": False,
            "error": str(e)
        }), file=sys.stderr)
        return 1


def cmd_history(args):
    """Get execution history"""
    try:
        module = args.module
        limit = args.limit or 50
        
        if module:
            records = history.get_module_history(module, limit)
        else:
            records = history.get_recent_executions(limit)
        
        # Convert to dict
        result = [r.to_dict() for r in records]
        
        print(json.dumps(result, indent=2))
        return 0
        
    except Exception as e:
        print(json.dumps({
            "success": False,
            "error": str(e)
        }), file=sys.stderr)
        return 1


def cmd_env(args):
    """Get environment information"""
    try:
        env_info = environment.get_info()
        
        print(json.dumps(env_info, indent=2))
        return 0
        
    except Exception as e:
        print(json.dumps({
            "success": False,
            "error": str(e)
        }), file=sys.stderr)
        return 1


def main():
    parser = argparse.ArgumentParser(
        description="Agent Observability CLI - Logging, history, and environment"
    )
    subparsers = parser.add_subparsers(dest="command", help="Available commands")
    
    # Log command
    log_parser = subparsers.add_parser("log", help="Log a message")
    log_parser.add_argument("--level", required=True, choices=["debug", "info", "warning", "error", "critical"],
                           help="Log level")
    log_parser.add_argument("--message", required=True, help="Log message")
    log_parser.add_argument("--module", help="Module name")
    log_parser.add_argument("--execution-id", help="Execution ID")
    
    # History command
    history_parser = subparsers.add_parser("history", help="Get execution history")
    history_parser.add_argument("--module", help="Filter by module name")
    history_parser.add_argument("--limit", type=int, default=50, help="Limit results")
    
    # Env command
    env_parser = subparsers.add_parser("env", help="Get environment information")
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return 1
    
    if args.command == "log":
        return cmd_log(args)
    elif args.command == "history":
        return cmd_history(args)
    elif args.command == "env":
        return cmd_env(args)
    
    return 0


if __name__ == "__main__":
    sys.exit(main())
