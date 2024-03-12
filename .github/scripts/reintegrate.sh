#!/bin/bash

GITHUB_EVENT_ACTION="$1"
GITHUB_REPOSITORY="$2"
GH_TOKEN="$3"

base_branch=$(jq -r .pull_request.base.ref "$GITHUB_EVENT_PATH")
branch_name=$(jq -r .pull_request.head.ref "$GITHUB_EVENT_PATH")

create_branch_and_pr() {
  echo "Debug: Starting create_branch_and_pr function"
  echo "Debug: base_branch is $base_branch"
  if [[ $GITHUB_EVENT_ACTION == 'closed' && $(jq -r '.pull_request.merged' "$GITHUB_EVENT_PATH") == 'true' && $(jq -r '.pull_request.base.ref' "$GITHUB_EVENT_PATH") == 'master' ]]; then
    echo "Debug: Branch is master"
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
    echo "Debug: Branch is not master"
  fi
}

# Llama a la función para obtener las ramas
create_branch_and_pr
