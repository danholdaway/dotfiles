#!/bin/bash

# Get all files with merge conflicts
conflicted_files=$(git diff --name-only --diff-filter=U .)

# Loop through each conflicted file
for file in $conflicted_files; do
    echo "Checking file $file"
    # Check if incoming and current changes are identical
    if git diff -U0 -- $file | grep -q '<<<<<<<\|=======\|>>>>>>>'; then
        # Use a three-way merge to automatically resolve identical changes
        git merge-file -p "$file" "$file".BASE "$file".REMOTE > "$file".MERGED
        
        # Replace the original file with the merged result
        mv "$file".MERGED "$file"
        
        # Add the file back to the index
        git add "$file"
    fi
done

# Commit the resolved changes
#git commit -m "Auto-resolved identical merge conflicts"
