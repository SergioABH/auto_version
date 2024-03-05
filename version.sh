#!/bin/bash

# Obtener las ramas base y de la pull request
base_branch=$(jq -r .pull_request.base.ref $GITHUB_EVENT_PATH)
branch_name=$(jq -r .pull_request.head.ref $GITHUB_EVENT_PATH)

# Función para manejar la versión en base a las condiciones dadas
handle_version() {
    if [[ $1 == 'closed' && $2 == 'true' ]]; then
        npm version $3
    fi
}

# Función para reintegrar cambios
reintegrate_changes() {
    if [[ $1 == 'closed' && $2 == 'true' && $3 == 'master' && $4 == *'hotfix'* ]]; then
        version=$(git describe --tags --abbrev=0 $(git rev-list --tags --max-count=1 master))
        reintegrate_branch="reintegrate/$version"

        git fetch origin master
        git checkout -b $reintegrate_branch master
        git push origin $reintegrate_branch

        PR_TITLE="Reintegrate $version to dev"

        curl -X POST \
            -H "Authorization: Bearer $GITHUB_TOKEN" \
            -d '{"title":"'"$PR_TITLE"'","head":"'"$reintegrate_branch"'","base":"dev"}' \
            "https://api.github.com/repos/${GITHUB_REPOSITORY}/pulls"
    fi
}

# Actualizar versión según las condiciones
if [[ $base_branch == 'dev' ]]; then
    if [[ $branch_name == *feat/* ]]; then
        handle_version "${GITHUB_EVENT.action}" "${GITHUB_EVENT.pull_request.merged}" "prerelease --preid=alpha"
    elif [[ $branch_name == *reintegrate/* ]]; then
        handle_version "${GITHUB_EVENT.action}" "${GITHUB_EVENT.pull_request.merged}" "--no-git-tag-version version minor"
        npm version prerelease --preid=alpha --force
    fi

elif [[ $base_branch == 'qa' ]]; then
    if [[ $branch_name == 'dev' ]]; then
        handle_version "${GITHUB_EVENT.action}" "${GITHUB_EVENT.pull_request.merged}" "prerelease --preid=beta"
    elif [[ $branch_name == *fix/* ]]; then
        handle_version "${GITHUB_EVENT.action}" "${GITHUB_EVENT.pull_request.merged}" "version patch"
    fi

elif [[ $base_branch == 'master' ]]; then
    if [[ $branch_name == 'qa' ]]; then
        handle_version "${GITHUB_EVENT.action}" "${GITHUB_EVENT.pull_request.merged}" "version minor"
    elif [[ $branch_name == *fix/* ]]; then
        handle_version "${GITHUB_EVENT.action}" "${GITHUB_EVENT.pull_request.merged}" "version patch"
    fi
fi

# Imprimir información de versión
new_version=$(npm --no-git-tag-version version)
echo "New Version: $new_version"

# Realizar el commit y push de la actualización de versión
git fetch origin $base_branch:$base_branch || true
git checkout $base_branch || true
git add .
git commit -am "Update version" || true
git checkout $base_branch
git push origin $base_branch --follow-tags || true

# Reintegrar cambios si es necesario
reintegrate_changes "${GITHUB_EVENT.action}" "${GITHUB_EVENT.pull_request.merged}" "$base_branch" "$branch_name"
