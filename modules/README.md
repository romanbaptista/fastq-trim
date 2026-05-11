# `modules`

This directory contains the implementation modules for the trim pipeline.

Each module is responsible for exactly one pipeline role and is executed under SLURM as part of a deterministic, preflight‑validated workflow.

Modules are coordinated by modules/pipeline.sh, which is submitted by `run_pipeline.sh` only after all preflight checks have completed successfully.

# Design Contract
All modules in this directory adhere to the following principles:
- Single responsibility per script
- Explicit, absolute input and output paths
- Strong separation between validation and execution
- Restart‑safe behavior where possible
- Deterministic execution under SLURM
- No reliance on implicit working directories
- No reliance on undeclared global state
- Assumption that all preflight invariants have already been enforced

Modules **do not repeat preflight checks** and may assume that all required inputs, tools, and configuration variables are valid at runtime.

# Execution Model
The trim pipeline uses a single‑dispatch execution model:
- Exactly one trimming module is executed per pipeline run
- Tool selection is controlled by PACKAGE_TO_USE in config.sh
- All SLURM resource requests are defined centrally by the pipeline orchestrator

The current set of modules is:

pipeline.sh
bbduk.sh
trimmomatic.sh


Execution and SLURM submission logic are explicitly defined in `modules/pipeline.sh`.

# Module Overview

## `pipeline.sh`
Internal SLURM orchestrator for the trim pipeline.

### Role
`pipeline.sh` is responsible for coordinating execution of the trimming stage under SLURM. It is not intended to be executed directly by end users.

### Workflow
- Runs as a SLURM job submitted by `run_pipeline.sh`
- Validates the presence of required inherited environment variables
- Defines and creates the pipeline‑wide output directory
- Extends the explicit environment export contract
- Dispatches exactly one trimming module based on `PACKAGE_TO_USE`
- Aborts immediately if job submission fails

`pipeline.sh` does not perform any trimming itself.

### Guarantees
- Submits only one trimming module
- Passes an explicit, curated environment to downstream jobs
- Does not duplicate preflight validation logic
- Produces a single SLURM log for pipeline‑level orchestration

## `bbduk.sh`
Runs adapter removal and quality trimming using BBDUK from the BBTools suite.

### Inputs
- `INPUT_DIR` (directory containing sample subdirectories)
- BBDUK executable and adapter FASTA (validated in preflight)
- BBDUK‑specific configuration variables from `config.sh`
- SLURM‑allocated CPUs and memory

### Expected Input Layout
Each sample must reside in its own subdirectory under INPUT_DIR and contain exactly one paired FASTQ set:

INPUT_DIR/
├── sample1/
│   ├── sample1_1.fastq.gz
│   └── sample1_2.fastq.gz


### Workflow
- Iterates over sample directories in `INPUT_DIR`
- Enforces exactly one paired FASTQ dataset per sample
- Creates a per‑sample output directory
- Executes BBDUK using SLURM‑allocated resources
- Writes trimmed FASTQs and a per‑sample log file
- Aborts immediately on sample‑level errors while preserving logs

### Outputs

output/trim/
└── sample1/
    ├── sample1_1.trim.fastq.gz
    ├── sample1_2.trim.fastq.gz
    └── sample1_trim.log


### Guarantees
- No reliance on the working directory
- No shared state between samples
- Deterministic trimming per sample
- Safe to rerun if outputs already exist
- Assumes all tool and adapter requirements were satisfied in preflight

## `trimmomatic.sh`
Runs adapter removal and quality trimming using Trimmomatic.

### Inputs
- INPUT_DIR (directory containing sample subdirectories)
- Trimmomatic JAR and adapter FASTA (validated in preflight)
- Java runtime (validated in preflight)
- Trimmomatic‑specific configuration variables from config.sh
- SLURM‑allocated CPUs and memory

### Expected Input Layout
Identical to bbduk.sh:

INPUT_DIR/
├── sample1/
│   ├── sample1_1.fastq.gz
│   └── sample1_2.fastq.gz


### Workflow
- Iterates over sample directories in INPUT_DIR
- Enforces exactly one paired FASTQ dataset per sample
- Executes Trimmomatic in paired‑end mode
- Uses adapter clipping and quality filtering parameters from config.sh
- Writes trimmed outputs and per‑sample logs

### Outputs

output/trim/
└── sample1/
    ├── sample1.trim_1P.fastq.gz
    ├── sample1.trim_2P.fastq.gz
    ├── sample1.trim_1U.fastq.gz
    ├── sample1.trim_2U.fastq.gz
    └── sample1_trim.log

(Output naming follows Trimmomatic semantics.)

### Guarantees
- No reliance on implicit system state
- Correct use of SLURM‑allocated resources
- Deterministic behavior given identical inputs
- Safe to rerun where outputs already exist
- No validation duplication beyond preflight

# Notes

- All module scripts assume that preflight validation has already succeeded
- SLURM resource allocation is centralized and not user‑defined at module level
- No module modifies global system state
- No module requires interactive user input
- All paths are absolute and derived from exported pipeline variables