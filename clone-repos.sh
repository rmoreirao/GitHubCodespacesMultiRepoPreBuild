#!/bin/bash
# filepath: d:\repos\codespaces-multi-repo\clone-repos.sh

# Set working directory to where the devcontainer.json is located
cd "$(dirname "$0")/.devcontainer" || exit

# Create a temporary directory for processing
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Extract repository entries from devcontainer.json using jq
# If jq is not available, we'll install it
if ! command -v jq &> /dev/null; then
    echo "jq not found, installing..."
    if command -v apt-get &> /dev/null; then
        apt-get update && apt-get install -y jq
    elif command -v brew &> /dev/null; then
        brew install jq
    else
        echo "Cannot install jq. Please install it manually and run this script again."
        exit 1
    fi
fi

# Extract repository names from devcontainer.json
jq -r '.customizations.codespaces.repositories | keys[]' devcontainer.json > "$TEMP_DIR/repos.txt"

# Read the file and clone each repository
echo "Starting to clone repositories..."
while IFS= read -r repo; do
    echo "Cloning $repo..."
    # Create parent directories if they don't exist
    REPO_DIR="../../$(echo "$repo" | cut -d '/' -f 2)"
    mkdir -p "$REPO_DIR"
    
    # Clone the repository if it doesn't exist already
    if [ ! -d "$REPO_DIR/.git" ]; then
        git clone "https://github.com/$repo.git" "$REPO_DIR"
        echo "Repository $repo cloned successfully to $REPO_DIR."
    else
        echo "Repository $repo already exists at $REPO_DIR. Skipping."
    fi
done < "$TEMP_DIR/repos.txt"

echo "All repositories have been processed."