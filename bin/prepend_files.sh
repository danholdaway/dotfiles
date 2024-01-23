#!/bin/bash

# Check if the prefix argument is provided
if [ $# -ne 1 ]; then
  echo "Usage: $0 <prefix>"
  exit 1
fi

# Extract the prefix from the command-line argument
prefix="$1"

# Use the current directory as the target directory
directory="./"

# Navigate to the directory
cd "$directory" || exit

# Loop through all files in the directory
for file in *; do
  # Check if the file is a regular file (not a directory or symlink)
  if [[ -f "$file" ]]; then
    # Rename the file with the prefix added to the beginning
    new_name="${prefix}${file}"
    mv "$file" "$new_name"
    echo "Renamed: $file to $new_name"
  fi
done
