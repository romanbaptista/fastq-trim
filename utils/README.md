# `utils`

# Overview
The `utils/` directory contains all static variable definitions used throughout the `fastq-trim` pipeline.

These scripts define:
- directory paths
- tool installation parameters
- tool-specific configuration variables

Importantly, `utils/` is a pure definition layer — it contains no logic, validation, or execution.

# Design Principles
The `utils/` layer follows strict design rules:
- Definitions only — no functions or control flow
- No validation — all checks occur in the preflight layer
- No side effects — sourcing only sets variables
- Centralised variable ownership — each variable is defined exactly once
- Deterministic behaviour — no runtime decisions or dynamic modification

These principles ensure clean separation between:
- what is defined (`utils/`)
- what is validated (`preflight/`)
- what is executed (`pipeline/` and modules)

# Role in the Pipeline
The `utils/` layer acts as the source of truth for derived and tool-related variables, particularly:
- directory structure
- tool download parameters
- tool-specific static configuration

| Aspect | Description |
|--------|------------|
| Purpose | Static variable definitions |
| Contains logic? | No |
| Performs validation? | No |
| Consumed by | Preflight and execution layers |
| Scope | Paths and tool configuration parameters |

Variables defined in `utils/` are:
- consumed by preflight scripts for validation and installation
- used to construct derived runtime state (e.g. output directories)
- relied upon by tool preflight scripts for deterministic installation

This ensures that all shared parameters are:
- defined once
- validated centrally
- used consistently across all layers

# File Overview
The directory is organised into:
- a shared path definition file (`utils_paths.sh`)
- tool-specific configuration files (`utils_<tool>.sh`)

Each file:
- defines variables within its domain
- contains no logic
- introduces no side effects

| File | Responsibility |
|------|----------------|
| `utils_paths.sh` | Defines core directory variables and initialises `DIR_ARRAY` |
| `utils_bbtools.sh` | Defines BBTools download parameters (URL, tarball) |
| `utils_trimmomatic.sh` | Defines Trimmomatic download parameters (URL, tarball) |

## utils_paths.sh
Defines all core directory paths derived from `ROOT_DIR`.

Typical variables include:
```text
ARRAY_DIR
FUNCTIONS_DIR
PIPELINE_DIR
PREFLIGHT_DIR
UTILS_DIR
OUTPUT_DIR
```

It also initialises `DIR_ARRAY`, which defines the base set of pipeline-owned writable directories.

This array is intentionally minimal and typically includes:
```text
OUTPUT_DIR
```

It is later extended during preflight to include pipeline-specific directories such as:

```text
PACKAGE_OUTDIR
```

This file defines the directory structure contract of the pipeline.

## utils_bbtools.sh
Defines all static parameters required for downloading and installing BBTools.
Includes:
- `BBTOOLS_URL` — location of the release archive
- `BBTOOLS_TARBALL` — archive filename

These variables are consumed by:
- `functions_bbtools.sh` (download/extract logic)
- `preflight_bbtools.sh` (validation and installation orchestration)

No download, extraction, or validation logic is included here — this script is purely declarative.

## utils_trimmomatic.sh
Defines all static parameters required for downloading and installing Trimmomatic.

Includes:
- `TRIMMOMATIC_URL` — location of the release archive
- `TRIMMOMATIC_TARBALL` — archive filename

These variables are consumed by:
- `functions_trimmomatic.sh` (download/extract logic)
- `preflight_trimmomatic.sh` (validation and installation orchestration)

As with all `utils/` scripts, this file contains no logic.

# Variable Ownership Model
Each variable is defined in the layer where its meaning originates:
- global directory structure → `utils_paths.sh`
- tool configuration parameters → `utils_<tool>.sh`
- pipeline-derived variables → preflight scripts

This ensures:
- no duplication
- no accidental redefinition
- no hidden dependencies

Each variable has a clear, single owner within the pipeline.

# Usage Pattern
Utility scripts are sourced by preflight scripts and, where required, execution modules:

```bash
source "${UTILS_DIR}/utils_paths.sh"
source "${UTILS_DIR}/utils_bbtools.sh"
source "${UTILS_DIR}/utils_trimmomatic.sh"
```

Variables defined here are:
- validated during preflight
- used to construct pipeline state
- passed downstream via the execution ABI when required

They are never modified after definition.

# Key Rules
- Do not include logic (no loops, no conditionals)
- Do not perform validation
- Do not modify variables after definition
- Do not create or mutate runtime state
- Ensure variables are clearly named and unambiguous
- Keep all definitions deterministic and reproducible

# Summary
The `utils/` directory defines the static configuration layer of the `fastq-trim` pipeline.

It ensures that:
- all shared paths and tool parameters are declared in one place
- variables are consistently defined and traceable
- preflight scripts can perform validation deterministically
- execution layers operate on a stable, pre-validated environment

This separation is fundamental to maintaining a:
- reproducible
- portable
- contract-driven HPC pipeline architecture