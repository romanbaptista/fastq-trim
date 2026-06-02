# `functions`

# Overview
The `functions/` directory contains all reusable, atomic logic used throughout the `fastq-trim` pipeline.

These scripts provide:
- validation primitives
- filesystem checks and operations
- tool-specific helper functions
- shared utility operations

They represent the execution logic layer, but are strictly limited to stateless, reusable operations.

# Design Principles

| Principle | Description |
|----------|------------|
| Atomicity | Each function performs a single, well-defined task |
| No orchestration | Control flow handled externally in scripts |
| Validation-first | Inputs validated before execution |
| Return-based | Failures propagate via return codes |

These principles ensure that:
- logic is modular and reusable
- failure handling is consistent and predictable
- orchestration remains external to function definitions

# File Overview
The `functions/` directory is structured into:
- a shared base layer (`functions_base.sh`)
- tool-specific helper layers (`functions_<tool>.sh`)

Each file has a clearly defined responsibility.

| File | Responsibility |
|------|----------------|
| `functions_base.sh` | Core validation, filesystem operations, and error handling |
| `functions_bbtools.sh` | BBTools validation and installation helpers |
| `functions_trimmomatic.sh` | Trimmomatic validation and installation helpers |

## `functions_base.sh`
This file defines all core helper functions used across the entire pipeline.

It includes:
- argument validation (`arg_check_nonempty`)
- variable validation (`variable_check_nonempty`)
- array validation (`array_check_nonempty`)
- file and directory validation helpers
- filesystem operations (`directory_create`, etc.)
- binary checks (`tool_check_binary`)
- runtime checks (`tool_check_runtime`)
- generic error handling (`fail_message`)

This file forms the foundation of the contract-driven validation system.

All scripts that require:
- validation
- filesystem operations
- structured error handling

must explicitly source this file.

## `functions_bbtools.sh`
Provides atomic helper functions for validating and installing BBTools.

### Responsibilities
- checking BBTools installation (`check_bbtools`)
- downloading archive (`download_bbtools`)
- extracting and normalising installation directory (`extract_bbtools`)

### Key characteristics
- deterministic installation behaviour
- idempotent directory handling
- strict argument validation
- no orchestration logic

These functions are consumed by `preflight_bbtools.sh`

## `functions_trimmomatic.sh`
Provides atomic helper functions for validating and installing Trimmomatic.

### Responsibilities
- checking Trimmomatic installation (`check_trimmomatic`)
- downloading archive (`download_trimmomatic`)
- extracting and normalising installation directory (`extract_trimmomatic`)

### Key characteristics
- deterministic installation logic
- safe directory overwrite handling
- strict validation via shared helpers
- no orchestration logic

These functions are consumed by `preflight_trimmomatic.sh`

# Execution Pattern
Functions follow a strict internal structure:

```bash
my_function() {
    local arg="${1-}"

    # VALIDATION
    arg_check_nonempty "${arg}" || return $?

    # FUNCTION
    perform_operation "${arg}" || return 1
}
```

This pattern guarantees:
- predictable behaviour
- clear error propagation
- composability across scripts

# Usage in Pipeline
Functions are used across:
- preflight scripts → validation, tool installation, environment construction
- pipeline scripts → selected helper operations
- module scripts → filesystem operations and error handling

Scripts explicitly source required functions:

```bash
source "${FUNCTIONS_DIR}/functions_base.sh"
source "${FUNCTIONS_DIR}/functions_bbtools.sh"
source "${FUNCTIONS_DIR}/functions_trimmomatic.sh"
```

No implicit availability is assumed.

# Execution Boundary Model
The pipeline enforces strict behaviour across execution contexts:
- Same-shell (preflight layer) → functions assumed available from orchestrator
- SLURM job (`pipeline.sh`) → functions must be re-sourced
- SLURM job (modules) → functions must be re-sourced
- No function state is inherited across boundaries

This ensures:
- deterministic behaviour
- no hidden dependencies
- reproducibility across execution environments

# Error Handling
Functions:
- return non-zero exit codes on failure
- do not terminate execution directly

Scripts handle failure using:

```bash
function_call || fail_message "error description"
```

This ensures:
- centralised failure handling
- consistent error messaging
- separation between logic and control flow

# Variable and Validation Model
Functions implement a layered validation system:
- `arg_check_nonempty` → validates function arguments
- `variable_check_nonempty` → validates named pipeline variables
- `array_check_nonempty` → validates arrays

Each function:
- validates only its own inputs
- does not assume upstream guarantees unless enforced

This allows validation to remain:
- composable
- explicit
- layered across the pipeline

# Key Rules
- Do not include orchestration logic in functions
- Do not use exit inside functions
- Always validate inputs before execution
- Keep functions minimal and focused
- Avoid hidden dependencies or global state
- Ensure functions are reusable across pipeline contexts

# Summary
The `functions/` directory provides the core logic building blocks of the `fastq-trim` pipeline.

It enables:
- consistent validation and error handling
- strict separation between logic and orchestration
- modular, reusable components

All higher-level behaviour in the pipeline is constructed from these atomic functions, ensuring:
- clarity of responsibility
- reproducibility
- maintainability