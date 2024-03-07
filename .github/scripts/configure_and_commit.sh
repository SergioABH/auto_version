#!/bin/bash
set -e

echo "Configuring Git"
git config --global user.email "actions@github.com"
git config --global user.name "GitHub Actions"

# Función para obtener la versión de package.json de una rama
get_version_from_branch() {
    local branch_name=$1
    local package_version

    # Obtener la versión de package.json de la rama correspondiente
    if [[ $branch_name == 'dev' || $branch_name == 'qa' ]]; then
        package_version=$(git show $branch_name:package.json | jq -r .version)
    else
        package_version=$(node -pe "require('./package.json').version")
    fi

    echo $package_version
}

echo "Determining Version"
base_branch=$Determine_Version_BASE_BRANCH
branch_name=$Determine_Version_BRANCH_NAME
github_event_action=$github_event_action
github_event_pull_request_merged=$github_event_pull_request_merged

# Obtener las versiones de QA y DEV
qa_version=$(get_version_from_branch 'qa')
dev_version=$(get_version_from_branch 'dev')

if [[ $base_branch == 'qa' ]]; then
    if [[ $branch_name == 'dev' ]]; then
        if [[ $github_event_action == 'closed' && $github_event_pull_request_merged == 'true' ]]; then
            # Obtener las versiones de QA y DEV después de verificar el evento cerrado y fusionado
            qa_version=$(get_version_from_branch 'qa')
            dev_version=$(get_version_from_branch 'dev')

            # Extraer los componentes de versión
            qa_major=$(echo $qa_version | cut -d. -f1)
            qa_minor=$(echo $qa_version | cut -d. -f2)

            dev_major=$(echo $dev_version | cut -d. -f1)
            dev_minor=$(echo $dev_version | cut -d. -f2)

            # Comparar las versiones y actualizar según tus reglas
            if [[ $dev_major -eq $qa_major && $dev_minor -eq $qa_minor ]]; then
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
