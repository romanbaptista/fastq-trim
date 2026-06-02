# `preflight`

# Overview
The `preflight/` directory implements the validation and environment construction layer of the `fastq-trim` pipeline.

This layer is responsible for ensuring that all requirements are satisfied before any SLURM jobs are submitted.

It performs:
- validation of user configuration
- validation of system environment
- validation of input FASTQ data
- validation of pipeline structure
- construction of runtime directories
- installation and validation of trimming tools (BBDUK or Trimmomatic)
- construction of the execution ABI (`SBATCH_EXPORTS`)

The preflight phase enforces a strict fail‑fast model, guaranteeing that downstream execution begins only in a fully validated and deterministic state.

# Design Principles
The preflight layer follows core architectural rules:
- Fail-fast — any error immediately terminates the pipeline
- Validation-only responsibility — no data processing or module execution
- Deterministic ordering — all steps run in a strictly defined sequence
- Explicit contracts — validation driven entirely by declarative arrays
- No hidden state — all required variables, tools, and inputs are explicitly checked
- Reproducibility — tools are installed and validated deterministically

This ensures that all downstream scripts can assume:
- consistent state
- valid inputs
- functional tools
- fully constructed runtime environment

# Role in the Pipeline
The preflight layer is executed immediately after the entrypoint script (`fastq-trim.sh`) and before any SLURM submission occurs.

It ensures:
- all required variables are defined and non-empty
- all required system binaries are available
- all input files and directories are valid
- all pipeline scripts exist and are executable
- all runtime directories are created
- the selected trimming tool is installed and functional
- the execution ABI is fully constructed and ready for export

Only once all checks succeed does execution proceed to the pipeline orchestration stage.

# Execution Flow
Preflight is orchestrated by `preflight.sh`.

This script:
- sources `array_preflight.sh`
- validates the `PREFLIGHT_ARRAY` contract
- dynamically appends the selected tool-specific preflight script
- executes each preflight script in order
- terminates immediately on failure

Each script:
- consumes only validated upstream state
- performs validation or controlled environment construction
- guarantees correctness of its own domain

This enforces a strict producer → consumer relationship between validation stages.

# Preflight Stages
The pipeline implements the following validation stages:

### Paths
- Defines all pipeline directories via `utils_paths.sh`
- Extends `DIR_ARRAY` with pipeline-specific directories
- Creates all required directories in a single pass

### Variables
- Validates core user-defined variables from `config.sh`
- Ensures all required configuration inputs are present

### Binaries
- Verifies required system-level CLI tools from `BINARY_ARRAY`
- Ensures basic runtime environment availability

### Input
- Validates input directory existence
- Confirms input directory is non-empty
- Validates presence of `.fastq.gz` files
- Ensures pipeline has usable sequencing data

### Exports
- Constructs the execution ABI from `EXPORT_ARRAY`
- Exports all required pipeline variables
- Generates `SBATCH_EXPORTS` for SLURM job submission

### Pipeline
- Confirms all execution modules exist
- Ensures scripts are non-empty
- Enforces executable permissions
- Validates presence of `pipeline.sh` orchestrator

### Tool Validation (BBDUK / Trimmomatic)
- Validates tool-specific configuration variables
- Checks for existing tool installation

If absent or invalid:
- downloads tool archive
- extracts and installs deterministically
- Re-validates installation after setup

Tool selection is driven by `PACKAGE_TO_USE`, and only the relevant tool preflight script is executed.

# Script Structure
Each preflight script follows a consistent structure:

```text
GUARDS
SETUP
SOURCE
CHECKS
MAIN
```

- `GUARDS` validate required variables using shared validation functions
- `SETUP` defines script-level constants
- `SOURCE` imports required arrays, utils, or functions
- `CHECKS` validates consumed state
- `MAIN` performs validation or controlled environment construction

This ensures:
- predictable control flow
- explicit dependencies
- strict separation between validation stages

# Tool Integration Model
Each tool is integrated using a three-part structure:
- `utils_<tool>.sh` → defines static parameters (URL, archive)
- `functions_<tool>.sh` → implements atomic install and validation logic
- `preflight_<tool>.sh` → orchestrates validation and installation

This separation ensures:
- no logic in utils
- no orchestration in functions
- no validation duplication

All tool installation occurs exclusively in preflight, ensuring execution modules never perform setup.

# Execution ABI
The preflight layer constructs the execution ABI using:
- `array_exports.sh` → defines required variables
- `preflight_exports.sh` → exports variables and constructs `SBATCH_EXPORTS`

This ensures:
- only required variables are passed to SLURM jobs
- no implicit environment state is relied upon
- execution environments are deterministic and reproducible

# Execution Relationships

| Script | Responsibility |
|--------|----------------|
| `preflight.sh` | Orchestrates execution of all preflight stages |
| `preflight_paths.sh` | Defines and creates pipeline directories |
| `preflight_variables.sh` | Validates core user configuration variables |
| `preflight_binaries.sh` | Validates required system binaries |
| `preflight_input.sh` | Validates input FASTQ directory and files |
| `preflight_exports.sh` | Constructs SBATCH_EXPORTS from EXPORT_ARRAY |
| `preflight_pipeline.sh` | Validates pipeline scripts and orchestrator |
| `preflight_bbtools.sh` | Validates and installs BBTools |
| `preflight_trimmomatic.sh` | Validates and installs Trimmomatic |

# Key Rules
- Do not include execution logic in preflight scripts
- Do not defer validation to downstream stages
- Always fail immediately on error
- Only validate variables consumed by the script
- Maintain strict ordering via `PREFLIGHT_ARRAY`
- Do not rely on implicit environment state
- Ensure all execution dependencies are satisfied before completion
- Treat SLURM execution as a strict boundary

# Summary
The `preflight/` directory guarantees that the pipeline executes in an environment that is:
- fully validated
- reproducible
- deterministic

By enforcing strict contracts and fail-fast validation, it provides a clean boundary between setup and execution.

This ensures that all downstream pipeline stages can operate:
- without ambiguity
- without hidden dependencies
- with full confidence in their execution context