#!/bin/bash

base_branch=$(jq -r .pull_request.base.ref $GITHUB_EVENT_PATH)
branch_name=$(jq -r .pull_request.head.ref $GITHUB_EVENT_PATH)

if [[ $base_branch == 'dev' ]]; then
    if [[ $branch_name == *feat/* ]]; then
        if [[ ${{ github.event.action }} == 'closed' && ${{ github.event.pull_request.merged }} == 'true' ]]; then
        npm version prerelease --preid=alpha
        fi
    elif [[ $branch_name == *reintegrate/* ]]; then
        if [[ ${{ github.event.action }} == 'closed' && ${{ github.event.pull_request.merged }} == 'true' ]]; then
        new_version=$(npm --no-git-tag-version version minor)
        new_version="${new_version}-alpha.0"
        fi
    fi

elif [[ $base_branch == 'qa' ]]; then
    if [[ $branch_name == 'dev' ]]; then
        if [[ ${{ github.event.action }} == 'closed' && ${{ github.event.pull_request.merged }} == 'true' ]]; then
        npm version prerelease --preid=beta
        fi
    elif [[ $branch_name == *fix/* ]]; then
        if [[ ${{ github.event.action }} == 'closed' && ${{ github.event.pull_request.merged }} == 'true' ]]; then
        npm version patch
        fi
    fi

elif [[ $base_branch == 'master' ]]; then
    if [[ $branch_name == 'qa' ]]; then
        if [[ ${{ github.event.action }} == 'closed' && ${{ github.event.pull_request.merged }} == 'true' ]]; then
        npm version minor
        fi
    elif [[ $branch_name == *fix/* ]]; then
        if [[ ${{ github.event.action }} == 'closed' && ${{ github.event.pull_request.merged }} == 'true' ]]; then
        npm version patch
        fi
    fi
fi

new_version=$(npm version)
echo "New Version: $new_version"

echo "Base branch: $base_branch"
echo "Branch name: $branch_name"
echo "Version: $version"

git fetch origin $base_branch:$base_branch || true
git checkout $base_branch || true
git add .
git commit -am "Update version" || true
git checkout $base_branch
git push origin $base_branch --follow-tags || true

if [[ ${{ github.event.action }} == 'closed' && ${{ github.event.pull_request.merged }} == 'true' && ${{ github.event.pull_request.base.ref }} == 'master' && ${{ github.event.pull_request.head.ref }} == *'hotfix'* ]]; then
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