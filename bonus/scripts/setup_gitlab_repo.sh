#!/bin/bash

GITLAB_URL="http://gitlab.local"
GITLAB_PROJECT_NAME="tgellon_iot_willapp"
USERNAME="root"

echo $"GitLab username: $USERNAME"
GITLAB_PASSWORD=$(kubectl get secret -n gitlab gitlab-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 -d)
echo "Password: $GITLAB_PASSWORD"

echo $'\nCloning GitHub repository...\n'

# Clone the GitHub repository
TEMP_DIR=$(mktemp -d)
cd $TEMP_DIR
git clone https://github.com/tang1304/tgellon_IoT_willApp.git
cd tgellon_IoT_willApp

# Check for existing personal access token named 'automation-token'
echo "Checking for existing GitLab personal access token.."
TOKEN=$(kubectl exec -n gitlab deployment/gitlab-toolbox -- \
  gitlab-rails runner "user = User.find_by_username('root'); token = user.personal_access_tokens.find_by(name: 'automation-token'); puts token&.token.to_s" | tr -d '\n\r')


GITLAB_TOKEN=$(curl -sk --request POST "${GITLAB_URL}/oauth/token" \
  --form "grant_type=password" \
  --form "username=${USERNAME}" \
  --form "password=${GITLAB_PASSWORD}" \
  --form "scope=api" 2>/dev/null | jq -r '.access_token')

echo 'GitLab token created:'
echo "$GITLAB_TOKEN"

# Create a new project in GitLab
echo "Creating new GitLab project: $GITLAB_PROJECT_NAME..."
PROJECT_RESPONSE=$(curl -s -X POST "$GITLAB_URL/api/v4/projects" \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --form "name=$GITLAB_PROJECT_NAME" \
  --form "visibility=public")

# echo "API Response: $PROJECT_RESPONSE"

PROJECT_ID=$(echo "$PROJECT_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
echo "Project created with ID: $PROJECT_ID"

# Configure git and push to GitLab
git remote rename origin github
# Use the token as both username and password for GitLab authentication
git remote add gitlab "http://oauth2:${GITLAB_TOKEN}@iot.local.gitlab/root/${GITLAB_PROJECT_NAME}.git"

# Alternatively, you can use git credential store
git config --global credential.helper store

# Push to GitLab
echo "Pushing repository to GitLab..."
git push -u gitlab --all
git push -u gitlab --tags

echo "Repository successfully uploaded to GitLab!"
echo "GitLab project URL: $GITLAB_URL/root/$GITLAB_PROJECT_NAME"

# Clean up
cd -
rm -rf $TEMP_DIR