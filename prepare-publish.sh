#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

source ./keyvalues-parser.sh  # You’ll need to convert this PS1 file to `.sh`

zip_files() {
    local zipfilename=$1
    local sourcedir=$2
    (
        cd "$sourcedir"
        zip -r9 "../$(basename "$zipfilename")" ./*
    )
    mv "$(basename "$zipfilename")" "$zipfilename"
    mark_files_in_zip_as_readable_on_linux "$zipfilename"
}

zip_file() {
    local zipfilename=$1
    local sourcefile=$2
    local sourcedir
    sourcedir=$(dirname "$(realpath "$sourcefile")")
    local tempdir="$sourcedir/tempZipDir"
    mkdir -p "$tempdir"
    cp "$sourcefile" "$tempdir"
    zip_files "$zipfilename" "$tempdir"
    rm -f "$tempdir/$(basename "$sourcefile")"
    rmdir "$tempdir"
}

mark_files_in_zip_as_readable_on_linux() {
    local zipfilename=$1
    zipinfo -1 "$zipfilename" | while IFS= read -r file; do
        zipnote -w "$zipfilename" <<< "@=$file
@unix_mode=0444"
    done > /dev/null
}

test_updater_file() {
    local file=$1
    [[ -f "$file" ]] && grep -qE '^plugin_version\s*=' "$file"
}

rm -rf dist
mkdir -p dist/{release,source/includes,ftp}

cp -r includes dist/source/

spcomp="spcomp64_original"
command -v "$spcomp" >/dev/null 2>&1 || spcomp="spcomp64"

plugins=("waitforstv" "medicstats" "supstats2" "logstf" "restorescore" "countdown" "fixstvslot" "pause" "recordstv" "classwarning" "afk")

for p in "${plugins[@]}"; do
    echo "Compiling $p..."
    "$spcomp" "$p.sp" -i ../includes -D "$p"

    if [[ $? -ne 0 ]]; then
        echo "Failed compilation of $p" >&2
        exit 1
    fi

    if ! test_updater_file "./$p/update.txt"; then
        echo "Failed validation of $p/update.txt" >&2
        exit 1
    fi

    mkdir -p "dist/ftp/$p/plugins"
    cp "$p/update.txt" "dist/ftp/$p/"
    cp "$p/$p.smx" "dist/ftp/$p/plugins/"
    cp "$p/$p.smx" "dist/release/"
    cp "$p/$p.sp" "dist/source/"

    if [[ -f "$p/$p.inc" ]]; then
        cp "$p/$p.inc" "dist/source/includes/"
    fi

    zip_file "dist/ftp/$p.zip" "$p/$p.smx"
done

zip_files "dist/ftp/f2-sourcemod-plugins.zip" "dist/release"
zip_files "dist/ftp/f2-sourcemod-plugins-src.zip" "dist/source"

echo "Finished successfully"
