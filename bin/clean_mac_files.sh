#!/bin/bash

# Use the find command to locate files starting with "._" in subdirectories
find "./" -type f -name "._*" -exec rm -f {} \;
find "./" -type f -name ".DS_Store" -exec rm -f {} \;

