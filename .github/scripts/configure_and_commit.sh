#!/bin/bash
set -e

echo "Configurando Git"
git config --global user.email "actions@github.com"
git config --global user.name "GitHub Actions"

echo "Determinando versión"
base_branch=$Determine_Version_BASE_BRANCH
branch_name=$Determine_Version_BRANCH_NAME
github_event_action=$github_event_action
github_event_pull_request_merged=$github_event_pull_request_merged

# Función para obtener la versión minor de package.json de una rama
get_minor_version_from_branch() {
  local branch_name=$1
  local package_version

  # Obtener la versión de package.json de la rama correspondiente
  if [[ $branch_name == 'dev' || $branch_name == 'qa' ]]; then
    package_version=$(git show $branch_name:package.json | jq -r .version)
  else
    package_version=$(node -pe "require('./package.json').version")  # Use for local branch or non-existent remote branch
  fi

  # Extraer la versión minor
  minor_version=$(echo $package_version | cut -d. -f2)

  echo $minor_version
}

# Obtener las versiones minor de QA y DEV
qa_minor=$(get_minor_version_from_branch 'qa')
dev_minor=$(get_minor_version_from_branch 'dev')

if [[ $base_branch == 'qa' ]]; then
  if [[ $branch_name == 'dev' ]]; then
    if [[ $github_event_action == 'closed' && $github_event_pull_request_merged == 'true' ]]; then
      # Obtener las versiones minor después de verificar el evento cerrado y fusionado
      qa_minor=$(get_minor_version_from_branch 'qa')
      dev_minor=$(get_minor_version_from_branch 'dev')

      # Comparar las versiones minor
      if [[ $dev_minor -gt $qa_minor ]]; then
        # Si la versión minor de DEV es mayor, actualizar a la siguiente versión minor
        npm --no-git-tag-version version minor --preid=beta
      elif [[ $dev_minor -eq $qa_minor ]]; then
        # Si las versiones minor son iguales, actualizar el pre-release
        npm --no-git-tag-version version preminor --preid=beta
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
