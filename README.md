# `fastq-trim`

# Overview
This repository contains the `fastq-trim` pipeline — a modular, HPC‑compatible workflow for:

> Performing adapter removal and quality trimming of paired FASTQ sequencing data using BBDUK or Trimmomatic within a reproducible, contract‑driven SLURM execution model.

The pipeline is designed for execution in HPC environments and provides:
- Deterministic trimming using BBDUK or Trimmomatic
- Fully validated execution environment prior to any job submission
- Explicit execution ABI for safe variable propagation across SLURM boundaries
- Parallel execution through SLURM compute nodes
- Clean separation between validation, orchestration, and execution
- Restart-safe, per-sample processing

Internally, the pipeline adheres to a strict contract-driven architecture, enforcing separation between:
- configuration
- declarative contract definition
- validation
- execution

This guarantees reproducibility, portability, and fail‑fast behaviour across HPC systems.
All outputs are written to a structured `output/` directory and are suitable for direct downstream use in QC, alignment, and variant-calling pipelines.

# Repository Structure
```text
fastq-trim/
├── README.md                  # Top-level overview (this file)
├── config.sh                  # User configuration (inputs + parameters)
├── fastq-trim.sh              # Entry point (logging + preflight + submission)
│
├── arrays/                    # Declarative pipeline contracts (ABI + ordering)
│   ├── array_preflight.sh
│   ├── array_pipeline.sh
│   ├── array_variables.sh
│   ├── array_binaries.sh
│   └── array_exports.sh
│
├── utils/                     # Static variable definitions (no logic)
│   ├── utils_paths.sh
│   ├── utils_bbtools.sh
│   └── utils_trimmomatic.sh
│
├── functions/                 # Atomic helper functions
│   ├── functions_base.sh
│   ├── functions_bbtools.sh
│   └── functions_trimmomatic.sh
│
├── preflight/                 # Validation + environment setup
│   ├── preflight.sh
│   ├── preflight_paths.sh
│   ├── preflight_variables.sh
│   ├── preflight_binaries.sh
│   ├── preflight_input.sh
│   ├── preflight_exports.sh
│   ├── preflight_pipeline.sh
│   ├── preflight_bbtools.sh
│   └── preflight_trimmomatic.sh
│
├── pipeline/                  # Execution layer
│   ├── pipeline.sh            # SLURM orchestrator
│   ├── bbduk.sh
│   └── trimmomatic.sh
│
├── output/                    # Pipeline outputs (created at runtime)
├── logs/                      # Centralised logs
└── env/                       # Tool/environment artefacts
```

# Workflow

At a high level, the pipeline executes in three phases:

## Preflight validation
The preflight layer performs strict fail-fast validation before any SLURM job is submitted:
- Verifies all required system binaries are available
- Confirms required configuration variables are set and valid
- Validates input directory structure and FASTQ files
- Ensures pipeline scripts exist and are executable
- Constructs the execution ABI (`EXPORT_ARRAY`)
- Generates SBATCH_EXPORTS for SLURM environment propagation
- Validates pipeline structure and available modules
- Installs and verifies the selected trimming tool (BBDUK or Trimmomatic)

## Pipeline orchestration
The entrypoint submits a SLURM orchestration script (`pipeline.sh`), which:
- Logs execution using a centralised log file
- Consumes the immutable execution ABI (`SBATCH_EXPORTS`)
- Selects the trimming module based on `PACKAGE_TO_USE`
- Submits a single module job via sbatch
- Applies CPU and memory settings from the configuration

## Execution modules

### `bbduk.sh`
- Processes paired FASTQ files per sample directory
- Enforces exactly one FASTQ pair per sample
- Performs adapter removal and quality trimming using BBDUK
- Uses SLURM-provided CPU resources
- Writes outputs to per-sample directories
- Skips already completed samples (restart-safe)

