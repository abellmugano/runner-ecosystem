"""
Tests for Governance Agent
"""

import unittest
import sys
import os
from datetime import datetime, timedelta

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

from registry import Registry, RegistryEntry, ModuleStatus
from status_manager import StatusManager, StatusTransition
from version_control import VersionControl, Version
from permissions import GovernancePermissions, GovernancePermission, PermissionGrant


class TestRegistry(unittest.TestCase):
    """Test registry functionality"""
    
    def setUp(self):
        self.registry = Registry()
    
    def test_register_module(self):
        manifest = {"name": "test_module", "version": "1.0.0"}
        result = self.registry.register("test_module", "1.0.0", manifest)
        
        self.assertTrue(result)
        self.assertTrue(self.registry.exists("test_module"))
    
    def test_register_duplicate(self):
        manifest = {"name": "test_module", "version": "1.0.0"}
        self.registry.register("test_module", "1.0.0", manifest)
        
        result = self.registry.register("test_module", "1.0.0", manifest)
        self.assertFalse(result)
    
    def test_unregister(self):
        self.registry.register("test", "1.0.0", {})
        
        result = self.registry.unregister("test")
        self.assertTrue(result)
        self.assertFalse(self.registry.exists("test"))
    
    def test_update_status(self):
        self.registry.register("test", "1.0.0", {}, ModuleStatus.EXPERIMENTAL)
        
        result = self.registry.update_status("test", ModuleStatus.ACTIVE)
        self.assertTrue(result)
        
        entry = self.registry.get("test")
        self.assertEqual(entry.status, ModuleStatus.ACTIVE)
    
    def test_get_by_status(self):
        self.registry.register("mod1", "1.0.0", {}, ModuleStatus.ACTIVE)
        self.registry.register("mod2", "1.0.0", {}, ModuleStatus.ACTIVE)
        self.registry.register("mod3", "1.0.0", {}, ModuleStatus.DEPRECATED)
        
        active = self.registry.get_by_status(ModuleStatus.ACTIVE)
        self.assertEqual(len(active), 2)
    
    def test_is_active(self):
        self.registry.register("active_mod", "1.0.0", {}, ModuleStatus.ACTIVE)
        self.registry.register("inactive_mod", "1.0.0", {}, ModuleStatus.DISABLED)
        
        self.assertTrue(self.registry.is_active("active_mod"))
        self.assertFalse(self.registry.is_active("inactive_mod"))
    
    def test_registry_entry(self):
        entry = RegistryEntry("test", "1.0.0", ModuleStatus.ACTIVE, {"key": "value"})
        
        self.assertEqual(entry.name, "test")
        self.assertEqual(entry.version, "1.0.0")
        
        entry.update_version("2.0.0")
        self.assertEqual(entry.version, "2.0.0")


class TestStatusManager(unittest.TestCase):
    """Test status manager"""
    
    def setUp(self):
        self.manager = StatusManager()
    
    def test_set_status(self):
        result = self.manager.set_status("test_module", "active", "Initial activation")
        self.assertTrue(result)
        self.assertEqual(self.manager.get_status("test_module"), "active")
    
    def test_invalid_status(self):
        result = self.manager.set_status("test", "invalid_status", "")
        self.assertFalse(result)
    
    def test_disallowed_transition(self):
        self.manager.set_status("test", "active", "")
        
        result = self.manager.set_status("test", "experimental", "")
        self.assertFalse(result)
    
    def test_allowed_transition(self):
        self.manager.set_status("test", "experimental", "")
        
        result = self.manager.set_status("test", "active", "")
        self.assertTrue(result)
    
    def test_get_modules_by_status(self):
        self.manager.set_status("mod1", "active", "")
        self.manager.set_status("mod2", "active", "")
        self.manager.set_status("mod3", "deprecated", "")
        
        active = self.manager.get_modules_by_status("active")
        self.assertEqual(len(active), 2)
    
    def test_transition_history(self):
        self.manager.set_status("test", "active", "First")
        self.manager.set_status("test", "deprecated", "Second")
        
        history = self.manager.get_transition_history("test")
        self.assertEqual(len(history), 2)
    
    def test_can_transition(self):
        self.assertTrue(self.manager.can_transition("experimental", "active"))
        self.assertFalse(self.manager.can_transition("active", "experimental"))
    
    def test_get_allowed_transitions(self):
        allowed = self.manager.get_allowed_transitions("experimental")
        self.assertIn("active", allowed)
        self.assertIn("disabled", allowed)


