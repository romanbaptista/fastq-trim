# `pipeline`

# Overview
The `pipeline/` directory contains the execution layer of the `fastq-trim` pipeline.

| File | Responsibility |
|------|----------------|
| `pipeline.sh` | Orchestrates SLURM job submission and module selection |
| `bbduk.sh` | Performs trimming using BBTools (BBDUK) |
| `trimmomatic.sh` | Performs trimming using Trimmomatic |

These scripts implement the trimming workflow, operating on a fully validated environment constructed by the preflight layer.

All execution within this directory assumes that:
- all required variables are defined and exported via the execution ABI
- all required tools are installed and functional
- all required directories have been created
- all inputs have been validated

No validation or installation logic is duplicated in this layer.

# Module Naming Convention
Module scripts follow the pattern:

```text
<tool>.sh
```

In this pipeline:

```text
bbduk.sh        → trimming using BBTools (BBDUK)
trimmomatic.sh  → trimming using Trimmomatic
```

Unlike multi-stage pipelines, this pipeline implements mutually exclusive execution modules rather than ordered stages.

This convention provides:
- clear mapping between configuration (`PACKAGE_TO_USE`) and execution
- consistent naming across pipelines
- improved readability in logs and job submission

# Design Contract
All scripts in this directory adhere to the following principles:
- single responsibility per script
- execution-only (no validation beyond guard checks)
- explicit input and output paths
- deterministic behaviour
- no reliance on implicit working directories
- no reliance on undeclared global state
- compatibility with SLURM execution boundaries

Modules assume that all preflight invariants have already been enforced.

# Execution Model
The execution layer is orchestrated by `pipeline.sh`.

This script:
- runs as a SLURM job submitted after preflight
- consumes a fully validated environment via `SBATCH_EXPORTS`
- selects a trimming module based on `PACKAGE_TO_USE`
- submits exactly one module script via SLURM

Execution behaviour is defined by:
- explicit module selection (not stage chaining)
- SLURM job submission (`sbatch`)
- configuration-driven resource allocation

| Component | Role |
|----------|------|
| Orchestrator (`pipeline.sh`) | Submits and controls SLURM execution |
| Module (`bbduk.sh`) | Executes BBDUK trimming |
| Module (`trimmomatic.sh`) | Executes Trimmomatic trimming |

# `pipeline.sh`

### Role
- `pipeline.sh` is the SLURM orchestration script for execution
- It performs no data processing

### Responsibilities
- configures pipeline-level logging (`tee`)
- validates required execution variables via guard checks
- selects the trimming tool based on `PACKAGE_TO_USE`
- submits the selected module via sbatch
- passes the execution ABI via `SBATCH_EXPORTS`
- applies CPU and memory settings from configuration
- captures the submitted job ID (`--parsable`)

### Guarantees
- deterministic orchestration
- explicit module selection
- correct propagation of execution ABI
- no duplication of preflight validation

# Module Overview
Each module implements a single trimming strategy.

Modules are:
- execution-only
- stateless beyond defined inputs/outputs
- restart-safe
- dependent on preflight guarantees

## bbduk.sh
### Role
Performs adapter removal and quality trimming using BBTools (BBDUK).

### Inputs

```text
INPUT_DIR
PACKAGE_OUTDIR
ROOT_DIR
SLURM_CPUS_PER_TASK
BBDUK_TRIMQ
BBDUK_MINLEN
```

### Workflow
- iterates over sample subdirectories in `INPUT_DIR`
- validates exactly one FASTQ pair per sample
- creates a per-sample output directory
- skips samples with existing trimmed outputs
- runs `bbduk.sh` with user-defined parameters
- writes per-sample logs

### Outputs

```text
output/fastq-trim/<sample>/
├── sample_1.trim.fastq.gz
├── sample_2.trim.fastq.gz
└── sample.log
```

### Guarantees
- per-sample isolation
- deterministic output structure
- restart-safe execution
- consistent CPU utilisation via SLURM

## trimmomatic.sh
### Role
Performs adapter removal and quality trimming using Trimmomatic.

### Inputs

```text
INPUT_DIR
PACKAGE_OUTDIR
ROOT_DIR
SLURM_CPUS_PER_TASK
SLURM_MEM_PER_CPU
TRIMMOMATIC_MISMATCH
TRIMMOMATIC_LEADING
TRIMMOMATIC_TRAILING
TRIMMOMATIC_WINDOW
TRIMMOMATIC_CLIP
TRIMMOMATIC_DISCARD
```

### Workflow
- loads Java via environment modules
- iterates over sample subdirectories in `INPUT_DIR`
- validates exactly one FASTQ pair per sample
- creates a per-sample output directory
- skips samples with existing trimmed outputs
- runs Trimmomatic (`java -jar`) with defined parameters
- writes per-sample logs

### Outputs

```text
output/fastq-trim/<sample>/
├── sample_1.trim.fastq.gz
├── sample_2.trim.fastq.gz
└── sample.log
```

### Guarantees
- per-sample isolation
- restart-safe execution
- deterministic trimming behaviour
- explicit resource usage via SLURM

# Execution Boundary Considerations
This pipeline operates across strict execution boundaries:

```text
preflight (login node)
  → sbatch pipeline.sh
    → sbatch <module>.sh
```

Key principles:
- each SLURM job runs in a new shell
- environment state is never implicitly shared
- all required variables are passed explicitly
- functions are re-sourced where required

This is enforced through:

```text
EXPORT_ARRAY → defines execution ABI
SBATCH_EXPORTS → injects variables into SLURM jobs
```

Modules:
- rely only on exported variables
- do not assume inherited shell state
- perform minimal guard-based validation

# Logging Model
The pipeline implements structured logging:
- `pipeline.sh` → central orchestration log (via `tee`)
- module scripts → per-sample logs (one log per sample)

This ensures:
- traceable execution
- isolation of sample-level failures
- reproducible debugging

# Key Rules
- do not include validation logic in modules
- do not install tools during execution
- do not modify global configuration
- always use explicit paths
- enforce per-sample isolation
- ensure restart-safe behaviour
- maintain strict separation between orchestration and execution
- never rely on implicit environment state across SLURM boundaries

# Summary
The `pipeline/` directory implements the execution phase of the `fastq-trim` pipeline.

It provides:
- a SLURM-based orchestration layer
- configurable tool selection (BBDUK or Trimmomatic)
- scalable, per-sample parallel execution
- deterministic and restart-safe trimming

This design ensures that all runtime behaviour is:
- reproducible
- portable across HPC environments
- robust to partial execution
- easy to extend and maintain