# Observability Agent

The Observability Agent provides logging, history tracking, and environment detection.

## Responsibilities

- Complete logging system
- Execution history by module
- Consolidate history and failures
- Detect execution environment

## Components

### logger.py
Logging system:
- `LogEntry` - Single log entry
- `Logger` - Main logger class with levels (DEBUG, INFO, WARNING, ERROR, CRITICAL)

### history.py
Execution history:
- `ExecutionRecord` - Single execution record
- `FailureRecord` - Failure tracking
- `History` - History manager

### environment.py
Environment detection:
- `Environment` - Environment information
- Detects: production, staging, test, development, local

## Usage

### Logging

```python
from logger import logger

logger.info("Processing request", module="my_module")
logger.error("Failed to process", execution_id="exec_123")
```

### History Tracking

```python
from history import history

# Start execution
exec_id = history.start_execution("module", "action", params, context)

# End execution
history.end_execution(exec_id, result, "success", 100.0)

# Get stats
stats = history.get_statistics()
```

### Environment Detection

```python
from environment import environment

env = environment.detect()
if environment.is_production():
    print("Running in production")

info = environment.get_info()
```

## Testing

```bash
python -m pytest tests/test_observability.py
```
