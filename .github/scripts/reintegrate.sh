#!/bin/bash

base_branch="$1"
branch_name="$2"
version="$3"
GH_TOKEN="$4"

# Your reintegrate logic here
if [ "$base_branch" == 'master' ]; then
  reintegrate_branch="reintegrate/$version"

  git fetch origin master
  git checkout -b "$reintegrate_branch" master
  git push origin "$reintegrate_branch"

  PR_TITLE="Reintegrate $version to dev"

  curl -X POST \
    -H "Authorization: Bearer $GH_TOKEN" \
    -d '{"title":"'"$PR_TITLE"'","head":"'"$reintegrate_branch"'","base":"dev"}' \
    "https://api.github.com/repos/$GITHUB_REPOSITORY/pulls"
fi
