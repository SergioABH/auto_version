#!/bin/bash
set -e

echo "Reintegrating Changes"
if [[ $GITHUB_EVENT_NAME == 'pull_request' && $GITHUB_EVENT_ACTION == 'closed' && $GITHUB_EVENT_PULL_REQUEST_MERGED == 'true' && $GITHUB_EVENT_PULL_REQUEST_BASE_REF == 'master' ]]; then

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
        -d "{\"title\":\"$PR_TITLE\",\"head\":\"$reintegrate_branch\",\"base\":\"dev\"}" \
        "https://api.github.com/repos/$GITHUB_REPOSITORY/pulls"
fi
