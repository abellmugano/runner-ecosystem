"""
History - Execution history tracking
Tracks and consolidates execution history across modules
"""

from typing import Any, Dict, List, Optional
from datetime import datetime, timedelta
import json
import os


class ExecutionRecord:
    """Single execution record"""
    
    def __init__(
        self,
        execution_id: str,
        module: str,
        action: str,
        params: Dict,
        context: Dict,
        result: Dict,
        status: str,
        duration_ms: float,
        timestamp: Optional[str] = None
    ):
        self.execution_id = execution_id
        self.module = module
        self.action = action
        self.params = params
        self.context = context
        self.result = result
        self.status = status
        self.duration_ms = duration_ms
        self.timestamp = timestamp or datetime.utcnow().isoformat()
    
    def to_dict(self) -> Dict:
        return {
            "execution_id": self.execution_id,
            "module": self.module,
            "action": self.action,
            "params": self.params,
            "context": self.context,
            "result": self.result,
            "status": self.status,
            "duration_ms": self.duration_ms,
            "timestamp": self.timestamp
        }
    
    @classmethod
    def from_dict(cls, data: Dict) -> "ExecutionRecord":
        return cls(
            execution_id=data["execution_id"],
            module=data["module"],
            action=data["action"],
            params=data.get("params", {}),
            context=data.get("context", {}),
            result=data.get("result", {}),
            status=data["status"],
            duration_ms=data["duration_ms"],
            timestamp=data.get("timestamp")
        )


class FailureRecord:
    """Record of execution failures"""
    
    def __init__(
        self,
        execution_id: str,
        module: str,
        action: str,
        error: str,
        stack_trace: Optional[str] = None,
        timestamp: Optional[str] = None
    ):
        self.execution_id = execution_id
        self.module = module
        self.action = action
        self.error = error
        self.stack_trace = stack_trace
        self.timestamp = timestamp or datetime.utcnow().isoformat()
    
    def to_dict(self) -> Dict:
        return {
            "execution_id": self.execution_id,
            "module": self.module,
            "action": self.action,
            "error": self.error,
            "stack_trace": self.stack_trace,
            "timestamp": self.timestamp
        }


class History:
    """Execution history manager"""
    
    def __init__(self):
        self.executions: List[ExecutionRecord] = []
        self.failures: List[FailureRecord] = []
        self._execution_counter = 0
        self._history_file = None
    
    def set_history_file(self, filepath: str):
        """Set history file path"""
        self._history_file = filepath
        os.makedirs(os.path.dirname(filepath), exist_ok=True)
        
        if os.path.exists(filepath):
            self._load_history()
    
    def _load_history(self):
        """Load history from file"""
        try:
            with open(self._history_file, 'r') as f:
                data = json.load(f)
                self.executions = [
                    ExecutionRecord.from_dict(r) for r in data.get("executions", [])
                ]
                self.failures = [FailureRecord(**f) for f in data.get("failures", [])]
        except Exception:
            pass
    
    def _save_history(self):
        """Save history to file"""
        if not self._history_file:
            return
        
        try:
            data = {
                "executions": [r.to_dict() for r in self.executions],
                "failures": [f.to_dict() for f in self.failures]
            }
            with open(self._history_file, 'w') as f:
                json.dump(data, f, indent=2)
        except Exception:
            pass
    
    def start_execution(self, module: str, action: str, params: Dict, context: Dict) -> str:
        """Start tracking an execution"""
        self._execution_counter += 1
        execution_id = f"exec_{self._execution_counter}_{int(datetime.utcnow().timestamp())}"
        
        record = ExecutionRecord(
            execution_id=execution_id,
            module=module,
            action=action,
            params=params,
            context=context,
            result={},
            status="running",
            duration_ms=0
        )
        self.executions.append(record)
        
        return execution_id
    
    def end_execution(
        self,
        execution_id: str,
        result: Dict,
        status: str,
        duration_ms: float
    ):
        """Complete execution tracking"""
        for record in reversed(self.executions):
            if record.execution_id == execution_id:
                record.result = result
                record.status = status
                record.duration_ms = duration_ms
                
                if status == "failed":
                    self._add_failure(record, result.get("error", "Unknown error"))
                
                self._save_history()
                break
    
    def _add_failure(self, record: ExecutionRecord, error: str):
        """Record a failure"""
        failure = FailureRecord(
            execution_id=record.execution_id,
            module=record.module,
            action=record.action,
            error=error
        )
        self.failures.append(failure)
    
    def get_execution(self, execution_id: str) -> Optional[ExecutionRecord]:
        """Get execution by ID"""
        for record in self.executions:
            if record.execution_id == execution_id:
                return record
        return None
    
    def get_module_history(self, module: str, limit: int = 100) -> List[ExecutionRecord]:
        """Get history for a module"""
        module_records = [r for r in self.executions if r.module == module]
        return module_records[-limit:]
    
    def get_recent_executions(self, limit: int = 50) -> List[ExecutionRecord]:
        """Get recent executions"""
        return self.executions[-limit:]
    
    def get_failures(
        self,
        module: Optional[str] = None,
        since: Optional[datetime] = None
    ) -> List[FailureRecord]:
        """Get failure records"""
        failures = self.failures
        
        if module:
            failures = [f for f in failures if f.module == module]
        
        if since:
            failures = [
                f for f in failures
                if datetime.fromisoformat(f.timestamp) >= since
            ]
        
        return failures
    
    def get_statistics(self) -> Dict:
        """Get execution statistics"""
        total = len(self.executions)
        successful = len([r for r in self.executions if r.status == "success"])
        failed = len([r for r in self.executions if r.status == "failed"])
        running = len([r for r in self.executions if r.status == "running"])
        
        avg_duration = 0
        completed = [r for r in self.executions if r.status in ["success", "failed"]]
        if completed:
            avg_duration = sum(r.duration_ms for r in completed) / len(completed)
        
        return {
            "total": total,
            "successful": successful,
            "failed": failed,
            "running": running,
            "success_rate": successful / total if total > 0 else 0,
            "average_duration_ms": avg_duration,
            "total_failures": len(self.failures)
        }
    
    def clear(self):
        """Clear all history"""
        self.executions = []
        self.failures = []
        self._execution_counter = 0


history = History()
