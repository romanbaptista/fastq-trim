# `modules`
This directory contains the execution modules for the `fastq-trim` pipeline.

Each module is responsible for exactly one execution role and operates under a strict, preflight‑validated contract designed for HPC environments where compute‑intensive work must be offloaded to the scheduler.

Modules are coordinated by `modules/pipeline.sh`, which is invoked by `run_pipeline.sh` only after all preflight checks have completed successfully.

# Design Contract
All modules in this directory adhere to the following principles:
- Single responsibility per script
- Explicit, absolute input and output paths
- Strong separation between validation and execution
- Restart‑safe behavior where possible
- Deterministic execution model
- No reliance on implicit working directories
- No reliance on undeclared global state
- No duplication of preflight validation logic
- Assumption that all preflight invariants have already been enforced
- Strict consumption of the execution ABI (`EXPORT_ARRAY`)

Modules do not perform input validation, tool installation, or configuration checks.
All such guarantees are established by the preflight layer and enforced via guarded environment variables.

# Execution Model
`fastq-trim` is a scheduler‑backed pipeline:
- Orchestration logic runs on the login node
- Execution modules run as SLURM jobs on compute nodes
- Execution behavior is controlled via an explicit environment contract

The execution flow is:
```text
run_pipeline.sh
  └─ pipeline.sh
       └─ bbduk.sh / trimmomatic.sh
```

Only one execution module is dispatched per pipeline run, based on `PACKAGE_TO_USE`.

All SLURM submissions occur only after successful preflight validation.

# Module Overview
## `pipeline.sh`
Internal orchestrator for the `fastq-trim` pipeline.

### Role
`pipeline.sh` coordinates submission of downstream execution modules. It is not intended to be executed directly by end users.

### Workflow
- Runs as a SLURM job submitted by `run_pipeline.sh`
- Guards all required variables defined in the execution ABI
- Assumes all preflight checks have succeeded
- Dispatches exactly one execution module based on `PACKAGE_TO_USE`
- Passes the precomputed execution ABI (`SBATCH_EXPORTS`) to the module
- Captures the submitted job ID for diagnostics

`pipeline.sh` does not perform trimming itself.

### Guarantees
- Deterministic orchestration
- No mutation of the execution ABI
- No data processing
- No tool execution
- No duplication of preflight logic

## `bbduk.sh`
Execution module for FASTQ trimming using BBDUK.

### Role
Processes paired FASTQ files for each sample using the bbtools suite.

### Inputs
- Sample directories under `INPUT_DIR`
- Pipeline-owned configuration variables (e.g. `BBDUK_TRIMQ`, `BBDUK_MINLEN`)
- SLURM‑injected variables (`SLURM_CPUS_PER_TASK`)
- Execution ABI (`EXPORT_ARRAY`, `SBATCH_EXPORTS`)

### Expected Input Layout
```text
INPUT_DIR/
├── sample1/
│   ├── sample1_1.fastq.gz
│   └── sample1_2.fastq.gz
```

### Workflow
- Iterates over sample-specific directories
- Identifies paired FASTQ files using deterministic glob patterns
- Enforces exactly one pair per sample
- Creates a per-sample output directory
- Runs BBDUK using SLURM-allocated resources
- Writes trimmed FASTQ files
- Logs all output per sample
- Skips samples where outputs already exist

### Outputs
```text
output/trim/
└── sample1/
    ├── sample1_1.trim.fastq.gz
    ├── sample1_2.trim.fastq.gz
    └── sample1.log
```

### Guarantees
- One sample per execution unit
- No shared state between samples
- Restart‑safe execution
- Deterministic file discovery
- Assumes all tool and input validation completed in preflight

## `trimmomatic.sh`
Execution module for FASTQ trimming using trimmomatic.

### Role
Processes paired FASTQ files for each sample using the trimmomatic Java application.

### Inputs
- Sample directories under `INPUT_DIR`
- Pipeline-owned configuration variables (e.g. trimming parameters)
- SLURM‑injected variables (`SLURM_CPUS_PER_TASK`)
- Execution ABI (`EXPORT_ARRAY`, `SBATCH_EXPORTS`)

### Expected Input Layout
```text
INPUT_DIR/
├── sample1/
│   ├── sample1_1.fastq.gz
│   └── sample1_2.fastq.gz
```

### Workflow
- Iterates over sample-specific directories
- Identifies exactly one paired FASTQ dataset per sample
- Creates a per-sample output directory
- Runs trimmomatic in paired-end mode
- Writes paired and unpaired trimmed reads
- Logs execution per sample
- Skips samples where output already exists

### Outputs
```text
output/trim/
└── sample1/
    ├── sample1.trim_1P.fastq.gz
    ├── sample1.trim_2P.fastq.gz
    ├── sample1.trim_1U.fastq.gz
    ├── sample1.trim_2U.fastq.gz
    └── sample1.log
```

### Guarantees
- One sample per execution unit
- No shared state between samples
- Restart‑safe execution
- Deterministic trimming given identical inputs
- Assumes all tool and input validation completed in preflight

# Notes
- All modules assume preflight validation has completed successfully
- No module installs software or performs environment configuration
- All filesystem paths are absolute and derived from the execution ABI
- All required variables are guarded at entry
- No module requires interactive input
- The pipeline is safe to re-run to resume partial trimming
- Downstream pipelines (alignment, variant calling, etc.) may safely consume outputs