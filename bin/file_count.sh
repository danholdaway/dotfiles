#!/bin/bash

directories=($(ls -d */))

for dir in "${directories[@]}"; do
    echo "Directory: $dir"
    cd $dir
    find . -type f | wc -l
    cd ..
done
