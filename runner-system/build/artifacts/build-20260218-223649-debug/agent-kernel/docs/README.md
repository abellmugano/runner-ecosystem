# Kernel Agent

The Kernel Agent defines the official execution contract for the Runner Ecosystem.

## Responsibilities

- Define official execution contract
- Standardize input/output across all modules
- Uniform error handling
- Permission control
- Module isolation

## Components

### kernel_core.py
Main kernel interface implementing the execution contract:
- `ExecutionResult` - Standardized result format
- `KernelCore` - Main execution engine

### input_validator.py
Input validation ensuring kernel contract compliance:
- Module name validation
- Action name validation
- Parameters validation
- Context validation

### error_handler.py
Uniform error handling:
- Standard error codes
- KernelError hierarchy
- Error logging and history

### permissions.py
Access control system:
- User permissions
- Module permissions
- Whitelist/blacklist
- Permission checking

## Usage

```python
from kernel_core import KernelCore, ExecutionResult
from input_validator import validate_input
from permissions import permissions

# Register a module
class MyModule:
    def run(self, params, context):
        return {"result": "success"}

kernel.register_module("my_module", MyModule)

# Execute
result = kernel.execute("my_module", "run", {"param": "value"})
print(result.to_json())
```

## Testing

```bash
python -m pytest tests/test_kernel.py
```
