#!/bin/bash

# Constants
REPO_PATH="$(dirname "$(realpath "$0")")"
COMMIT_MSG="Commit message added"
BRANCH="master"

# Function to stage changes
stage_changes() {
    git add .
    if [[ $? -ne 0 ]]; then
        printf "Error: Failed to stage changes.\n" >&2
        return 1
    fi
}

# Function to commit changes
commit_changes() {
    git commit -m "$COMMIT_MSG"
    if [[ $? -ne 0 ]]; then
        printf "Error: Failed to commit changes.\n" >&2
        return 1
    fi
}

# Function to push changes
push_changes() {
    git push origin "$BRANCH"
    if [[ $? -ne 0 ]]; then
        printf "Error: Failed to push changes.\n" >&2
        return 1
    fi
}

# Main function
main() {
    cd "$REPO_PATH" || return 1
    stage_changes || return 1
    commit_changes || return 1
    push_changes || return 1
    printf "Changes pushed successfully.\n"
}

# Execute main function
main "$@"
