#!/bin/bash
set -e

echo "Reintegrating Changes"
if [[ ${{ github.event.action }} == 'closed' && ${{ github.event.pull_request.merged }} == 'true' && ${{ github.event.pull_request.base.ref }} == 'master' ]]; then

    version=$(git describe --tags --abbrev=0 $(git rev-list --tags --max-count=1 master))
    reintegrate_branch="reintegrate/$version"

    git fetch origin master
    git checkout -b $reintegrate_branch master
    git push origin $reintegrate_branch

    PR_TITLE="Reintegrate $version to dev"

    curl -X POST \
        -H "Authorization: Bearer ${{ secrets.GH_TOKEN }}" \
        -d '{"title":"'"$PR_TITLE"'","head":"'"$reintegrate_branch"'","base":"dev"}' \
        "https://api.github.com/repos/${{ github.repository }}/pulls"
fi
