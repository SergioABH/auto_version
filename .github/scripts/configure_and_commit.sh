#!/bin/bash

GITHUB_EVENT_ACTION="$1"
GITHUB_REPOSITORY="$2"
GH_TOKEN="$3"

configure_git() {
  git config --global user.email "actions@github.com"
  git config --global user.name "GitHub Actions"
}

get_branches() {
  base_branch=$(jq -r .pull_request.base.ref "$GITHUB_EVENT_PATH")
  branch_name=$(jq -r .pull_request.head.ref "$GITHUB_EVENT_PATH")
}

evaluate_and_set_version() {
  if [[ $GITHUB_EVENT_ACTION == 'closed' && $(jq -r '.pull_request.merged' "$GITHUB_EVENT_PATH") == 'true' ]]; then
    case "$base_branch-$branch_name" in
      'qa-dev')   evaluate_dev_version ;;
      'master-qa') npm version minor && create_tag ;;
      'master-fix'*) npm version patch && create_tag ;;
      *) echo "Error: Invalid event or branch combination." >&2 ;;
    esac
  else
    echo "Invalid event. No action determined."
  fi
}

evaluate_dev_version() {
    dev_version=$(git show origin/dev:package.json | jq -r .version)
    dev_minor=$(echo "$dev_version" | cut -d. -f2)
    echo "Versión minor dev: $dev_minor"

    qa_version=$(git show refs/heads/qa:package.json | jq -r .version)
    qa_minor=$(echo "$qa_version" | cut -d. -f2)
    echo "Versión minor qa: $qa_minor"

    if [[ $dev_minor == $qa_minor ]]; then
      npm --no-git-tag-version version preminor --preid=beta
    else
      npm --no-git-tag-version version prerelease --preid=beta
    fi
}

create_tag() {
  version=$(npm version)
  git tag -a "$version" -m "Release $version"
  git push origin "$version"
}

set_outputs() {
  echo "::set-output name=base_branch::$base_branch"
  echo "::set-output name=branch_name::$branch_name"
  version=$(npm version)
  echo "::set-output name=version::$version"
}

commit_and_push_version_update() {
  echo "Base branch: $base_branch"
  echo "Branch name: $branch_name"
  git fetch origin "$base_branch":"$base_branch" || true
  git checkout "$base_branch" || true
  git add .
  git commit -am "Update version" || true
  git checkout "$base_branch"
  git push origin "$base_branch" --follow-tags || true
}

# Main script
configure_git
get_branches
evaluate_and_set_version
set_outputs
commit_and_push_version_update
