#!/bin/bash
set -e

echo "Configuring Git"
git config --global user.email "actions@github.com"
git config --global user.name "GitHub Actions"

echo "Determining Version"
base_branch=$Determine_Version_BASE_BRANCH
branch_name=$Determine_Version_BRANCH_NAME
github_event_action=$github_event_action
github_event_pull_request_merged=$github_event_pull_request_merged

package_name=$(node -pe "require('./package.json').name")

if [[ $base_branch == 'qa' ]]; then
    if [[ $branch_name == 'dev' ]]; then
        if [[ $github_event_action == 'closed' && $github_event_pull_request_merged == 'true' ]]; then
            # Check if the minor version is equal to the QA minor version
            minor_version=$(echo $version | cut -d. -f2)
            qa_minor_version=$(npm show $package_name version --tag=qa | cut -d. -f2)
            
            if [[ $minor_version -eq $qa_minor_version ]]; then
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
