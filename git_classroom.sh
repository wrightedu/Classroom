#!/bin/bash

# Check if the gh is installed.
isGitInstalled(){
	# Get git version, discard output, and get exit code
	if gh --version >/dev/null 2>&1; then
		echo "Git(gh) is installed."
	else
		echo "Git(gh) is not installed."

		# Ask user if they want to install git 
		read -p "Install Git(gh) now? (Y/N): " choice
	
	# Check if the user entered y or Y.
    	if [[ "$choice" =~ ^[Yy]$ ]]; then
        	sudo apt update
        	sudo apt install gh
    		fi
	fi	
}

# Check if gh is authenticated with a GitHub account.
isGitAuth(){
	# Get git auth status, discard output, and get exit code
    	if gh auth status >/dev/null 2>&1; then
		echo "Git(gh) is authenticated with GitHub."
    	else
		echo "Git(gh) is not authenticated with GitHub."

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
