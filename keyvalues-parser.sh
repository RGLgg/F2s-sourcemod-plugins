#!/usr/bin/env bash

# Parse a KeyValues file into a JSON-like structure using awk for simplicity
# Supports: "Key" "Value" and nested blocks
# Limitations: Assumes no multiline values or escaped quotes

convert_from_keyvalues() {
    local file=$1

    awk '
    function trim(str) {
        sub(/^[ \t\r\n]+/, "", str)
        sub(/[ \t\r\n]+$/, "", str)
        return str
    }

    BEGIN {
        indent = 0
        print "{"
    }

    {
        line = trim($0)
        if (line == "" || line ~ /^\/\//) next

        if (line ~ /^\"[^\"]+\"[ \t]+\"[^\"]+\"$/) {
            match(line, /^\"([^\"]+)\"[ \t]+\"([^\"]+)\"$/, kv)
            key = kv[1]
            val = kv[2]
            for (i = 0; i < indent; i++) printf "  "
            printf "\"%s\": \"%s\",\n", key, val
        }
        else if (line ~ /^\"[^\"]+\"$/) {
            match(line, /^\"([^\"]+)\"$/, k)
            key = k[1]
            for (i = 0; i < indent; i++) printf "  "
            printf "\"%s\": {\n", key
            indent++
        }
        else if (line == "{") {
            next
        }
        else if (line == "}") {
            indent--
            for (i = 0; i < indent; i++) printf "  "
            printf "},\n"
        }
        else {
            print "ERROR: Unrecognized line: " line > "/dev/stderr"
            exit 1
        }
    }

    END {
        print "}"
    }
    ' "$file" | jq -c '.'  # jq cleans up trailing commas
}

test_updater_file() {
    local file=$1
    if [[ -z "$file" || ! -f "$file" ]]; then
        echo "KeyValue file not specified or does not exist: $file" >&2
        return 1
    fi

    local json
    if ! json=$(convert_from_keyvalues "$file"); then
        echo "Failed to parse KeyValue file: $file" >&2
        return 1
    fi

    local missing=()

    if ! jq -e '.Updater' <<< "$json" >/dev/null; then
        missing+=("Updater")
    else
        if ! jq -e '.Updater.Information' <<< "$json" >/dev/null; then
            missing+=("Updater.Information")
        else
            if ! jq -e '.Updater.Information.Version.Latest' <<< "$json" >/dev/null; then
                missing+=("Updater.Information.Version.Latest")
            fi
            if ! jq -e '.Updater.Information.Notes' <<< "$json" >/dev/null; then
                missing+=("Updater.Information.Notes")
            fi
        fi
        if ! jq -e '.Updater.Files.Plugin' <<< "$json" >/dev/null; then
            missing+=("Updater.Files.Plugin")
        fi
    fi

    if [[ ${#missing[@]} -eq 0 ]]; then
        return 0
    else
        echo "Missing sections:"
        for m in "${missing[@]}"; do
            echo "- $m"
        done
        return 1
    fi
}
