#!/bin/bash

# Verifies that GH is installed.
# Outputs:
# 		GH is installed
#		or an error message that prompts user to install it
isGitInstalled(){
	if gh --version >/dev/null 2>&1; then
		echo "GH is installed."
		return 0
	else
		echo "Error: GH is not installed"
		echo "Please install it from:"
		echo "https://cli.github.com/"
		return 1
	fi	
}

# Check if gh is authenticated with a GitHub account
# Outputs:
# 		GH is authenticated with GitHub
#		or Gh isnt authenticated and prompts user to login
isGitAuth(){
    if gh auth status >/dev/null 2>&1; then
		echo "GH is authenticated with GitHub."
    else
		echo "GH is not authenticated with GitHub."
        read -p "Would you like to log in now? (Y/N): " choice
		
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

# if git isnt installed exit
if ! isGitInstalled; then 
	exit 1
fi
isGitAuth

# calls checkOrganizationOwnership
echo "Which org are you checking for? "
read ORGANIZATION
checkOrganizationOwnership "$ORGANIZATION"
