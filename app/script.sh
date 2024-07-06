#!/bin/bash

# Load environment variables from .env file
SCRIPTDIR="$(dirname "$0")"
ENV_FILE="$SCRIPTDIR/files/.env"
if [ -f "$ENV_FILE" ]; then
  export $(cat "$ENV_FILE" | xargs)
else
  echo ".env file not found. Please create one with the necessary environment variables."
  exit 1
fi

# Set the working directory to the script's directory
cd "$(dirname "$0")"

# File containing the list of repositories, tags, and identifiers
URLS_FILE="./files/urls.txt"

# File to store the digests
DIGEST_FILE="./files/digests.txt"

# Ensure the environment variables are set
if [[ -z "$DOCKERHUB_USERNAME" || -z "$DOCKERHUB_PASSWORD" ]]; then
  echo "Please set the DOCKERHUB_USERNAME and DOCKERHUB_PASSWORD environment variables in the .env file."
  exit 1
fi

if [[ -z "$TARGET_REGISTRY" ]]; then
  echo "Please set the TARGET_REGISTRY environment variable in the .env file."
  exit 1
fi

# Ensure the digest file exists
touch "$DIGEST_FILE"

# Function to get the latest images for a given repository
get_latest_images() {
  local repository=$1
  local url="https://hub.docker.com/v2/repositories/$repository/tags?page_size=25&page=1&ordering=last_updated"
  curl -s "$url" | jq -c '.results[] | {name: .name, digest: .images[0].digest, last_pushed: .images[0].last_pushed}'
}

# Function to get the stored digest for a given image
get_stored_digest() {
  local repository=$1
  local tag=$2
  grep "^$repository $tag" "$DIGEST_FILE" | cut -d ' ' -f3
}

# Function to update the stored digest for a given image
update_stored_digest() {
  local repository=$1
  local tag=$2
  local new_digest=$3
  sed -i "\:^$repository $tag:d" "$DIGEST_FILE"
  echo "$repository $tag $new_digest" >> "$DIGEST_FILE"
}

# Login to DockerHub
echo "Logging into DockerHub"
echo "$DOCKERHUB_PASSWORD" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin

# Check if URL file exists and is readable
if [ ! -f "$URLS_FILE" ]; then
  echo "URLs file not found: $URLS_FILE"
  exit 1
fi

# Iterate over each repository, tag, and identifier in the URLs file and check the digests
while read -r repository tag identifier || [ -n "$repository" ]; do
  if [ -z "$repository" ]; then
    continue
  fi

  echo "Processing Repository: $repository with Tag: $tag and Identifier: $identifier"
  latest_images=$(get_latest_images "$repository")

  latest_image=$(echo "$latest_images" | jq -r 'select(.name == "latest")')
  if [ -z "$latest_image" ]; then
    echo "No 'latest' tag found for repository: $repository"
    continue
  fi

  latest_digest=$(echo "$latest_image" | jq -r '.digest')
  last_pushed=$(echo "$latest_image" | jq -r '.last_pushed')

  # Get all tags with the same digest as the latest tag
  other_tags=$(echo "$latest_images" | jq -r "select(.digest == \"$latest_digest\" and .name != \"latest\") | .name")

  echo "Latest image digest: $latest_digest"
  echo "Other tags with same digest: $other_tags"
  echo "Last pushed date: $last_pushed"

  stored_digest=$(get_stored_digest "$repository" "$tag")
  echo "Stored Digest: $stored_digest"

  if [ "$latest_digest" != "$stored_digest" ]; then
    echo "Digest for $repository has changed. Pulling and pushing Docker image..."

    # Pulling the image
    docker pull "$repository:$tag"

    # Tagging and pushing the image with latest and all other tags
    for other_tag in $other_tags; do
      other_tag=$(echo "$other_tag" | tr -d '\n' | tr -d '\r')
      docker tag "$repository:$tag" "$TARGET_REGISTRY/$identifier:$other_tag"
      docker push "$TARGET_REGISTRY/$identifier:$other_tag"
    done

    docker tag "$repository:$tag" "$TARGET_REGISTRY/$identifier:latest"
    docker push "$TARGET_REGISTRY/$identifier:latest"

    update_stored_digest "$repository" "$tag" "$latest_digest"
  else
    echo "Digest for $repository has not changed."
  fi
done < "$URLS_FILE"
