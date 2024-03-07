#!/bin/bash
set -e

echo "Reintegrating Changes"
if [[ $github_event_action == 'closed' && $github_event_pull_request_merged == 'true' && $github_event_pull_request_base_ref == 'master' ]]; then

    version=$(git describe --tags --abbrev=0 $(git rev-list --tags --max-count=1 master))
    reintegrate_branch="reintegrate/$version"
    
    git config --global user.email "actions@github.com"
    git config --global user.name "GitHub Actions"
    git fetch origin master
    git checkout -b $reintegrate_branch master
    git push origin $reintegrate_branch

    PR_TITLE="Reintegrate $version to dev"

    curl -X POST \
        -H "Authorization: Bearer $GH_TOKEN" \
        -d '{"title":"'"$PR_TITLE"'","head":"'"$reintegrate_branch"'","base":"dev"}' \
        "https://api.github.com/repos/$GITHUB_REPOSITORY/pulls"
fi
