#!/bin/bash
set -e

echo "Configuring Git"
git config --global user.email "actions@github.com"
git config --global user.name "GitHub Actions"

echo "Determining Version"
base_branch=$(jq -r .pull_request.base.ref $GITHUB_EVENT_PATH)
branch_name=$(jq -r .pull_request.head.ref $GITHUB_EVENT_PATH)

if [[ $base_branch == 'qa' ]]; then
    if [[ $branch_name == 'dev' ]]; then
        if [[ ${{ github.event.action }} == 'closed' && ${{ github.event.pull_request.merged }} == 'true' ]]; then
            npm --no-git-tag-version version prerelease --preid=beta
        fi
    elif [[ $branch_name == *fix/* ]]; then
        if [[ ${{ github.event.action }} == 'closed' && ${{ github.event.pull_request.merged }} == 'true' ]]; then
            npm version prepatch --preid=beta
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

echo "::set-output name=base_branch::$base_branch"
echo "::set-output name=branch_name::$branch_name"

echo "Getting New Version"
echo "::set-output name=version::$(npm version)"

echo "Committing and Pushing Version Update"
base_branch=${{ steps.determine_version.outputs.base_branch }}
branch_name=${{ steps.determine_version.outputs.branch_name }}
version=${{ steps.get_version.outputs.version }}

echo "Base branch: $base_branch"
echo "Branch name: $branch_name"
echo "Version: $version"

git fetch origin $base_branch:$base_branch || true
git checkout $base_branch || true

git add .
git commit -am "Update version" || true
git checkout $base_branch
git push origin $base_branch --follow-tags || true