### `trimmomatic.sh`
- Processes paired FASTQ files per sample directory
- Enforces exactly one FASTQ pair per sample
- Performs adapter and quality trimming using Trimmomatic
- Loads Java via module system
- Uses SLURM-provided CPU/memory resources
- Writes outputs to per-sample directories
- Skips already completed samples (restart-safe)

# Execution Model
The pipeline enforces strict execution boundaries:

```text
login node
  → preflight (validation + environment construction)
    → SLURM job (pipeline.sh)
      → SLURM job (execution module)
```

Key guarantees:
- No implicit environment state crosses boundaries
- All variables passed explicitly via SBATCH_EXPORTS
- Functions are re-sourced explicitly where required
- Each layer assumes upstream validation has completed

# Configuration
All user-defined parameters are specified in `config.sh`.

At minimum:
```bash
INPUT_DIR="<path to FASTQ directory>"
PACKAGE_TO_USE="bbduk"  # or "trimmomatic"
```

Additional parameters control resource allocation and trimming behaviour.

| Variable | Description |
|----------|------------|
| `INPUT_DIR` | Directory containing input FASTQ data |
| `PACKAGE_TO_USE` | Trimming tool selection (`bbduk` or `trimmomatic`) |
| `BBDUK_CPUS` | CPUs per BBDUK task |
| `BBDUK_MEM_PER_CPU` | Memory per CPU for BBDUK |
| `BBDUK_TRIMQ` | Quality trimming threshold |
| `BBDUK_MINLEN` | Minimum read length after trimming |
| `TRIMMOMATIC_CPUS` | CPUs per Trimmomatic task |
| `TRIMMOMATIC_MEM_PER_CPU` | Memory per CPU for Trimmomatic |
| `TRIMMOMATIC_MISMATCH` | Adapter seed mismatch tolerance |
| `TRIMMOMATIC_LEADING` | Leading quality trimming threshold |
| `TRIMMOMATIC_TRAILING` | Trailing quality trimming threshold |
| `TRIMMOMATIC_WINDOW` | Sliding window size |
| `TRIMMOMATIC_CLIP` | Sliding window quality threshold |
| `TRIMMOMATIC_DISCARD` | Minimum read length after trimming |

# Usage
From the pipeline root directory:

```bash
bash fastq-trim.sh
```

This will:
- Execute full preflight validation
- Install and validate required tools
- Construct the execution ABI
- Submit SLURM job(s)
- Perform trimming using the selected tool

# Outputs
All outputs are written to `output/fastq-trim/`:

```text
output/
└── fastq-trim/
    ├── sample1/
    │   ├── sample1_1.trim.fastq.gz
    │   ├── sample1_2.trim.fastq.gz
    │   └── sample1.log
    ├── sample2/
    └── ...
```

Outputs are:
- Deterministic
- Restart-safe
- Organised per sample
- Compatible with downstream pipelines

# Architecture Summary

| Layer | Responsibility |
|------|----------------|
| `config.sh` | User-defined configuration |
| `arrays/` | Declarative pipeline contract and ABI |
| `utils/` | Static variable definitions |
| `functions/` | Atomic helper functions |
| `preflight/` | Validation and environment setup |
| `pipeline/` | SLURM orchestration |
| `modules` | Execution (bbduk, trimmomatic) |

# Further Documentation
For detailed documentation on individual components:
- `arrays/README.md` — contract layer and ABI design
- `preflight/README.md` — validation logic and guarantees
- `pipeline/README.md` — orchestration and execution model
- `utils/README.md` — static variables and shared definitions
- `functions/README.md` — helper functions and validation primitives

# Design Principles
This pipeline enforces:
- Contract-driven design
- Fail-fast validation
- Explicit execution boundaries
- Minimal, explicit ABI
- Deterministic execution
- Modular, reproducible HPC workflows

# Citation
If you use this pipeline in published work, please cite:

> Baptista, R. _fastq-trim: A contract-driven HPC pipeline for FASTQ trimming_.
> GitHub repository: https://github.com/romanbaptista/fastq-trim