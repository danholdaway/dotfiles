#!/usr/bin/env bash

# Get list of Git repos
repos=`ls -d -- */.git | cut -d/ -f1`

GR='\033[0;32m'
NC='\033[0m'

for repo in $repos
do
    cd $repo
    branch=`git rev-parse --abbrev-ref HEAD`
    printf "Git pull for $repo on branch ${GR}$branch${NC}\n"
    git pull
    printf "\n"
    cd ..
done
