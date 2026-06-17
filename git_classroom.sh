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
		echo "$USERNAME is not a part of the $ORGANIZATION organization."
		exit 1
	fi

	if [ "$ROLE" != "admin" ]; then
       		echo "$USERNAME is not an owner of $ORGANIZATION"
       		exit 1
	fi

	echo "$USERNAME is an owner of the $ORGANIZATION"
}

# Determines the current term based on the current month and year
# Inputs:
#		Current month and year obtained from the system date
# Outputs:
#		CURRENT_TERM variable is set to the current term in the format of fYY,
getCurrentTerm() {
    local MONTH
    MONTH=$(date +%m)
    local YEAR
    YEAR=$(date +%y)

    # if the month is between July and November, 
    # the term is Fall 
    if (( MONTH >= 7 && MONTH <= 11 )); then
        CURRENT_TERM="f${YEAR}"
    # if the month is December, the term is Spring of the next year
    elif (( MONTH == 12 )); then
        CURRENT_TERM="s$(printf "%02d" "$((10#$YEAR + 1))")"
    # if the month is between January and March, the term is Spring
    elif (( MONTH <= 3 )); then
        CURRENT_TERM="s${YEAR}"
    # if the month is between April and June, the term is Summer
    else
        CURRENT_TERM="su${YEAR}"
    fi
}

# Generates a repository name based on the assignment, username, and term
# Inputs:
#		ASSIGNMENT - the name of the assignment
#		USERNAME - the GitHub username of the authenticated user
#		CURRENT_TERM - the current term determined by the getCurrentTerm function
# Outputs:
#		REPO_NAME variable is set to the generated repository name in the format of assignment-username-term
generateRepoName() {
    local ASSIGNMENT="$1"
    local USERNAME="$2"
    local TERM="$3"

    REPO_NAME="${ASSIGNMENT}-${USERNAME}-${TERM}"
}

# Main

# if git is intalled run git authenticator
if ! isGitInstalled; then
	exit 1
fi
isGitAuth


while getopts ":h?O:A:" opt; do
    case $opt in
        h|\?)
            echo "Usage: $0 [-h] [-O organization] [-A assignment]"
            echo "  -h                Show this help message and exit"
            echo "  -O organization   Check if authenticated user is an owner of the specified GitHub organization"
            echo "  -A assignment     Generate a repository name based on the assignment, username, and term"
            ;;
        O)
			ORGANIZATION="$OPTARG"
            checkOrganizationOwnership "$OPTARG"
            ;;
        A)
            ASSIGNMENT="$OPTARG"
            USERNAME=$(gh api user --jq '.login')
            getCurrentTerm
            generateRepoName "$ASSIGNMENT" "$USERNAME" "$CURRENT_TERM"
            echo "Generated repository name: $REPO_NAME"
    ;;
    esac
done
