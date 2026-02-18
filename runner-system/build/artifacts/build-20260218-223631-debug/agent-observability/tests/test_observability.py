"""
Tests for Observability Agent
"""

import unittest
import sys
import os
import time
from datetime import datetime, timedelta

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

from logger import Logger, LogEntry, LogLevel
from history import History, ExecutionRecord, FailureRecord
from environment import Environment


class TestLogger(unittest.TestCase):
    """Test logger functionality"""
    
    def setUp(self):
        self.logger = Logger("test")
    
    def test_log_info(self):
        self.logger.info("Test message")
        self.assertEqual(len(self.logger.entries), 1)
        self.assertEqual(self.logger.entries[0].level, LogLevel.INFO)
    
    def test_log_debug(self):
        self.logger.debug("Debug message", module="test_module")
        entry = self.logger.entries[0]
        self.assertEqual(entry.level, LogLevel.DEBUG)
        self.assertEqual(entry.module, "test_module")
    
    def test_log_error(self):
        self.logger.error("Error message", execution_id="exec_1")
        entry = self.logger.entries[0]
        self.assertEqual(entry.level, LogLevel.ERROR)
        self.assertEqual(entry.execution_id, "exec_1")
    
    def test_log_with_metadata(self):
        metadata = {"key": "value"}
        self.logger.info("Message", metadata=metadata)
        entry = self.logger.entries[0]
        self.assertEqual(entry.metadata, metadata)
    
    def test_get_entries_filter_level(self):
        self.logger.info("info")
        self.logger.debug("debug")
        self.logger.error("error")
        
        info_entries = self.logger.get_entries(level=LogLevel.INFO)
        self.assertEqual(len(info_entries), 1)
    
    def test_get_entries_filter_module(self):
        self.logger.info("msg1", module="mod1")
        self.logger.info("msg2", module="mod2")
        
        mod1_entries = self.logger.get_entries(module="mod1")
        self.assertEqual(len(mod1_entries), 1)
    
    def test_get_entries_filter_since(self):
        self.logger.info("msg1")
        time.sleep(0.01)
        self.logger.info("msg2")
        
        since = datetime.utcnow() - timedelta(seconds=0.001)
        recent = self.logger.get_entries(since=since)
        self.assertEqual(len(recent), 1)
    
    def test_count(self):
        self.logger.info("1")
        self.logger.info("2")
        self.logger.debug("3")
        
        self.assertEqual(self.logger.count(), 3)
        self.assertEqual(self.logger.count(LogLevel.INFO), 2)
    
    def test_clear(self):
        self.logger.info("msg")
        self.logger.clear()
        self.assertEqual(len(self.logger.entries), 0)
    
    def test_to_dict(self):
        entry = LogEntry(LogLevel.INFO, "test message", "module1", "exec1", {"key": "val"})
        d = entry.to_dict()
        
        self.assertEqual(d["level"], LogLevel.INFO)
        self.assertEqual(d["message"], "test message")
        self.assertEqual(d["module"], "module1")
        self.assertEqual(d["execution_id"], "exec1")
        self.assertEqual(d["metadata"]["key"], "val")


