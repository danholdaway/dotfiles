#!/usr/bin/env bash

# Get list of Git repos
repos=`ls -d -- */.git | cut -d/ -f1`

GR='\033[0;32m'
NC='\033[0m'

for repo in $repos
do
    cd $repo
    echo $repo
    git branch
    printf "\n"
    cd ..
done
