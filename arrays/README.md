# `arrays`

# Overview
The `arrays/` directory defines the declarative contract layer of the `fastq-trim` pipeline.

These files contain no executable logic and instead declare:
- required configuration variables
- required system binaries
- execution modules
- preflight validation order
- execution ABI (exported variable contract)

Together, they define the Application Binary Interface (ABI) of the pipeline and its complete structural specification.

# Design Principles
- Declarative only — no functions, no control flow
- Single source of truth for pipeline structure
- Explicit contracts that enforce reproducibility
- Consumed by preflight and execution layers
- No hidden dependencies — all required inputs are declared
- Minimality — only required state is declared

These principles ensure that:
- the pipeline remains deterministic
- validation is centralised
- execution is reproducible across HPC environments

# Files and Responsibilities
The directory contains five core contract definitions:

| File | Responsibility |
|------|----------------|
| `array_variables.sh` | Defines required user configuration variables |
| `array_binaries.sh` | Defines required system binaries |
| `array_pipeline.sh` | Defines execution modules |
| `array_preflight.sh` | Defines ordered preflight validation stages |
| `array_exports.sh` | Defines execution ABI (variables exported to SLURM) |

# Contract Types

## `array_variables.sh`
Defines all variables that must be provided in `config.sh`.

Example:

```bash
VARIABLE_ARRAY=(
    INPUT_DIR
    PACKAGE_TO_USE
)
```

These variables:
- originate from user configuration
- are validated during preflight (`preflight_variables.sh`)
- must be non-empty before execution

Tool-specific variables are intentionally excluded and validated in tool-specific preflight scripts.

## `array_binaries.sh`
Defines all required system-level commands used by the pipeline.

### Rules
- include only commands explicitly invoked in scripts
- include scheduler and orchestration tools
- include system binaries used in pipeline and modules
- exclude tool installation logic (handled in preflight)
- exclude helper functions (not binaries)

Example:

```text
BINARY_ARRAY=(
    sbatch
    tee
    wget
    tar
    rm
    mv
    find
    grep
    java
    module
)
```

This contract defines the minimal runtime environment required for pipeline execution.

## `array_pipeline.sh`
Defines all execution modules in the pipeline.

For this pipeline:
- modules represent alternative execution paths
- execution order is defined in `pipeline.sh`, not here

Example:

```bash
PIPELINE_ARRAY=(
    "bbduk.sh"
    "trimmomatic.sh"
)
```

This ensures:
- all modules are explicitly declared
- all modules are validated before execution
- no undeclared scripts are executed

## `array_preflight.sh`
Defines the ordered execution of preflight scripts.

Order is critical and must follow dependency flow:

```bash
PREFLIGHT_ARRAY=(
    "preflight_paths.sh"
    "preflight_variables.sh"
    "preflight_binaries.sh"
    "preflight_input.sh"
    "preflight_exports.sh"
    "preflight_pipeline.sh"
)
```

Tool-specific preflight scripts are not included here and are instead:
- appended dynamically in `preflight.sh`
- selected based on `PACKAGE_TO_USE`

This ensures:
- clean separation between core validation and tool validation
- extensibility without modifying the base contract

## `array_exports.sh`
Defines the execution ABI of the pipeline.

This is the most critical contract in a SLURM-based pipeline.

Example:

```bash
EXPORT_ARRAY=(
    ROOT_DIR
    ARRAY_DIR
    FUNCTIONS_DIR
    UTILS_DIR
    PREFLIGHT_DIR
    PIPELINE_DIR
    OUTPUT_DIR
    PACKAGE_OUTDIR
    PACKAGE_TO_USE
    INPUT_DIR
    BBDUK_CPUS
    BBDUK_MEM_PER_CPU
    BBDUK_TRIMQ
    BBDUK_MINLEN
    TRIMMOMATIC_CPUS
    TRIMMOMATIC_MEM_PER_CPU
    TRIMMOMATIC_MISMATCH
    TRIMMOMATIC_LEADING
    TRIMMOMATIC_TRAILING
    TRIMMOMATIC_WINDOW
    TRIMMOMATIC_CLIP
    TRIMMOMATIC_DISCARD
)
```

This contract:
- defines all variables required across SLURM execution boundaries
- is converted into `SBATCH_EXPORTS` during preflight
- ensures no implicit environment state is relied upon

It guarantees:
- reproducibility across compute nodes
- portability across HPC environments
- explicit variable propagation

# Execution Relationships

| Array | Consumed By | Purpose |
|------|-------------|--------|
| `VARIABLE_ARRAY` | `preflight_variables.sh` | Validate user configuration |
| `BINARY_ARRAY` | `preflight_binaries.sh` | Validate system environment |
| `PIPELINE_ARRAY` | `preflight_pipeline.sh` | Validate module scripts |
| `PREFLIGHT_ARRAY` | `preflight.sh` | Define validation order |
| `EXPORT_ARRAY` | `preflight_exports.sh`, `pipeline.sh` | Construct and propagate execution ABI |

# Key Rules
- Do not include logic or validation in arrays
- Do not dynamically modify arrays
- Ensure all entries correspond to real entities (variables, scripts, binaries)
- Maintain strict alignment with preflight and execution layers
- Keep contracts minimal — no unused entries
- Ensure export contract reflects actual downstream consumption
- Avoid circular definitions (e.g. derived variables such as `SBATCH_EXPORTS` must not be included)

# Summary
The `arrays/` directory defines the contractual backbone of the `fastq-trim` pipeline:
- what must be provided (variables)
- what must exist (binaries)
- what will be executed (modules)
- in what order validation occurs (preflight)
- what state crosses execution boundaries (execution ABI)

All pipeline behaviour is derived from these declarations, ensuring:
- deterministic execution
- reproducibility across environments
- strict contract-driven validation
- clear separation between validation and execution