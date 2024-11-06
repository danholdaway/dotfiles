# Sitting on branch feature/work of fork (origin)

export branch=feature/work
export repo=gdasapp
export org=NOAA-EMC

# Add the upstream to get develop
git remote add upstream https://github.com/${org}/${repo}
git fetch upstream

# From your branch
git merge --no-commit --no-ff upstream/develop
git submodule update --init --recursive
git commit

