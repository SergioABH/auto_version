#!/bin/bash

base_branch="$1"
branch_name="$2"
GH_TOKEN="$3"

create_branch() {
    if [ "$base_branch" == 'master' ]; then
    version=$(git describe --tags --abbrev=0 $(git rev-list --tags --max-count=1 master))
    reintegrate_branch="reintegrate/$version"
    git config --global user.email "actions@github.com"
    git config --global user.name "GitHub Actions"
    git fetch origin master
    git checkout -b "$reintegrate_branch" master
    git push origin "$reintegrate_branch"
}

craete_pull_request() {
    PR_TITLE="Reintegrate $version to dev"
    curl -X POST \
        -H "Authorization: Bearer $GH_TOKEN" \
        -d '{"title":"'"$PR_TITLE"'","head":"'"$reintegrate_branch"'","base":"dev"}' \
        "https://api.github.com/repos/$GITHUB_REPOSITORY/pulls"
    fi
}
