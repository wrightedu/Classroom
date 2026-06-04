#!/bin/bash

checkOrganizationOwnership() {
ORGANIZATION="$1"

# get the username
USERNAME=$(gh api user --jq '.login')

# checking org membership and role
ROLE=$(gh api "/orgs/$ORGANIZATION/memberships/$USERNAME" --jq '.role' 2>/dev/null)

# if user is not in organization, exit the program 
if [ $? -ne 0 ]; then
	echo "$USERNAME is not apart of the $ORGANIZATION organization."
	exit 1
fi

# if the role is not admin, exit program
if [ "$ROLE" != "admin" ]; then
       echo "$USERNAME is not an owner of $ORGANIZATION"
       exit 1
fi

# validation of user is owner of organization
echo "$USERNAME is an owner of the $ORGANIZATION"
}

echo "Which org are you checking for? "
read ORGANIZATION
checkOrganizationOwnership "$ORGANIZATION"
