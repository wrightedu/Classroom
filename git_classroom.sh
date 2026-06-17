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

# Displays usage information for the script
# Inputs:
#		None
# Outputs:
#		Prints usage information and exits the script
usage() {
    echo "Usage: $0 [-h] [-O organization] [-A assignment]"
    echo "  -h                Show this help message and exit"
    echo "  -O organization   Check if authenticated user is an owner of the specified GitHub organization"
    echo "  -A assignment     Generate a repository name based on the assignment, username, and term"
    echo "  -T                Select a template repository from the specified GitHub organization"
    exit 0
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

# Allows the user to select a template repository from the specified GitHub organization
# Inputs:
#		ORGANIZATION - the GitHub organization to search for template repositories
# Outputs:
#		TEMPLATE_REPO variable is set to the name of the selected template repository
selectTemplateRepo(){
    local templates=()

    # while loop to read the template repositories from the specified 
    # GitHub organization and store them in an array and filter them using grep to only 
    # include repositories with "template" in their name
    while IFS= read -r repo; do
        templates+=("$repo")
    done < <(
        gh repo list "$ORGANIZATION" \
            --limit 100 \
            --json name \
            --jq '.[].name' \
            | grep -i "template"
    )

    # if the templates array is empty, print a message and exit the script
    if [ ${#templates[@]} -eq 0 ]; then
        echo "No template repositories found in the $ORGANIZATION."
        exit 1
    fi

    echo "Available template repositories in $ORGANIZATION:"
    echo

    # for each repository in the templates array, print its index and name
    for i in "${!templates[@]}"; do
        echo "$((i + 1)). ${templates[i]}"
    done

    echo 
    read -p "Select a template repository by number: " choice

    # if the user's choice is not a valid number or is out of range, print an error message and exit the script
    if ! [[ "$choice" =~ ^[1-9][0-9]*$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#templates[@]} ]; then
        echo "Invalid selection. Please enter a number between 1 and ${#templates[@]}."
        exit 1
    fi

    TEMPLATE_REPO="${templates[$((choice - 1))]}"

    echo "Selected template repository: $TEMPLATE_REPO"
}

# Main
USE_TEMPLATE=false
TEMPLATE_REPO=""

# if git is intalled run git authenticator
if ! isGitInstalled; then
	exit 1
fi
isGitAuth

# if no arguments are provided, display usage information and exit
if [ $# -eq 0 ]; then
    echo "No arguments provided."
    usage
fi

while getopts ":h?O:A:T" opt; do
    case $opt in
        h|\?)
            usage
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
        T)
            USE_TEMPLATE=true
            ;;
    esac
done

# if the -T flag is set, check if the -O flag is also set and prompt the user 
# to select a template repository from the specified GitHub organization
if [ "$USE_TEMPLATE" = true ]; then

    # if the -T flag is set but the -O flag is not set, print an error message and exit the script
    if [ -z "$ORGANIZATION" ]; then
        echo "Error: -T requires an organization specified with -O."
        exit 1
    fi

    selectTemplateRepo
fi
