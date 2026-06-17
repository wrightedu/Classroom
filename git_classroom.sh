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
# Input:
#		User input (y/n)
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

# Verifies that the authenticated GitHub user is an owner of the specified GitHub organization
# Input:
#		ORGANIZATION - GitHub organization
# Outputs:
# 		Prints message whether the user is an owner of specified organization

checkOrganizationOwnership() {
	USERNAME=$(gh api user --jq '.login')
	ROLE=$(gh api "/orgs/$ORGANIZATION/memberships/$USERNAME" --jq '.role' 2>/dev/null)

	if [ $? -ne 0 ]; then
		echo "$USERNAME is not apart of the $ORGANIZATION organization."
		exit 1
	fi

	if [ "$ROLE" != "admin" ]; then
       		echo "$USERNAME is not an owner of $ORGANIZATION"
       		exit 1
	fi

	echo "$USERNAME is an owner of the $ORGANIZATION"
}

# Verifies that a GitHub username exists
# Input:
#       GitHub username
# Outputs:
#       Prints whether the username is valid
isValidGitUser(){

}


# Main

# if git is intalled run git authenticator
if ! isGitInstalled; then
	exit 1
fi
isGitAuth


while getopts ":h?O:U:" opt; do
    case $opt in
        h|\?)
            echo "Usage: $0 [-h] [-O organization]"
            echo "  -h                Show this help message and exit"
            echo "  -O organization   Check if authenticated user is an owner of the specified GitHub organization"
	    echo "  -U username       Verify that a GitHub username exists"
            exit 0
            ;;
        O)
			ORGANIZATION="$OPTARG"
            checkOrganizationOwnership "$OPTARG"
            exit 0:
            ;;
    esac
done
