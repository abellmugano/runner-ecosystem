# Module System Agent

The Module System Agent creates and validates module standards for the Runner Ecosystem.

## Responsibilities

- Create mandatory module pattern
- Define minimum structure and manifest
- Standardize return values
- Validate kernel compatibility
- Provide example modules

## Components

### module_template.py
Base template for all modules:
- `ModuleManifest` - Manifest structure
- `BaseModule` - Abstract base class
- `ModuleTemplate` - Template implementation

### module_validator.py
Module validation:
- Manifest validation
- Module class validation
- Kernel compatibility checks
- File structure validation

### example_module.py
Official example modules:
- `ExampleModule` - Basic example
- `CalculatorModule` - Calculator example

## Usage

### Creating a Module

```python
from module_template import BaseModule

class MyModule(BaseModule):
    def get_manifest(self):
        return {
            "name": "my_module",
            "version": "1.0.0",
            "description": "My module",
            "author": "Author Name",
            "actions": ["run"]
        }
    
    def initialize(self, config):
        self._config = config
        return True
    
    def execute(self, action, params, context):
        if action == "run":
            return {"result": "success"}
        return {"error": "Unknown action"}
```

### Validating a Module

```python
from module_validator import validate_module

result = validate_module("/path/to/module")
if result.valid:
    print("Module is valid")
else:
    print("Errors:", result.errors)
```

## Manifest Format

```json
{
  "name": "module_name",
  "version": "1.0.0",
  "description": "Module description",
  "author": "Author Name",
  "dependencies": [],
  "actions": ["action1", "action2"],
  "kernel_version": "1.0.0"
}
```

## Testing

```bash
python -m pytest tests/test_modules.py
```
