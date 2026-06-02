#!/bin/bash

######################### DIRECTORIES ####################

# INPUT_DIR:
# Absolute or relative path to the directory containing input sequencing data
# for the fastq-trim pipeline.
# This directory MUST be set by the user, MUST exist, and MUST contain
# sample-specific subdirectories. Each subdirectory must contain exactly one
# paired set of compressed FASTQ files (e.g. *_1.fastq.gz and *_2.fastq.gz).
INPUT_DIR=""

######################### PACKAGE SELECTION #############

# PACKAGE_TO_USE:
# Trimming package to use for adapter and quality trimming.
# Supported options are "bbduk" or "trimmomatic".
# This setting determines:
#   - which trimming module is dispatched by pipeline.sh
#   - which tool-specific variables are validated during preflight
#   - which execution path is followed under SLURM
PACKAGE_TO_USE="bbduk"

######################### BBDUK.SH ######################

# BBDUK_CPUS:
# Number of CPU threads allocated per bbduk task.
# Increasing this value can improve conversion speed but will increase
# per-job CPU usage (6-8 is normal).
BBDUK_CPUS=8

# BBDUK_MEM_PER_CPU:
# Amount of memory allocated per CPU thread for bbduk.
# This value is typically passed to the scheduler as memory-per-CPU
# and should be adjusted based on dataset size and cluster policy (8-16 is normal).
BBDUK_MEM_PER_CPU=16G

# BBDUK_TRIMQ:
# Quality trimming threshold. Bases with Phred quality < TRIMQ are trimmed
# from the ends of reads (when qtrim is enabled). Lower values are more
# conservative and help preserve coverage for variant calling.
BBDUK_TRIMQ=10

# BBDUK_MINLEN:
# Minimum read length to retain after trimming. Reads shorter than this
# value are discarded. Prevents very short, low-information reads from
# entering downstream analyses.
BBDUK_MINLEN=20

######################### TRIMMOMATIC ###################

# TRIMMOMATIC_CPUS:
# Number of CPU threads allocated per trimmomatic task.
# Increasing this value can improve conversion speed but will increase
# per-job CPU usage.(4 is normal)
TRIMMOMATIC_CPUS=4

# TRIMMOMATIC_MEM_PER_CPU:
# Amount of memory allocated per CPU thread for trimmomatic.
# This value is typically passed to the scheduler as memory-per-CPU
# and should be adjusted based on dataset size and cluster policy (2-4 is normal).
TRIMMOMATIC_MEM_PER_CPU=4G

# TRIMMOMATIC_MISMATCH:
# Maximum number of mismatches allowed in the adapter seed during adapter
# clipping. Controls how tolerant Trimmomatic is to imperfect adapter matches.
TRIMMOMATIC_MISMATCH=2

# TRIMMOMATIC_LEADING:
# Removes low-quality bases from the beginning of the read if their
# Phred score is below this threshold.
TRIMMOMATIC_LEADING=3

# TRIMMOMATIC_TRAILING:
# Removes low-quality bases from the end of the read if their
# Phred score is below this threshold.
TRIMMOMATIC_TRAILING=3

# TRIMMOMATIC_WINDOW:
# Size of the sliding window (in bases) used for quality trimming.
# Trimmomatic calculates the average quality across this window.
TRIMMOMATIC_WINDOW=15

# TRIMMOMATIC_CLIP:
# Quality threshold used during sliding-window trimming. If the average
# quality within the window falls below this value, the read is trimmed.
TRIMMOMATIC_CLIP=4

# TRIMMOMATIC_DISCARD:
# Minimum read length to keep after all trimming steps. Reads shorter than
# this value are discarded to avoid low-information alignments.
TRIMMOMATIC_DISCARD=36