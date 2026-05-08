# `utils`

This directory contains shared utility functions used by the trim pipeline.

The scripts in utils/ provide reusable, strictly validated helper functions that support:
- Preflight validation
- Tool installation and verification
- Defensive error handling
- Deterministic pipeline behavior under strict Bash execution

Utility scripts are sourced by `run_pipeline.sh`, preflight scripts, and pipeline modules as required.

# Design Contract
All utility scripts adhere to the following principles:
- Pure helper logic only (no pipeline orchestration)
- Safe operation under set -euo pipefail
- Explicit, readable control flow
- Clear and actionable error messages
- No reliance on implicit environment state
- No modification of global system settings
- Portable across HPC environments

Utility functions are stateless and rely entirely on arguments and inherited environment variables.

# Utility Script Overview
```text
functions_base.sh
functions_bbtools.sh
functions_trimmomatic.sh
```
Each utility script serves a narrow, well‑defined purpose and is designed to be reused across multiple pipeline stages.

## `functions_base.sh`
Provides core validation and helper functions used throughout the pipeline.

### Responsibilities
- Validates files, directories, variables, and commands
- Enforces non‑empty configuration values
- Provides consistent error handling and messaging
- Guards against common Bash failure modes

### Key Functions

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
Provides BBTools‑specific helpers for verification and installation.

### Responsibilities
- Detects whether BBTools is installed and usable
- Downloads and installs BBTools if missing
- Verifies the presence, executability, and integrity of bbduk.sh
- Supports deterministic tool setup during preflight

### Key Functions

| Function | Purpose |
|---------|---------|
| `check_bbtools` | Verifies BBTools directory structure and BBDUK executable |
| `download_bbtools` | Downloads and extracts a pinned BBTools release into the pipeline directory |
| `ensure_bbtools` | Calls `check_bbtools` and installs BBTools if required |

All BBTools installation and verification is performed only during preflight, never during compute jobs.

## `functions_trimmomatic.sh`
Provides Trimmomatic‑specific helpers for verification and installation.

### Responsibilities
- Detects whether Trimmomatic is installed and usable
- Downloads and installs Trimmomatic if missing
- Verifies presence and integrity of the Trimmomatic JAR
- Confirms availability of a Java runtime

### Key Functions

| Function | Purpose |
|---------|---------|
| `check_trimmomatic` | Verifies Trimmomatic directory, JAR file, and Java command |
| `download_trimmomatic` | Downloads and extracts a pinned Trimmomatic release into the pipeline directory |
| `ensure_trimmomatic` | Calls `check_trimmomatic` and installs Trimmomatic if required |

As with BBTools, all Trimmomatic setup occurs exclusively during preflight.

# Usage
Utility scripts are not intended to be executed directly, they are sourced where required.

`functions_base.sh` is sourced by:
- `run_pipeline.sh`
- All preflight scripts
- All pipeline modules that require helper functions

`functions_bbtools.sh` and `functions_trimmomatic.sh` are sourced only when relevant to the selected trimming tool.

# Error Handling
All utility functions are designed to:
- Fail immediately on invalid input
- Emit concise, context‑aware error messages
- Prevent execution from progressing in an unsafe state

This ensures that pipeline failures occur as early and close to the source of the problem as possible.

# Notes
- Utility functions intentionally duplicate no validation logic found elsewhere
- All path resolution is delegated to pipeline‑level variables
- Functions make no assumptions about SLURM execution context
- Tool installation is deterministic and repeat‑safe
- Adding new tools or modules should include corresponding utility helpers where appropriate