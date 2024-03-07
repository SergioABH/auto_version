#!/bin/bash
set -e

echo "Configuring Git"
git config --global user.email "actions@github.com"
git config --global user.name "GitHub Actions"

echo "Determining Version"
base_branch=$Determine_Version_BASE_BRANCH
branch_name=$Determine_Version_BRANCH_NAME
github_event_action=$github_event_action
github_event_pull_request_merged=$github_event_pull_request_merged

if [[ $base_branch == 'qa' ]]; then
    if [[ $branch_name == 'dev' ]]; then
        if [[ $github_event_action == 'closed' && $github_event_pull_request_merged == 'true' ]]; then
            npm --no-git-tag-version version prerelease --preid=beta
        fi
    elif [[ $branch_name == *fix/* ]]; then
        if [[ $github_event_action == 'closed' && $github_event_pull_request_merged == 'true' ]]; then
            npm version prepatch --preid=beta
        fi
    fi
elif [[ $base_branch == 'master' ]]; then
    if [[ $branch_name == 'qa' ]]; then
        if [[ $github_event_action == 'closed' && $github_event_pull_request_merged == 'true' ]]; then
            npm version minor
        fi
    elif [[ $branch_name == *fix/* ]]; then
        if [[ $github_event_action == 'closed' && $github_event_pull_request_merged == 'true' ]]; then
            npm version patch
        fi
    fi
fi

echo "Getting New Version"
version=$(npm version)

echo "Base branch: $base_branch"
echo "Branch name: $branch_name"
echo "Version: $version"

git fetch origin $base_branch:$base_branch || true
git checkout $base_branch || true

git add .
git commit -am "Update version" || true
git checkout $base_branch
git push origin $base_branch --follow-tags || true

echo "Reintegrate Changes"
if [[ $GITHUB_EVENT_NAME == 'pull_request' && $github_event_action == 'closed' && $github_event_pull_request_merged == 'true' && $GITHUB_EVENT_PULL_REQUEST_BASE_REF == 'master' ]]; then

    version=$(git describe --tags --abbrev=0 $(git rev-list --tags --max-count=1 master))
    reintegrate_branch="reintegrate/$version"
    
    git fetch origin master
    git checkout -b $reintegrate_branch master
    git push origin $reintegrate_branch

    PR_TITLE="Reintegrate $version to dev"

    curl -X POST \
        -H "Authorization: Bearer $GH_TOKEN" \
        -d "{\"title\":\"$PR_TITLE\",\"head\":\"$reintegrate_branch\",\"base\":\"dev\"}" \
        "https://api.github.com/repos/$GITHUB_REPOSITORY/pulls"

    echo "Pull request created successfully"
fi
