#!/bin/bash

# check_file
# Verifies that a regular file exists.
# Arguments:
#   $1 - path to file
# Operation:
#   Uses [[ -f ]] to confirm the file exists and is a regular file.
# Returns:
#   0 if the file exists
#   1 if the file does not exist (prints error)
# Example:
# check_file "/path/to/file.txt" || exit 1
check_file() {

    local path="$1"

    if [[ -f "${path}" ]]; then
        echo "  SUCCESS: File found: ${path}"
        return 0
    else
        echo "  ERROR: File not found: ${path}"
        return 1
    fi
}

# check_file_data
# Verifies that a file exists and is not empty.
# Arguments:
#   $1 - path to file
# Operation:
#   Uses [[ -s ]] to confirm file size > 0.
# Returns:
#   0 if file exists and contains data
#   1 if file missing or empty (prints error)
# Example:
# check_file_data "results.txt" || exit 1
check_file_data() {

    local path="$1"

    if [[ -s "${path}" ]]; then
        echo "  SUCCESS: File contains data: ${path}"
        return 0
    else
        echo "  ERROR: File does not contain data: ${path}"
        return 1
    fi
}

# make_executable
# Adds executable permissions to a file.
# Arguments:
#   $1 - path to file
# Operation:
#   Runs chmod +x on the specified path.
# Returns:
#   0 if permissions were successfully modified
#   1 if chmod fails (prints error)
# Example:
# make_executable "script.sh"
make_executable() {
    local path="$1"

    if chmod +x "${path}"; then
        echo "  SUCCESS: File is now executable: ${path}"
        return 0
    else
        echo "  ERROR: Failed to make file executable: ${path}"
        return 1
    fi
}

# check_executable
# Verifies that a file exists and is executable.
# Arguments:
#   $1 - path to file
# Operation:
#   Calls check_file; then checks executable bit with [[ -x ]].
# Returns:
#   0 if file exists and is executable
#   1 if file exists but is not executable
# Notes:
#   Calls fail() if file does not exist.
# Example:
# check_executable "./run.sh"
check_executable() {
    local path="$1"

    if [[ ! -f "${path}" ]]; then
        echo "  ERROR: File does not exist: ${path}"
        return 1
    fi

    if [[ -x "${path}" ]]; then
        echo "  SUCCESS: File is executable: ${path}"
        return 0
    else
        echo "  ERROR: File is not executable: ${path}"
        return 1
    fi
}

# check_directory
# Verifies that a directory exists.
# Arguments:
#   $1 - path to directory
# Operation:
#   Uses [[ -d ]] to test for directory existence.
# Returns:
#   0 if directory exists
#   1 if directory is missing (prints error)
# Example:
# check_directory "/data/output" || exit 1
check_directory() {
    local path="$1"

    if [[ -d "${path}" ]]; then
        echo "  SUCCESS: Directory found: ${path}"
        return 0
    else
        echo "  ERROR: Directory not found: ${path}"
        return 1
    fi
}

# check_string
# Verifies that a string is non-empty.
# Arguments:
#   $1 - string value
# Operation:
#   Uses [[ -n ]] to test string length.
# Returns:
#   0 if string is non-empty
#   1 if string is empty or unset (prints error)
# Example:
# check_string "$SAMPLE_ID" || exit 1
check_string() {
    local string="$1"

    if [[ -n "${string}" ]]; then
        echo "  SUCCESS: String found: ${string}"
        return 0
    else
        echo "  ERROR: String empty or not set: ${string}"
        return 1
    fi
}

# check_variable
# Verifies that a named variable is set and non-empty.
# Arguments:
#   $1 - variable name (string)
# Operation:
#   Uses indirect expansion to read the variable value.
# Returns:
#   0 if variable exists and is non-empty
#   1 if variable is unset or empty (prints error)
# Example:
# check_variable "BIOPROJECT"
check_variable() {
    local name="$1"
    local value="${!name-}"

    if [[ -n "${value}" ]]; then
        echo "  SUCCESS: Variable set: ${name}"
        return 0
    else
        echo "  ERROR: Variable not set: ${name}"
        return 1
    fi
}

# check_command
# Verifies that a command is available in PATH.
# Arguments:
#   $1 - command name
# Operation:
#   Uses command -v to test command availability.
# Returns:
#   0 if command is found
#   1 if command is not found (prints error)
# Example:
# check_command tmux || exit 1
check_command() {
    local cmd="$1"

    if command -v "${cmd}" >/dev/null 2>&1; then
        echo "  SUCCESS: Command found: ${cmd}"
        return 0
    else
        echo "  ERROR: Command not found ${cmd}"
        return 1
    fi
}

# fail
# Prints an error message and terminates the script.
# Arguments:
#   All arguments are treated as an error message.
# Operation:
#   Writes message to stderr and exits with status 1.
# Returns:
#   Does not return.
# Example:
# fail "Configuration file missing"
fail () {
    echo "  $*" >&2
    echo "  Exiting..." >&2
    exit 1
}

# check_arg
# Verifies that a required function argument is provided.
# Arguments:
#   $1 - argument value
# Operation:
#   Calls check_string; prints calling function name on failure.
# Returns:
#   0 if argument is non-empty
#   2 if argument is missing (usage/programmer error)
# Example:
# check_arg "$DIR" || return $?
check_arg() {
    if [[ -n "$1" ]]; then
        return 0 
    else
        echo "    ${FUNCNAME[1]}: required argument missing" >&2
        return 2
    fi
}