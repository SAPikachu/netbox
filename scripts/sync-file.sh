#!/bin/bash

dry_run=""

if [ "$1" == "--dry-run" ]; then
    dry_run='echo '
    shift
fi

$dry_run remountrw
# $dry_run auplink / flush
tmp_dir=/run/sync-file-tmp


while (($#)); do
    full_path=`python -c "import os; print os.path.abspath('$1')"`
    dir=$(readlink -m $(dirname "$full_path"))
    base=$(basename "$full_path")

    # we need to copy to a temporary location first, otherwise the file may be truncated
    $dry_run mkdir $tmp_dir
    $dry_run cp -arf "$1" "$tmp_dir/$base"
    # $dry_run mkdir -p "/rw$dir"
    # $dry_run cp -rf "$tmp_dir/$base" "/rw$dir"
    $dry_run mkdir -p "/ro$dir"
    
    # Need to copy back first, otherwise it will cause "orphan inode" error after syncing symbolic links, and no further syncing is possible until next boot
    $dry_run cp -arf "$tmp_dir/$base" "$dir"

    $dry_run cp -arf "$tmp_dir/$base" "/ro$dir"
    $dry_run rm -rf $tmp_dir
    
    shift
done

$dry_run sync
# $dry_run auplink / flush
$dry_run sync
$dry_run remountro
$dry_run sync
