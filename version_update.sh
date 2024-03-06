#!/bin/bash

# Configure Git
echo "Configuring Git..."
git config --global user.email "actions@github.com"
git config --global user.name "GitHub Actions"

# Determine Version
echo "Determining version..."
base_branch=$(jq -r .pull_request.base.ref "$GITHUB_EVENT_PATH")
branch_name=$(jq -r .pull_request.head.ref "$GITHUB_EVENT_PATH")

if [[ $base_branch == 'qa' ]]; then
  if [[ $branch_name == 'dev' ]]; then
    if [[ "$GITHUB_EVENT_NAME" == 'pull_request' && "$GITHUB_EVENT_ACTION" == 'closed' && "$GITHUB_EVENT_PULL_REQUEST_MERGED" == 'true' ]]; then
      npm version prerelease --preid=beta
    fi
  elif [[ $branch_name == *fix/* ]]; then
    if [[ "$GITHUB_EVENT_NAME" == 'pull_request' && "$GITHUB_EVENT_ACTION" == 'closed' && "$GITHUB_EVENT_PULL_REQUEST_MERGED" == 'true' ]]; then
      npm version prepatch --preid=beta
    fi
  fi
elif [[ $base_branch == 'master' ]]; then
  if [[ $branch_name == 'qa' ]]; then
    if [[ "$GITHUB_EVENT_NAME" == 'pull_request' && "$GITHUB_EVENT_ACTION" == 'closed' && "$GITHUB_EVENT_PULL_REQUEST_MERGED" == 'true' ]]; then
      npm version minor
    fi
  elif [[ $branch_name == *fix/* ]]; then
    if [[ "$GITHUB_EVENT_NAME" == 'pull_request' && "$GITHUB_EVENT_ACTION" == 'closed' && "$GITHUB_EVENT_PULL_REQUEST_MERGED" == 'true' ]]; then
      npm version patch
    fi
  fi
fi

echo "::set-output name=base_branch::$base_branch"
echo "::set-output name=branch_name::$branch_name"

# Get New Version
echo "Getting new version..."
version=$(npm version)
echo "::set-output name=version::$version"

# Commit and Push Version Update
echo "Committing and pushing version update..."
git fetch origin $base_branch:$base_branch || true
git checkout $base_branch || true
git add .
git commit -am "Update version" || true
git checkout $base_branch
git push origin $base_branch --follow-tags || true

# Reintegrate Changes
echo "Reintegrating changes..."
if [[ "$GITHUB_EVENT_NAME" == 'pull_request' && "$GITHUB_EVENT_ACTION" == 'closed' && "$GITHUB_EVENT_PULL_REQUEST_MERGED" == 'true' && "$GITHUB_EVENT_PULL_REQUEST_BASE_REF" == "$base_branch" ]]; then
  version=$(git describe --tags --abbrev=0 $(git rev-list --tags --max-count=1 $base_branch))
  reintegrate_branch="reintegrate/$version"

  git fetch origin $base_branch
  git checkout -b $reintegrate_branch $base_branch
  git push origin $reintegrate_branch

  PR_TITLE="Reintegrate $version to $branch_name"

  curl -X POST \
    -H "Authorization: Bearer $GH_TOKEN" \
    -d '{"title":"'"$PR_TITLE"'","head":"'"$reintegrate_branch"'","base":"'"$branch_name"'"}' \
    "https://api.github.com/repos/$GITHUB_REPOSITORY/pulls"
fi
