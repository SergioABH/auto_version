#!/bin/bash

GITHUB_EVENT_ACTION="$1"
GITHUB_REPOSITORY="$2"
GH_TOKEN="$3"

base_branch=$(jq -r .pull_request.base.ref "$GITHUB_EVENT_PATH")
branch_name=$(jq -r .pull_request.head.ref "$GITHUB_EVENT_PATH")

create_branch_and_pr() {
  if [[ $GITHUB_EVENT_ACTION == 'closed' && \
        $(jq -r '.pull_request.merged' "$GITHUB_EVENT_PATH") == 'true' && \
        $(jq -r '.pull_request.base.ref' "$GITHUB_EVENT_PATH") == 'master' ]]; then
    version=$(git describe --tags --abbrev=0 $(git rev-list --tags --max-count=1 master))
    reintegrate_branch="reintegrate/$version"

    git config --global user.email "actions@github.com"
    git config --global user.name "GitHub Actions"

    git fetch origin master
    git checkout -b "$reintegrate_branch" master
    git push origin "$reintegrate_branch"

    PR_TITLE="Reintegrate $version to dev"
    curl -X POST \
      -H "Authorization: Bearer $GH_TOKEN" \
      -d '{"title":"'"$PR_TITLE"'","head":"'"$reintegrate_branch"'","base":"dev"}' \
      "https://api.github.com/repos/$GITHUB_REPOSITORY/pulls"
  else
    echo "Branch is not master"
  fi
}

# Main script
create_branch_and_pr
