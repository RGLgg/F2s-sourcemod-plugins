#!/usr/bin/env bash
set -euo pipefail

# Save current directory and switch to script location
pushd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null

echo -n "Updating PATH environment variable... "
export PATH="$PATH:$(pwd):$(pwd)/sourcemod-binaries/addons/sourcemod/scripting"
echo "DONE!"

get_spcomp_version() {
    if command -v spcomp64 >/dev/null 2>&1; then
        local version_output
        version_output=$(spcomp64 2>/dev/null | head -n 1)
        if [[ $version_output =~ SourcePawn\ Compiler\ ([0-9]+\.[0-9]+)(\.[0-9]+)* ]]; then
            echo "${BASH_REMATCH[1]}"
            return
        fi
    fi
    echo ""
}

echo -n "Installing SourceMod binaries... "
if [[ -d "sourcemod-binaries" && "$(get_spcomp_version)" == "1.12" ]]; then
    echo "already installed."
else
    if [[ -d "sourcemod-binaries" ]]; then
        timestamp=$(date +%Y%m%d_%H%M%S)
        mv sourcemod-binaries "sourcemod-binaries-backup-$timestamp"
    fi

    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
        sourcemod_filename="sourcemod-1.12.0-git7210-windows.zip"
        sourcemod_url="https://sm.alliedmods.net/smdrop/1.12/$sourcemod_filename"
        curl -sLO "$sourcemod_url"
        unzip -q "$sourcemod_filename" -d sourcemod-binaries
        rm -f "$sourcemod_filename"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sourcemod_filename="sourcemod-1.12.0-git7210-linux.tar.gz"
        sourcemod_url="https://sm.alliedmods.net/smdrop/1.12/$sourcemod_filename"
        curl -sLO "$sourcemod_url"
        mkdir -p sourcemod-binaries
        tar -xzf "$sourcemod_filename" -C sourcemod-binaries
        rm -f "$sourcemod_filename"
    else
        echo "OS not supported"
        exit 1
    fi
    echo "DONE!"
fi

echo ""
echo "You can now compile a plugin in one of the following ways:"
echo ""
echo -e "\033[1;33mcompile logstf\033[0m"
echo ""
echo -e "\033[1;33mcompile logstf/logstf.sp\033[0m"
echo ""
echo -e "\033[1;33mcd logstf\033[0m"
echo -e "\033[1;33mcompile\033[0m"

popd >/dev/null
