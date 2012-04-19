#!/bin/bash

dry_run=""

if [ "$1" == "--dry-run" ]; then
    dry_run='echo '
    shift
fi

$dry_run remountrw

tmp_dir=/tmp/sync-file-tmp


while (($#)); do
    full_path=$(readlink -m "$1")
    dir=$(dirname "$full_path")
    base=$(basename "$full_path")

    # we need to copy to a temporary location first, otherwise the file may be truncated
    $dry_run mkdir $tmp_dir
    $dry_run cp -rf "$1" "$tmp_dir/$base"
    # $dry_run mkdir -p "/rw$dir"
    # $dry_run cp -rf "$tmp_dir/$base" "/rw$dir"
    $dry_run mkdir -p "/ro$dir"
    $dry_run cp -rf "$tmp_dir/$base" "/ro$dir"
    $dry_run rm -rf $tmp_dir
    
    shift
done

$dry_run sync
$dry_run sync
$dry_run remountro
$dry_run sync
