#!/bin/bash
set -e

echo "Configurando Git"
git config --global user.email "actions@github.com"
git config --global user.name "GitHub Actions"

# Función para obtener las versiones minor de package.json de las ramas 'qa' y 'dev'
get_minor_version_from_branches() {
  local qa_minor_version dev_minor_version

  # Obtain the minor version from the 'qa' branch
  qa_minor_version=$(git show qa:package.json | jq -r .version | cut -d. -f2)

  # Obtain the minor version from the 'dev' branch
  dev_minor_version=$(git show dev:package.json | jq -r .version | cut -d. -f2)

  echo "qa minor version: $qa_minor_version"
  echo "dev minor version: $dev_minor_version"
}

echo "Determinando versión"
base_branch=$Determine_Version_BASE_BRANCH
branch_name=$Determine_Version_BRANCH_NAME
github_event_action=$github_event_action
github_event_pull_request_merged=$github_event_pull_request_merged

# Obtain the minor versions of 'qa' and 'dev' branches
qa_minor_version=$(get_minor_version_from_branches | grep "qa minor version:" | awk '{print $3}')
dev_minor_version=$(get_minor_version_from_branches | grep "dev minor version:" | awk '{print $3}')

if [[ $base_branch == 'qa' ]]; then
  if [[ $branch_name == 'dev' ]]; then
    if [[ $github_event_action == 'closed' && $github_event_pull_request_merged == 'true' ]]; then
      # Comparar las versiones minor
      if [[ $dev_minor_version -eq $qa_minor_version ]]; then
        npm --no-git-tag-version version preminor --preid=beta
      else
        npm --no-git-tag-version version prerelease --preid=beta
      fi
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
