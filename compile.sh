#!/usr/bin/env bash
set -euo pipefail

path="${1:-}"

# If no path provided, find exactly one .sp file in current directory
if [[ -z "$path" ]]; then
    files=( *.sp )
    if [[ ${#files[@]} -ne 1 ]]; then
        echo "Could not find one .sp file in current directory" >&2
        exit 1
    fi
    path="${files[0]}"
fi

# If input is a folder name (like `logstf`), look for `logstf/logstf.sp`
if [[ ! -f "$path" && -f "$path/$path.sp" ]]; then
    path="$path/$path.sp"
fi

# Ensure .sp extension
if [[ "$path" != *.sp ]]; then
    path="$path.sp"
fi

directory=$(dirname "$path")
filename=$(basename "$path")

# Replace with your own path
includes_path="$HOME/Projects/sourcepawn/obj/spcomp/linux-x86_64/includes"

pushd "$directory" >/dev/null

# Call SourceMod compiler with custom include path
spcomp "$filename" -i "$includes_path"

popd >/dev/null