class TestHistory(unittest.TestCase):
    """Test history functionality"""
    
    def setUp(self):
        self.history = History()
    
    def test_start_execution(self):
        execution_id = self.history.start_execution(
            "test_module", "run", {"param": 1}, {}
        )
        self.assertIsNotNone(execution_id)
        self.assertTrue(execution_id.startswith("exec_"))
    
    def test_end_execution_success(self):
        execution_id = self.history.start_execution(
            "test_module", "run", {}, {}
        )
        
        self.history.end_execution(
            execution_id,
            {"result": "success"},
            "success",
            100.0
        )
        
        record = self.history.get_execution(execution_id)
        self.assertEqual(record.status, "success")
        self.assertEqual(record.duration_ms, 100.0)
    
    def test_end_execution_failure(self):
        execution_id = self.history.start_execution(
            "test_module", "run", {}, {}
        )
        
        self.history.end_execution(
            execution_id,
            {"error": "Failed"},
            "failed",
            50.0
        )
        
        failures = self.history.get_failures()
        self.assertEqual(len(failures), 1)
        self.assertEqual(failures[0].module, "test_module")
    
    def test_get_module_history(self):
        self.history.start_execution("mod1", "run", {}, {})
        self.history.start_execution("mod2", "run", {}, {})
        self.history.start_execution("mod1", "run", {}, {})
        
        mod1_history = self.history.get_module_history("mod1")
        self.assertEqual(len(mod1_history), 2)
    
    def test_get_statistics(self):
        exec_id1 = self.history.start_execution("mod1", "run", {}, {})
        self.history.end_execution(exec_id1, {"result": "ok"}, "success", 10.0)
        
        exec_id2 = self.history.start_execution("mod2", "run", {}, {})
        self.history.end_execution(exec_id2, {"error": "fail"}, "failed", 5.0)
        
        stats = self.history.get_statistics()
        
        self.assertEqual(stats["total"], 2)
        self.assertEqual(stats["successful"], 1)
        self.assertEqual(stats["failed"], 1)
        self.assertEqual(stats["success_rate"], 0.5)
    
    def test_clear(self):
        self.history.start_execution("mod1", "run", {}, {})
        self.history.clear()
        
        self.assertEqual(len(self.history.executions), 0)


class TestExecutionRecord(unittest.TestCase):
    """Test ExecutionRecord"""
    
    def test_to_dict(self):
        record = ExecutionRecord(
            execution_id="exec_1",
            module="test",
            action="run",
            params={"a": 1},
            context={"user": "test"},
            result={"result": "ok"},
            status="success",
            duration_ms=100.0
        )
        
        d = record.to_dict()
        
        self.assertEqual(d["execution_id"], "exec_1")
        self.assertEqual(d["module"], "test")
        self.assertEqual(d["status"], "success")
    
    def test_from_dict(self):
        data = {
            "execution_id": "exec_1",
            "module": "test",
            "action": "run",
            "params": {},
            "context": {},
            "result": {},
            "status": "success",
            "duration_ms": 100.0,
            "timestamp": "2024-01-01T00:00:00"
        }
        
        record = ExecutionRecord.from_dict(data)
        
        self.assertEqual(record.execution_id, "exec_1")
        self.assertEqual(record.timestamp, "2024-01-01T00:00:00")


class TestEnvironment(unittest.TestCase):
    """Test environment detection"""
    
    def setUp(self):
        self.env = Environment()
    
    def test_detect_environment(self):
        env = self.env.detect()
        self.assertIn(env, Environment.DETECTED_ENVIRONMENTS)
    
    def test_set_environment(self):
        self.env.set_environment("production")
        self.assertEqual(self.env.get_environment(), "production")
    
    def test_set_environment_invalid(self):
        with self.assertRaises(ValueError):
            self.env.set_environment("invalid_env")
    
    def test_is_production(self):
        self.env.set_environment("production")
        self.assertTrue(self.env.is_production())
        self.assertFalse(self.env.is_test())
    
    def test_is_test(self):
        self.env.set_environment("test")
        self.assertTrue(self.env.is_test())
        self.assertFalse(self.env.is_production())
    
    def test_get_info(self):
        info = self.env.get_info()
        
        self.assertIn("environment", info)
        self.assertIn("hostname", info)
        self.assertIn("platform", info)
        self.assertIn("start_time", info)
    
    def test_metadata(self):
        self.env.set_metadata("key1", "value1")
        self.assertEqual(self.env.get_metadata("key1"), "value1")
        self.assertEqual(self.env.get_metadata("nonexistent", "default"), "default")
        
        self.env.clear_metadata()
        self.assertEqual(len(self.env.get_all_metadata()), 0)


if __name__ == "__main__":
    unittest.main()
