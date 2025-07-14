#!/bin/bash

namespace="pyler-mlops"
releaseTrain="train"
releaseTriton="triton"
releaseClient="client"
trainJobName="job-train-model"
clientPodName="triton-client"
pvcName="pyler-model-pvc"

# logging function
write_log() {
    local message="$1"
    local type="${2:-INFO}"

    # ANSI color codes
    local color_red="\033[0;31m"
    local color_green="\033[0;32m"
    local color_gray="\033[0;90m"
    local nocolor="\033[0m"

    local color="$color_gray"
    case "$type" in
        SUCCESS) color="$color_green" ;;
        ERROR)   color="$color_red" ;;
    esac

    # Use echo -e to interpret the backslash escapes for colors.
    echo -e "${color}[$type] $message${nocolor}"
}

