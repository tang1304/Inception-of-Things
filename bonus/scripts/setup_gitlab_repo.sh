#!/bin/bash

GITLAB_URL="http://localhost:8082"
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

# Wait for GitLab to be fully ready
# echo "Waiting for GitLab API to be ready..."
# sleep 30

# Create a personal access token
echo "Creating GitLab personal access token.."
GITLAB_TOKEN=$(kubectl exec -n gitlab deployment/gitlab-toolbox -- \
  gitlab-rails runner "token = User.find_by_username('root').personal_access_tokens.create(scopes: [:api, :read_repository, :write_repository], name: 'automation-token', expires_at: 365.days.from_now); token.set_token('glpat-' + SecureRandom.alphanumeric(20)); token.save!; puts token.token")

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
git remote add gitlab "http://root:${GITLAB_TOKEN}@localhost:8082/root/${GITLAB_PROJECT_NAME}.git"

# Push to GitLab
echo "Pushing repository to GitLab..."
git push -u gitlab --all
git push -u gitlab --tags

echo "Repository successfully uploaded to GitLab!"
echo "GitLab project URL: $GITLAB_URL/root/$GITLAB_PROJECT_NAME"

# Clean up
cd -
rm -rf $TEMP_DIR