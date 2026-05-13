# `utils`
This directory contains shared utility functions used by the `fastq-trim` pipeline.

The scripts in `utils/` provide reusable, strictly validated helper functions that support:
- Preflight validation
- Tool installation and verification
- Defensive error handling
- Deterministic pipeline behavior under strict Bash execution
- Canonical definition of pipeline structure and execution ABI

Utility scripts are sourced by `run_pipeline.sh`, preflight scripts, and (where required) execution modules.

# Design Contract
All utility scripts adhere to the following principles:
- Pure helper logic only (no pipeline orchestration)
- Safe operation under `set -euo pipefail`
- Explicit, readable control flow
- Clear and actionable error messages
- No reliance on implicit environment state
- No modification of global system settings
- Portable across HPC environments
- Canonical definition of pipeline structure via arrays

Utility functions are stateless and rely entirely on arguments and inherited environment variables.

# Utility Script Overview
```text
arrays.sh
functions_base.sh
functions_bbtools.sh
functions_trimmomatic.sh
```

Each utility script serves a narrow, well‑defined purpose and is designed to be reused across multiple pipeline stages.

## `arrays.sh`
Defines the canonical structure and execution contract of the pipeline.

### Responsibilities
Defines ordered lists of:
- Preflight scripts (`PREFLIGHT_ARRAY`)
- Execution modules (`SCRIPT_ARRAY`)
- Defines the execution ABI (`EXPORT_ARRAY`)
- Defines required commands (`COMMAND_ARRAY`)
- Defines required configuration variables (`VARIABLE_ARRAY`)

### Guarantees
- Provides a single source of truth for pipeline structure
- Ensures consistent validation and execution ordering
- Defines the complete set of pipeline-owned variables propagated across SLURM boundaries

### Design Note
- `EXPORT_ARRAY` defines the pipeline execution ABI and must not be modified downstream.
- `SBATCH_EXPORTS` is derived from this array and passed across process boundaries.

## `functions_base.sh`
Provides core validation and helper functions used throughout the pipeline.

### Responsibilities
- Validates files, directories, variables, and commands
- Enforces non-empty configuration values
- Provides consistent error handling and messaging
- Guards against common Bash failure modes

### Functions

| Function | Purpose |
|---------|---------|
| `check_file` | Confirms that a regular file exists |
| `check_file_data` | Confirms that a file exists and is non-empty |
| `check_directory` | Confirms that a directory exists |
| `check_variable` | Confirms that a variable is set and non-empty |
| `check_command` | Confirms that a command is available in `PATH` |
| `check_executable` | Confirms that a file exists and is executable |
| `check_arg` | Confirms that required function arguments are provided |
| `fail` | Prints an error message and exits immediately |

These functions are used extensively by preflight scripts to enforce pipeline invariants before SLURM job submission.

## `functions_bbtools.sh`
Provides bbtools‑specific helpers for verification and installation.

### Responsibilities
- Detects whether bbtools is installed and usable
- Downloads and installs bbtools if missing
- Verifies the presence, executability, and integrity of `bbduk.sh`
- Verifies adapter FASTA presence and validity
- Supports deterministic tool setup during preflight

### Functions

| Function | Purpose |
|---------|---------|
| `check_bbtools` | Verifies bbtools installation, BBDUK executable, and adapter file |
| `download_bbtools` | Downloads a pinned bbtools release archive |
| `extract_bbtools` | Extracts and normalises bbtools installation |
| `install_bbtools` | Installs and verifies bbtools if not already present |

All bbtools installation and verification is performed only during preflight, never during compute jobs.

## `functions_trimmomatic.sh`
Provides trimmomatic‑specific helpers for verification and installation.

### Responsibilities
- Detects whether trimmomatic is installed and usable
- Downloads and installs trimmomatic if missing
- Verifies presence and integrity of the trimmomatic JAR
- Confirms availability of a Java runtime
- Supports deterministic tool setup during preflight

### Functions
| Function | Purpose |
|---------|---------|
| `check_trimmomatic` | Verifies trimmomatic directory, JAR file, and Java availability |
| `download_trimmomatic` | Downloads a pinned trimmomatic release archive |
| `extract_trimmomatic` | Extracts and normalises trimmomatic installation |
| `install_trimmomatic` | Installs and verifies trimmomatic if not already present |

As with bbtools, all trimmomatic setup occurs exclusively during preflight.

# Usage
Utility scripts are not intended to be executed directly; they are sourced where required.

`arrays.sh` is sourced by:
- `run_pipeline.sh`
- preflight scripts

`functions_base.sh` is sourced by:
- `run_pipeline.sh`
- all preflight scripts

`functions_bbtools.sh` and `functions_trimmomatic.sh` are sourced only within tool-specific preflight scripts.

Execution modules do not rely on utility functions and instead consume only the execution ABI.

# Error Handling
All utility functions are designed to:
- Fail immediately on invalid input
- Emit concise, context-aware error messages
- Prevent execution from progressing in an unsafe state

This ensures that failures occur early, at the validation stage, rather than during compute jobs.

# Notes
- Utility functions intentionally duplicate no validation logic found elsewhere
- All path resolution is handled at the pipeline layer (`run_pipeline.sh`)
- Functions make no assumptions about SLURM execution context
- Tool installation is deterministic and restart-safe
- Arrays define the canonical pipeline structure and must remain immutable
- Adding new tools requires corresponding utility helpers and preflight integration