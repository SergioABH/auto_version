#!/bin/bash
set -e

echo "Reintegrate Changes"
base_branch=$Determine_Version_BASE_BRANCH
branch_name=$Determine_Version_BRANCH_NAME
github_event_action=$github_event_action
github_event_pull_request_merged=$github_event_pull_request_merged
github_event_name=$github_event_name
github_event_pull_request_base_ref=$github_event_pull_request_base_ref

if [[ $github_event_name == 'pull_request' && $github_event_action == 'closed' && $github_event_pull_request_merged == 'true' && $github_event_pull_request_base_ref == 'master' ]]; then

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
