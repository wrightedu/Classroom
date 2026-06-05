#!/bin/bash

# Verifies that GH is installed.
# Verifies that GH is authenticated.
# Displays appropriate status messages.
isGitInstalled(){
	if gh --version >/dev/null 2>&1; then
		echo "GH is installed."
		return 0
	else
		echo
		echo
		echo
	fi	
}

# Check if gh is authenticated with a GitHub account.
isGitAuth(){
	# Get git auth status, discard output, and get exit code
    if gh auth status >/dev/null 2>&1; then
		echo "GH is authenticated with GitHub."
    else
		echo "GH is not authenticated with GitHub."

        # Ask the user if they want to log in.
        read -p "Would you like to log in now? (Y/N): " choice

        # Check if the user entered y or Y.
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            gh auth login
        fi
    fi
}

# Check the organization ownership
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


# Main

# if git is intalled run git authenticator
if isGitInstalled; then
    isGitAuth
fi

# calls checkOrganizationOwnership
echo "Which org are you checking for? "
read ORGANIZATION
checkOrganizationOwnership "$ORGANIZATION"
