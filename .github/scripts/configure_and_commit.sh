#!/bin/bash
set -e

echo "Configurando Git"
git config --global user.email "actions@github.com"
git config --global user.name "GitHub Actions"

get_minor_version_from_branch() {
  local branch_name=$1
  local package_version

  if [[ $branch_name == 'dev' || $branch_name == 'qa' ]]; then
    package_version=$(git show $branch_name:package.json | jq -r .version)
  else
    package_version=$(node -pe "require('./package.json').version")  
  fi

  minor_version=$(echo $package_version | cut -d. -f2)

  echo $minor_version
}

compare_versions() {
  local dev_minor=$1
  local qa_minor=$2

  if [[ $dev_minor -gt $qa_minor ]]; then
    npm --no-git-tag-version version preminor --preid=beta
  else
    npm --no-git-tag-version version prerelease --preid=beta
  fi
}

echo "Determinando versión"
base_branch=$Determine_Version_BASE_BRANCH
branch_name=$Determine_Version_BRANCH_NAME
github_event_action=$github_event_action
github_event_pull_request_merged=$github_event_pull_request_merged

if [[ $base_branch == 'qa' ]]; then
  if [[ $branch_name == 'dev' ]]; then
    if [[ $github_event_action == 'closed' && $github_event_pull_request_merged == 'true' ]]; then
      qa_minor=$(get_minor_version_from_branch 'qa')
      dev_minor=$(get_minor_version_from_branch 'dev')

      compare_versions $dev_minor $qa_minor
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

echo "Obteniendo nueva versión"
version=$(npm version)

echo "Rama base: $base_branch"
echo "Nombre de la rama: $branch_name"
echo "Versión: $version"

git fetch origin $base_branch:$base_branch || true
git checkout $base_branch || true

git add .
git commit -am "Actualizar versión" || true
git checkout $base_branch
git push origin $base_branch --follow-tags || true
