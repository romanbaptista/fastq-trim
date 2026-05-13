# `fastq-trim`

# Overview
This repository contains the `fastq-trim` pipeline — a modular, HPC‑compatible workflow for:

> Adapter removal and quality trimming of paired-end FASTQ sequencing data in a reproducible, restart-safe, and execution-contract–driven manner.

The pipeline is designed to operate downstream of sequencing data generation or QC pipelines and assumes that FASTQ files are already organised into a deterministic, sample-specific directory layout.

The pipeline is designed specifically for HPC environments and supports:
- Explicit environment contracts for deterministic execution across SLURM boundaries
- Tool‑agnostic trimming via selectable modules (e.g. BBDUK or trimmomatic)
- Strict preflight validation before any SLURM jobs are submitted
- Per-sample output isolation enabling safe restart and partial completion
- Canonical pipeline structure defined via shared arrays and enforced contracts

All pipeline outputs are written to a dedicated output/ directory, enabling clean chaining into downstream alignment, variant calling, or analysis workflows.

# Repository Structure
```text
fastq-trim/
├── README.md                               # Top-level overview (this file)
├── config.sh                               # User configuration (inputs and parameters)
├── run_pipeline.sh                         # Entry point (login-node orchestration)
├── utils/                                  # Shared utilities and canonical definitions
│   ├── arrays.sh                           # Source of truth for pipeline structure and ABI
│   ├── functions_base.sh                   # General-purpose helper functions
│   ├── functions_bbtools.sh                # bbtools install/check helpers
│   └── functions_trimmomatic.sh            # trimmomatic install/check helpers
├── preflight/                              # Preflight validation layer
│   ├── preflight.sh
│   ├── preflight_input.sh
│   ├── preflight_variables.sh
│   ├── preflight_scripts.sh
│   ├── preflight_commands.sh
│   ├── preflight_bbduk.sh
│   └── preflight_trimmomatic.sh
├── modules/                                # Execution modules
│   ├── pipeline.sh                         # Internal orchestrator (SLURM job)
│   ├── bbduk.sh                            # BBDUK trimming module
│   └── trimmomatic.sh                      # trimmomatic trimming module
└── output/                                 # Pipeline-generated results (created at runtime)
```

# Workflow
At a high level, the pipeline proceeds as follows:

### Preflight validation
- Verifies all required framework-level commands are available
- Confirms all required user configuration variables are set and non-empty
- Validates presence and integrity of module scripts
- Confirms the input directory exists and contains FASTQ data
- Ensures tool-specific dependencies are present or installs them deterministically
- Guarantees all execution invariants before any job submission

All validation is authoritative and occurs before any SLURM jobs are submitted.

### Pipeline orchestration
- Submits an internal orchestrator job (`modules/pipeline.sh`) from the login node
- Defines a strict execution ABI via `EXPORT_ARRAY`
- Passes only explicitly declared variables to downstream jobs via `--export`
- Dispatches exactly one trimming module based on user configuration

### Trimming execution
The selected module executes under SLURM and:
- Iterates over sample-specific directories within the input directory
- Processes exactly one paired FASTQ dataset per sample
- Writes outputs and logs to per-sample directories
- Skips samples with existing outputs to support restart-safe execution
- Uses only explicitly exported variables and SLURM-allocated resources

Modules assume all preflight guarantees are satisfied and do not revalidate inputs.

# Configuration
All user‑tunable parameters are defined in `config.sh`.

| Variable | Description |
|----------|-------------|
| `INPUT_DIR` | Directory containing sample-specific subdirectories, each with exactly one paired set of `.fastq.gz` files |
| `PACKAGE_TO_USE` | Trimming tool to use (`bbduk` or `trimmomatic`) |
| `BBDUK_CPUS` | Number of CPU threads allocated per BBDUK task |
| `BBDUK_MEM_PER_CPU` | Memory allocated per CPU for BBDUK |
| `BBDUK_TRIMQ` | Quality threshold for base trimming in BBDUK |
| `BBDUK_MINLEN` | Minimum read length retained after BBDUK trimming |
| `TRIM_CPUS` | Number of CPU threads allocated per trimmomatic task |
| `TRIM_MEM_PER_CPU` | Memory allocated per CPU for trimmomatic |
| `TRIM_MISMATCH` | Maximum mismatches allowed in the adapter seed for trimmomatic |
| `TRIM_LEADING` | Quality threshold for trimming low-quality bases from the start of reads |
| `TRIM_TRAILING` | Quality threshold for trimming low-quality bases from the end of reads |
| `TRIM_WINDOW` | Sliding window size (in bases) for quality trimming |
| `TRIM_CLIP` | Average quality threshold within the sliding window |
| `TRIM_DISCARD` | Minimum read length retained after all trimmomatic trimming steps |

# Required Input Layout
The pipeline expects FASTQ files organised per sample:

```text
INPUT_DIR/
├── sample1/
│   ├── sample1_1.fastq.gz
│   └── sample1_2.fastq.gz
├── sample2/
│   ├── sample2_1.fastq.gz
│   └── sample2_2.fastq.gz
```

Each sample directory must contain exactly one paired dataset.

# Usage
Navigate to the root of the repository and run:

```bash
run_pipeline.sh
```

This will:
- Perform all preflight validation checks
- Install or verify required tools
- Submit the trimming workflow to the cluster via SLURM

The pipeline is restart‑safe; re-running the entrypoint will skip completed samples.

# Outputs
All pipeline outputs are written under `output/`, grouped by module and sample.

Example structure after completion:

```text
output/
└── trim/
    ├── sample1/
    │   ├── sample1_1.trim.fastq.gz
    │   ├── sample1_2.trim.fastq.gz
    │   └── sample1.log
    └── sample2/
        └── ...
```

Each sample is fully isolated, enabling independent failure handling and downstream processing.

# Further Documentation
For detailed documentation on individual components, see:
- preflight/README.md — validation guarantees and execution ordering
- modules/README.md — execution model and module contracts
- utils/README.md — shared utilities and ABI definitions

# Citation
If you use this pipeline in published work, please cite:
> Baptista, R. _fastq-trim: A contract-driven HPC pipeline for FASTQ trimming_.
> GitHub repository: https://github.com/romanbaptista/fastq-trim

Optionally include the commit hash or release tag used for analysis.