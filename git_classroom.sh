#!/bin/bash

ORGANIZATION="mkijowski"

# Get the authenticated username

USERNAME=$(gh api user --jq '.login')

echo "Authenticated as $USERNAME"

ROLE=$(gh api "/orgs/$ORGANIZATION/memberships/$USERNAME" --jq '.role' 2>/dev/null)

echo "Authenticated user, $USERNAME, has the role of $ROLE in $ORGANIZATION"
