#!/bin/bash

######################### DIRECTORIES ####################

# Define directory containing fastq.gz per-sample folders
INPUT_DIR=""

######################### PACKAGE SELECTION #############

# PACKAGE_TO_USE:
# Trimming package to use, can be either "bbduk" or "trimmomatic"
PACKAGE_TO_USE="bbduk"

######################### BBDUK.SH ######################

# Define number of threads (6-8 is normal)
BBDUK_CPUS=8
# Define memory per thread (8-16 is normal)
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

# Define number of threads (4 is normal)
TRIM_CPUS=4
# Define memory per thread (2-4 is normal)
TRIM_MEM_PER_CPU=4G

# TRIM_MISMATCH:
# Maximum number of mismatches allowed in the adapter seed during adapter
# clipping. Controls how tolerant Trimmomatic is to imperfect adapter matches.
TRIM_MISMATCH=2

# TRIM_LEADING:
# Removes low-quality bases from the beginning of the read if their
# Phred score is below this threshold.
TRIM_LEADING=3

# TRIM_TRAILING:
# Removes low-quality bases from the end of the read if their
# Phred score is below this threshold.
TRIM_TRAILING=3

# TRIM_WINDOW:
# Size of the sliding window (in bases) used for quality trimming.
# Trimmomatic calculates the average quality across this window.
TRIM_WINDOW=15

# TRIM_CLIP:
# Quality threshold used during sliding-window trimming. If the average
# quality within the window falls below this value, the read is trimmed.
TRIM_CLIP=4

# TRIM_DISCARD:
# Minimum read length to keep after all trimming steps. Reads shorter than
# this value are discarded to avoid low-information alignments.
TRIM_DISCARD=36