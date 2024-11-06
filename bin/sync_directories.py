#!/usr/bin/env python3

import click
import subprocess
import argparse
from datetime import datetime

def get_file_info_from_find(dir_path):
    """
    Runs a `find` command to get file paths, sizes, and modification times.
    Returns a dictionary with relative paths as keys and file info (size, mtime) as values.
    """
    file_info = {}
    # Run find command to get all files with size and modification time
    result = subprocess.run(
        ["find", dir_path, "-type", "f", "-exec", "ls", "-l", "{}", ";"],
        capture_output=True, text=True, check=True
    )

    for line in result.stdout.splitlines():
        parts = line.split()
        # Parse the output format of `ls -l`
        if len(parts) >= 9:
            size = int(parts[4])
            mtime_str = " ".join(parts[5:8])
            mtime = datetime.strptime(mtime_str, "%b %d %H:%M")
            full_path = " ".join(parts[8:])
            rel_path = full_path[len(dir_path):].lstrip("/")
            file_info[rel_path] = {'size': size, 'mtime': mtime, 'path': full_path}

    return file_info

def compare_directories(ref_dir, trg_dir):
    # Get file info from both directories
    files_ref_dir = get_file_info_from_find(ref_dir)
    files_trg_dir = get_file_info_from_find(trg_dir)

    identical_files = []
    only_in_ref_dir = []
    only_in_trg_dir = []
    different_files = []

    # Files only in ref_dir
    for rel_path in files_ref_dir.keys() - files_trg_dir.keys():
        only_in_ref_dir.append(rel_path)

    # Files only in trg_dir
    for rel_path in files_trg_dir.keys() - files_ref_dir.keys():
        only_in_trg_dir.append(rel_path)

    # Files in both directories
    for rel_path in files_ref_dir.keys() & files_trg_dir.keys():
        file1_info = files_ref_dir[rel_path]
        file2_info = files_trg_dir[rel_path]

        # Compare size and modification time for identical check
        if file1_info['size'] == file2_info['size'] and file1_info['mtime'] == file2_info['mtime']:
            identical_files.append(rel_path)
        else:
            different_files.append(rel_path)

    return identical_files, only_in_ref_dir, only_in_trg_dir, different_files

@click.command()
@click.argument('ref_dir', type=click.Path(exists=True, file_okay=False), required=True)
@click.argument('trg_dir', type=click.Path(exists=True, file_okay=False), required=True)
@click.option('--dry_run', is_flag=True, help="If set, the script will only produce prints.")
def main(ref_dir, trg_dir, dry_run):

    """
    Compare and optionally synchronize two directories.

    REF_DIR: Path to the reference directory.

    TRG_DIR: Path to the target directory.
    """
    click.echo(f"This utility will compare two directories.")
    click.echo(f" ")
    click.echo(f"  Reference directory: {ref_dir}")
    click.echo(f"  Target directory: {trg_dir}")
    dry_run_msg = ""
    if dry_run:
        click.echo(f"  Dry run mode: enabled, no changes will be made.")
        dry_run_msg = "(dry run, no action) "
    click.echo(f" ")

    identical_files, only_in_ref_dir, only_in_trg_dir, different_files = compare_directories(ref_dir, trg_dir)

    # If a file is only in trg_dir then remove it
    if only_in_trg_dir:
        print("The following files are only in the target directory and so will be removed:\n")
        for file in only_in_trg_dir:
            print(" - " + dry_run_msg + f"removing {file}")
            if not dry_run:
                subprocess.run(["rm", trg_dir + "/" + file])
        print(" ")

    if only_in_ref_dir:
        print("The following files are only in the reference directory so are copied:\n")
        for file in only_in_ref_dir:
            print(" - " + dry_run_msg + f"copying {file}")
            if not dry_run:
                subprocess.run(["cp", "-p", ref_dir + "/" + file, trg_dir + "/" + file])
        print(" ")

    if different_files:
        print("The following files are in both but are different, overwriting from reference to target:\n")
        for file in different_files:
            print(" - " + dry_run_msg + f"copying {file}")
            if not dry_run:
                subprocess.run(["rm", trg_dir + "/" + file])
                subprocess.run(["cp", "-p", ref_dir + "/" + file, trg_dir + "/" + file])
        print(" ")

    if identical_files:
        print("The following files are identical between directories:\n")
        for file in identical_files:
            print(f" - {file}")
        print(" ")

if __name__ == "__main__":
    main()
