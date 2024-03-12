#!/bin/bash

base_branch="$1"
branch_name="$2"
GH_TOKEN="$3"

create_branch_and_pr() {
  echo "Debug: Starting create_branch_and_pr function"
  if [ "$base_branch" == 'master' ]; then
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
