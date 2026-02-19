# Governance Agent

The Governance Agent manages module registry, status, versions, and permissions.

## Responsibilities

- Maintain official module registry
- Control module status (active, experimental, deprecated, disabled)
- Manage version control
- Permission and whitelist/blacklist control

## Components

### registry.py
Module registry:
- `RegistryEntry` - Single module entry
- `Registry` - Module registry manager
- Status: active, experimental, deprecated, disabled

### status_manager.py
Status transitions:
- `StatusTransition` - Transition record
- `StatusManager` - Status management
- Enforces valid transitions

### version_control.py
Version management:
- `Version` - Semantic version
- `VersionControl` - Version manager
- Supports semver (major.minor.patch)

### permissions.py
Permissions:
- `GovernancePermission` - Permission constants
- `PermissionGrant` - Grant record
- `GovernancePermissions` - Permissions manager

## Usage

### Registry

```python
from registry import registry, ModuleStatus

registry.register("my_module", "1.0.0", manifest, ModuleStatus.ACTIVE)
entry = registry.get("my_module")
print(entry.status)
```

### Status Management

```python
from status_manager import status_manager

status_manager.set_status("module", "active", "Initial activation")
transitions = status_manager.get_transition_history("module")
```

### Version Control

```python
from version_control import version_control

version_control.register_version("module", "1.0.0")
version_control.increment_minor("module")  # "1.1.0"

latest = version_control.get_latest_version("module")
```

### Permissions

```python
from permissions import governance_permissions, GovernancePermission

governance_permissions.grant_permission("user1", GovernancePermission.READ, "admin")
if governance_permissions.has_permission("user1", GovernancePermission.READ):
    print("Access granted")
```

## Testing

```bash
python -m pytest tests/test_governance.py
```
