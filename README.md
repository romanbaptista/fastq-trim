# Trim Pipeline

# Overview
This repository contains the trim pipeline — a modular, SLURM‑compatible workflow for:

> Adapter removal and quality trimming of compressed FASTQ sequencing data using BBDUK or Trimmomatic in a reproducible, HPC‑friendly manner.

The pipeline is designed specifically for HPC environments and provides:
- Validation of user‑supplied input FASTQ directories
- Tool‑specific preflight checks and dependency enforcement
- Flexible selection between BBDUK and Trimmomatic
- Robust SLURM job orchestration with explicit environment contracts
- Per‑sample trimming with isolated logs
- Centralised, deterministic output structure for downstream workflows

All trimmed outputs are written to a dedicated output/ directory, enabling seamless continuation into alignment, variant calling, or additional QC pipelines.

# Repository Structure
```text
trim/
├── README.md                               # Top-level overview (this file)
├── config.sh                               # User configuration (input paths, resources, parameters)
├── run_pipeline.sh                         # Entry point (preflight + SLURM submission)
├── preflight/                              # Pipeline preflight validation
│   ├── preflight_input.sh                  # Input directory and FASTQ validation
│   ├── preflight_variables.sh              # Core configuration variables
│   ├── preflight_scripts.sh                # Module script integrity checks
│   ├── preflight_commands.sh               # Required external command checks
│   ├── preflight_bbduk.sh                  # BBDUK-specific validation and installation
│   └── preflight_trimmomatic.sh            # Trimmomatic-specific validation and installation
├── utils/                                  # Shared utility functions
│   ├── functions_base.sh                   # Core validation and helper functions
│   ├── functions_bbtools.sh                # BBTools install/check helpers
│   └── functions_trimmomatic.sh            # Trimmomatic install/check helpers
├── modules/                                # Pipeline modules (executed under SLURM)
│   ├── pipeline.sh                         # SLURM pipeline orchestrator
│   ├── bbduk.sh                            # BBDUK trimming module
│   └── trimmomatic.sh                      # Trimmomatic trimming module
└── output/                                 # Pipeline-generated data (created at runtime)
```

# Workflow
At a high level, the trim pipeline proceeds as follows:

### Preflight validation
- Confirms required user variables are set and non‑empty
- Verifies the input directory exists and contains `.fastq.gz` files
- Ensures all module scripts are present and non‑empty
- Checks for all required external commands
- Validates or installs the selected trimming tool (BBDUK or Trimmomatic)
- Confirms required adapter files and executables are present and usable

All preflight checks must pass before any SLURM jobs are submitted.

### Pipeline orchestration
Submits a single SLURM job (`pipeline.sh`) that:
- Establishes a deterministic environment contract
- Defines a pipeline‑wide output directory
- Dispatches exactly one trimming module based on user selection

### Trimming (BBDUK or Trimmomatic)
- Iterates over sample‑specific subdirectories within the input directory
- Enforces exactly one paired FASTQ set per sample
- Runs trimming independently per sample
- Writes trimmed FASTQ files and logs into per‑sample output directories
- Fails fast on sample‑level errors while preserving logs for diagnosis

All execution is coordinated through SLURM to ensure reproducible, scalable operation.

# Configuration
All user‑tunable parameters are defined in config.sh.

At minimum, the user must specify:
```bash
INPUT_DIR="/path/to/sample_directories"
PACKAGE_TO_USE="bbduk"   # or "trimmomatic"
```

Each sample is expected to reside in its own subdirectory under INPUT_DIR, containing exactly one paired FASTQ set:
```text
INPUT_DIR/
├── sample1/
│   ├── sample1_1.fastq.gz
│   └── sample1_2.fastq.gz
├── sample2/
│   ├── sample2_1.fastq.gz
│   └── sample2_2.fastq.gz
```

Additional tool‑specific parameters are available and validated automatically.

| Variable | Description |
|--------|-------------|
| `INPUT_DIR` | Absolute path to the directory containing sample-specific subdirectories, each holding exactly one paired `.fastq.gz` dataset |
| `PACKAGE_TO_USE` | Trimming tool to use: `bbduk` or `trimmomatic` |
| `BBDUK_CPUS` | Number of CPUs allocated per BBDUK SLURM job |
| `BBDUK_MEM_PER_CPU` | Memory allocated per CPU for BBDUK |
| `BBDUK_TRIMQ` | Quality threshold for base trimming in BBDUK |
| `BBDUK_MINLEN` | Minimum read length retained after BBDUK trimming |
| `TRIM_CPUS` | Number of CPUs allocated per Trimmomatic SLURM job |
| `TRIM_MEM_PER_CPU` | Memory allocated per CPU for Trimmomatic |
| `TRIM_MISMATCH` | Maximum allowed mismatches in the adapter seed for Trimmomatic |
| `TRIM_LEADING` | Quality threshold for trimming low-quality bases from the start of reads |
| `TRIM_TRAILING` | Quality threshold for trimming low-quality bases from the end of reads |
| `TRIM_WINDOW` | Window size (in bases) used for sliding-window quality trimming |
| `TRIM_CLIP` | Average quality threshold required within the sliding window |
| `TRIM_DISCARD` | Minimum read length retained after all Trimmomatic trimming steps |

All variables are validated in preflight; unset or empty values cause the pipeline to exit before submission.

# Usage
Navigate to the pipeline root directory and run:
```bash
bash run_pipeline.sh
```

This will:
- Execute all preflight validation steps
- Install or verify required trimming tools if needed
- Submit the trimming pipeline to SLURM
- Exit cleanly after submission

Once submitted, users may safely disconnect from the cluster.

# Outputs
All pipeline outputs are written under output/, grouped by sample.

Example structure after a complete run:
```text
output/
└── trim/
    ├── sample1/
    │   ├── sample1_1.trim.fastq.gz
    │   ├── sample1_2.trim.fastq.gz
    │   └── sample1_trim.log
    └── sample2/
        ├── sample2_1.trim.fastq.gz
        ├── sample2_2.trim.fastq.gz
        └── sample2_trim.log
```

Logs include:
- `run_pipeline.log` (launcher‑level, overwritten per run)
- `pipeline.<jobid>.log` (pipeline orchestration)
- Per‑sample trimming logs within each sample directory

This structure enables precise troubleshooting without ambiguity across samples or runs.

# Further Documentation
For detailed documentation on individual components, see:
- `preflight/README.md` — preflight validation design and responsibilities
- `modules/README.md` — trimming modules and SLURM execution details
- `utils/README.md` — shared utility functions and helpers

# Citation
If you use this pipeline in published work, please cite:

> Baptista, R. trim: A SLURM‑compatible pipeline for FASTQ trimming using BBDUK and Trimmomatic.
GitHub repository: https://github.com/romanbaptista/trim

Optionally include the specific commit hash or release tag used for analysis.