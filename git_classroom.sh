#!/bin/bash

ORGANIZATION="WSU-kkoppin"

# Get the authenticated username

USERNAME=$(gh api user --jq '.login')

echo "Authenticated as $USERNAME"
