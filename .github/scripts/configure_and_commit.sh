#!/bin/bash
set -e

echo "Configuring Git"
git config --global user.email "actions@github.com"
git config --global user.name "GitHub Actions"

echo "Determining Version"
Determine_Version_BASE_BRANCH=$(jq -r .pull_request.base.ref $GITHUB_EVENT_PATH)
Determine_Version_BRANCH_NAME=$(jq -r .pull_request.head.ref $GITHUB_EVENT_PATH)

echo "Determine_Version_BASE_BRANCH=$Determine_Version_BASE_BRANCH" >> $GITHUB_ENV
echo "Determine_Version_BRANCH_NAME=$Determine_Version_BRANCH_NAME" >> $GITHUB_ENV
echo "github_event_action=${{ github.event.action }}" >> $GITHUB_ENV
echo "github_event_pull_request_merged=${{ github.event.pull_request.merged }}" >> $GITHUB_ENV

if [[ $Determine_Version_BASE_BRANCH == 'qa' ]]; then
    if [[ $Determine_Version_BRANCH_NAME == 'dev' ]]; then
        if [[ $github_event_action == 'closed' && $github_event_pull_request_merged == 'true' ]]; then
            npm --no-git-tag-version version prerelease --preid=beta
        fi
    elif [[ $Determine_Version_BRANCH_NAME == *fix/* ]]; then
        if [[ $github_event_action == 'closed' && $github_event_pull_request_merged == 'true' ]]; then
            npm version prepatch --preid=beta
        fi
    fi
elif [[ $Determine_Version_BASE_BRANCH == 'master' ]]; then
    if [[ $Determine_Version_BRANCH_NAME == 'qa' ]]; then
        if [[ $github_event_action == 'closed' && $github_event_pull_request_merged == 'true' ]]; then
            npm version minor
        fi
    elif [[ $Determine_Version_BRANCH_NAME == *fix/* ]]; then
        if [[ $github_event_action == 'closed' && $github_event_pull_request_merged == 'true' ]]; then
            npm version patch
        fi
    fi
fi

echo "Getting New Version"
version=$(npm version)

echo "Base branch: $Determine_Version_BASE_BRANCH"
echo "Branch name: $Determine_Version_BRANCH_NAME"
echo "Version: $version"

git fetch origin $Determine_Version_BASE_BRANCH:$Determine_Version_BASE_BRANCH || true
git checkout $Determine_Version_BASE_BRANCH || true

git add .
git commit -am "Update version" || true
git checkout $Determine_Version_BASE_BRANCH
git push origin $Determine_Version_BASE_BRANCH --follow-tags || true

echo "Reintegrating Changes"
if [[ $github_event_action == 'closed' && $github_event_pull_request_merged == 'true' && $github_event_pull_request_base_ref == 'master' ]]; then

    version=$(git describe --tags --abbrev=0 $(git rev-list --tags --max-count=1 master))
    reintegrate_branch="reintegrate/$version"

    git fetch origin master
    git checkout -b $reintegrate_branch master
    git push origin $reintegrate_branch

    PR_TITLE="Reintegrate $version to dev"

    curl -X POST \
        -H "Authorization: Bearer $GH_TOKEN" \
        -d '{"title":"'"$PR_TITLE"'","head":"'"$reintegrate_branch"'","base":"dev"}' \
        "https://api.github.com/repos/$GITHUB_REPOSITORY/pulls"
fi
