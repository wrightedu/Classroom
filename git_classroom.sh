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

# Determines the current term based on the current month and year
# Inputs:
#		Current month and year
# Outputs:
#		TERM variable is set to the current term in the format of fYY,
#		sYY, or suYY
getCurrentTerm() {
    local MONTH=$(date +%m)
    local YEAR=$(date +%y)

	# if the months are between july and november,
	# the term is fall of the current year
    if (( MONTH >= 7 && MONTH <= 11 )); then
        TERM="f${YEAR}"
    # if the month is decermber,
	# the term is spring of the next year
	elif (( MONTH == 12 )); then
        TERM="s$(printf "%02d" $((10#$YEAR + 1)))"
    # if the month is between january and march,
	# the term is spring of the current year
	elif (( MONTH <= 3 )); then
        TERM="s${YEAR}"
    # if the month is between april and june,
	# the term is summer of the current year
	else
        TERM="su${YEAR}"
    fi
}


# Main

# if git is intalled run git authenticator
if ! isGitInstalled; then
	exit 1
fi
isGitAuth

getCurrentTerm
echo "Current term is: $TERM"

while getopts ":h?O:" opt; do
    case $opt in
        h|\?)
            echo "Usage: $0 [-h] [-O organization]"
            echo "  -h                Show this help message and exit"
            echo "  -O organization   Check if authenticated user is an owner of the specified GitHub organization"
            exit 0
            ;;
        O)
			ORGANIZATION="$OPTARG"
            checkOrganizationOwnership "$OPTARG"
            exit 0
            ;;
    esac
done
