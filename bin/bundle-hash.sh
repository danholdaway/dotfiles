#!/usr/bin/env bash

# Get list of Git repos
repos=`ls -d -- */.git | cut -d/ -f1`

GR='\033[0;32m'
NC='\033[0m'

for repo in $repos
do
    cd $repo
    hash=`git rev-parse --short HEAD`
    printf "Hash for $repo: ${GR}$hash${NC}\n"
    printf "\n"
    cd ..
done
