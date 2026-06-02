#!/bin/bash

# THIS WILL HOLD-NON REPEATING FUNCTIONS E.G. TMUX THAT ARE PIPELINE SPECIFIC

####################################################### BUILDERS

# function_single_var
function_single_var() {
    local arg="${1-}"

    # VALIDATION
    arg_check "${arg}" || return $?

    # FUNCTION
    ...
}

# function_multi_var
function_multi_var() {
    local arg1="${1-}"
    local arg2="${2-}"
    ...

    # VALIDATION
    local arg_array=(
        "${arg1}"
        "${arg2}"
        ...
    )

    for arg in "${arg_array[@]}"; do
        arg_check "${arg}" || return $?
    done

    # FUNCTION
    ...
}

####################################################### FUNCTIONS