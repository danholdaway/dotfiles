#!/usr/bin/env bash

# Get list of Git repos
repos=`ls -d -- */.git | cut -d/ -f1`

GR='\033[0;32m'
NC='\033[0m'

for repo in $repos
do
    printf "Fetching infomration for $repo ...\n"
    cd $repo
    printf "\n"
    branch=`git rev-parse --abbrev-ref HEAD`
    printf "  Branch: ${GR}$branch${NC}\n"
    printf "\n"
    cd ..
done