class TestVersionControl(unittest.TestCase):
    """Test version control"""
    
    def setUp(self):
        self.vc = VersionControl()
    
    def test_register_version(self):
        result = self.vc.register_version("test_module", "1.0.0")
        self.assertTrue(result)
    
    def test_register_duplicate_version(self):
        self.vc.register_version("test", "1.0.0")
        
        result = self.vc.register_version("test", "1.0.0")
        self.assertFalse(result)
    
    def test_invalid_version(self):
        result = self.vc.register_version("test", "invalid")
        self.assertFalse(result)
    
    def test_get_versions(self):
        self.vc.register_version("test", "1.0.0")
        self.vc.register_version("test", "1.0.1")
        self.vc.register_version("test", "2.0.0")
        
        versions = self.vc.get_versions("test")
        self.assertEqual(len(versions), 3)
    
    def test_get_current_version(self):
        self.vc.register_version("test", "1.0.0")
        self.vc.register_version("test", "1.0.1")
        
        current = self.vc.get_current_version("test")
        self.assertEqual(current, "1.0.1")
    
    def test_get_latest_version(self):
        self.vc.register_version("test", "1.0.0")
        self.vc.register_version("test", "2.0.0")
        self.vc.register_version("test", "1.5.0")
        
        latest = self.vc.get_latest_version("test")
        self.assertEqual(latest, "2.0.0")
    
    def test_increment_major(self):
        self.vc.register_version("test", "1.0.0")
        
        new_version = self.vc.increment_major("test")
        self.assertEqual(new_version, "2.0.0")
    
    def test_increment_minor(self):
        self.vc.register_version("test", "1.0.0")
        
        new_version = self.vc.increment_minor("test")
        self.assertEqual(new_version, "1.1.0")
    
    def test_increment_patch(self):
        self.vc.register_version("test", "1.0.0")
        
        new_version = self.vc.increment_patch("test")
        self.assertEqual(new_version, "1.0.1")
    
    def test_compare_versions(self):
        self.assertEqual(self.vc.compare_versions("1.0.0", "1.0.0"), 0)
        self.assertEqual(self.vc.compare_versions("1.0.0", "2.0.0"), -1)
        self.assertEqual(self.vc.compare_versions("2.0.0", "1.0.0"), 1)
    
    def test_is_compatible(self):
        self.assertTrue(self.vc.is_compatible("1.0.0", "1.5.0"))
        self.assertFalse(self.vc.is_compatible("2.0.0", "1.5.0"))


class TestVersion(unittest.TestCase):
    """Test Version class"""
    
    def test_parse_valid(self):
        v = Version("1.2.3")
        self.assertEqual(v.major, 1)
        self.assertEqual(v.minor, 2)
        self.assertEqual(v.patch, 3)
    
    def test_parse_invalid(self):
        with self.assertRaises(ValueError):
            Version("invalid")
    
    def test_comparison(self):
        v1 = Version("1.0.0")
        v2 = Version("2.0.0")
        
        self.assertTrue(v1 < v2)
        self.assertTrue(v2 > v1)
        self.assertTrue(v1 == Version("1.0.0"))


class TestGovernancePermissions(unittest.TestCase):
    """Test governance permissions"""
    
    def setUp(self):
        self.perms = GovernancePermissions()
    
    def test_grant_permission(self):
        result = self.perms.grant_permission(
            "user1",
            GovernancePermission.READ,
            "admin"
        )
        self.assertTrue(result)
    
    def test_has_permission(self):
        self.perms.grant_permission("user1", GovernancePermission.READ, "admin")
        
        self.assertTrue(self.perms.has_permission("user1", GovernancePermission.READ))
        self.assertFalse(self.perms.has_permission("user1", GovernancePermission.WRITE))
    
    def test_admin_has_all(self):
        self.perms.grant_permission("admin_user", GovernancePermission.ADMIN, "system")
        
        self.assertTrue(self.perms.has_permission("admin_user", GovernancePermission.READ))
        self.assertTrue(self.perms.has_permission("admin_user", GovernancePermission.WRITE))
    
    def test_whitelist(self):
        self.perms.add_to_whitelist("user1", [GovernancePermission.READ])
        
        self.assertTrue(self.perms.has_permission("user1", GovernancePermission.READ))
    
    def test_blacklist(self):
        self.perms.grant_permission("user1", GovernancePermission.READ, "admin")
        self.perms.add_to_blacklist("user1", [GovernancePermission.READ])
        
        self.assertFalse(self.perms.has_permission("user1", GovernancePermission.READ))
    
    def test_revoke_permission(self):
        self.perms.grant_permission("user1", GovernancePermission.READ, "admin")
        self.perms.revoke_permission("user1", GovernancePermission.READ)
        
        self.assertFalse(self.perms.has_permission("user1", GovernancePermission.READ))
    
    def test_check_permission(self):
        self.perms.grant_permission("user1", GovernancePermission.READ, "admin")
        
        result = self.perms.check_permission("user1", GovernancePermission.READ)
        self.assertTrue(result)
        
        with self.assertRaises(PermissionError):
            self.perms.check_permission("user1", GovernancePermission.WRITE)


if __name__ == "__main__":
    unittest.main()
