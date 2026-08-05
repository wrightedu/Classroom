#!/bin/bash

# Verifies that GH is installed.
# Outputs:
# 		GH is installed
#		or an error message that prompts user to install it
isGitInstalled() {
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
isGitAuth() {
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
    echo "Usage: $0 [-h] [-O organization] [-A assignment] [-T template] [-C csv_file]"
    echo "  -h                Show this help message and exit"
    echo "  -O organization   Check if authenticated user is an owner of the specified GitHub organization"
    echo "  -A assignment     Generate a repository name based on the assignment, username, and term"
    echo "  -T template       Specify the template repository to use for creating new repositories"
    echo "  -C csv_file       Specify the class roster CSV file"
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

# Makes sure the github username exists
# Input:
#		Github Username
# Outputs:
#		Returns 0 if valid, 1 otherwise
isGitHubUserValid() {
	local username="$1"

    if gh api "users/$username" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Determines the current term based on the current month and year
# Inputs:
#		Current month and year obtained from the system date
# Outputs:
#		CURRENT_TERM variable is set to the current term in the format of fYY,
getCurrentTerm() {

    local MONTH=$((10#$(date +%m)))
    local YEAR=$((10#$(date +%y)))

    # if the current month is between July and November, it's Fall term (fYY)
    if (( MONTH >= 7 && MONTH <= 11 )); then
        CURRENT_TERM="f${YEAR}"
    # if the current month is December, it's Spring term of the next year (sYY)
    elif (( MONTH == 12 )); then
        CURRENT_TERM="s$(printf "%02d" $((YEAR + 1)))"
    # if the current month is between January and March, it's Spring term (sYY)
    elif (( MONTH <= 3 )); then
        CURRENT_TERM="s${YEAR}"
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

# Allows the user to edit the generated repository name
# Inputs:
#		None
# Outputs:
#		Prompts the user to edit the repository name or continue with the current name
editRepoName(){
    while true
    do
        echo
        echo "Would you like to edit the repository name?"
        echo "Current repository name: $REPO_NAME"
        echo
        echo "1. Assignment: $ASSIGNMENT"
        echo "2. Term: $CURRENT_TERM"
        echo "3. Use custom repository name"
        echo "4. Continue with current repository name"
        echo "5. Cancel and exit"
        echo
        read -p "Enter your choice (1-5): " choice

        case $choice in
            1)
                read -p "Enter new assignment name: " ASSIGNMENT
                generateRepoName "$ASSIGNMENT" "$USERNAME" "$CURRENT_TERM"
                ;;
            2)
                read -p "Enter new term (e.g., f24, s25, su25): " CURRENT_TERM
                generateRepoName "$ASSIGNMENT" "$USERNAME" "$CURRENT_TERM"
                ;;
            3)
                read -p "Enter custom repository name: " REPO_NAME
                ;;
            4)
                break
                ;;
            5)
                echo "Exiting..."
                exit 0
                ;;
            *)
                echo "Invalid choice. Please enter a number between 1 and 5."
                ;;
        esac
    done
}

# Verifies that the specified template repository exists and is a template repository
# Inputs:
#		TEMPLATE - the name of the template repository
# Outputs:
#		Prints message whether the template repository exists and is a template repository
checkTemplateRepo() {

    if ! gh repo view "$TEMPLATE" >/dev/null 2>&1; then
        echo "Error: Template repository '$TEMPLATE' does not exist."
        exit 1
    fi

    if [[ "$(gh api "repos/$TEMPLATE" --jq '.is_template')" != "true" ]]; then
        echo "Error: '$TEMPLATE' is not a template repository."
        exit 1
    fi

    echo "Using template repository: $TEMPLATE"
}


# Processes the class roster and creates repos
# Inputs:
#       CSV_FILE - CSV file containing names, GitHub usernames, and roles
# Outputs:
#       Creates repos for students and TAs.
#       Grants TAs read access to all student repos
processRoster() {

    TAS=()
    STUDENTS=()

    # while IFS=',' read -r NAME USERNAME ROLE
	while IFS=',' read -r NAME USERNAME ROLE || [[ -n "$NAME" ]]
    do

        # Skip header
        [[ "$NAME" == "Name" ]] && continue

        # Remove Windows carriage return if present
        # ROLE=$(echo "$ROLE" | tr -d '\r')
		NAME=${NAME//$'\r'/}
		USERNAME=${USERNAME//$'\r'/}
		ROLE=${ROLE//$'\r'/}

        if ! isGitHubUserValid "$USERNAME"; then
            echo "Skipping invalid GitHub username: $USERNAME"
            continue
        fi

        case "$ROLE" in

            Student)
                STUDENTS+=("$USERNAME")
                createStudentRepo "$USERNAME"
                ;;

            TA)
                TAS+=("$USERNAME")
                createTARepo "$USERNAME"
                ;;

            Teacher)
                echo "$USERNAME is the instructor. No repository created."
                ;;

            *)
                echo "Unknown role: $ROLE"
                ;;
        esac

    done < "$CSV_FILE"

    echo
    echo "Granting TA access..."

    for TA in "${TAS[@]}"
    do
        for STUDENT in "${STUDENTS[@]}"
        do
            grantTAAccess "$TA" "$STUDENT"
        done
    done
}

# Clones the student repositories to a specified local directory
# Inputs:
#       STUDENTS - Array of student GitHub usernames
#       CLONE_DIR - Directory to clone the repositories into
# Outputs:
#       Clones each student's repository into the specified local directory
cloneRepositories() {

    local CLONE_DIR

    read -p "Enter the directory to clone student repositories into: " CLONE_DIR

    if [[ ! -d "$CLONE_DIR" ]]; then
        read -p "Directory does not exist. Create it? (Y/N): " CREATE

        if [[ "$CREATE" =~ ^[Yy]$ ]]; then
            mkdir -p "$CLONE_DIR"
        else
            echo "Skipping repository cloning."
            return
        fi
    fi

    for USERNAME in "${STUDENTS[@]}"
    do
        getCurrentTerm
        generateRepoName "$ASSIGNMENT" "$USERNAME" "$CURRENT_TERM"

        echo "Cloning $REPO_NAME..."
        gh repo clone "$ORGANIZATION/$REPO_NAME" "$CLONE_DIR/$REPO_NAME"
    done

    echo "Finished cloning student repositories."
}

SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")

#source "$SCRIPT_DIR/classroom_git_checks.sh"
source "$SCRIPT_DIR/classroom_helper.sh"

classroom() {
# if git is intalled run git authenticator
if ! isGitInstalled; then
	exit 1
fi
isGitAuth

# process the command line arguments
# if no arguments are provided, display usage information and exit
if [ $# -eq 0 ]; then
    echo "No arguments provided."
    usage
fi

while getopts ":h?O:A:T:C:" opt; do
    case $opt in
        h|\?)
            usage
            ;;
        O)
			ORGANIZATION="$OPTARG"
            ;;
        A)
            ASSIGNMENT="$OPTARG"
            USERNAME=$(gh api user --jq '.login')

            getCurrentTerm
            generateRepoName "$ASSIGNMENT" "$USERNAME" "$CURRENT_TERM"
            echo "Generated repository name: $REPO_NAME"
            ;;
        T)
            TEMPLATE="$OPTARG"
            ;;
        C)
            CSV_FILE="$OPTARG"
            ;;
        :)
            echo "Error: Option -$OPTARG requires an argument."
            usage
            ;;
        *)
            echo "Error: Invalid option -$OPTARG"
            usage
            ;;
    esac
done

# make sure both an organization and assignment were provided
if [[ -z "$ORGANIZATION" || -z "$ASSIGNMENT" || -z "$TEMPLATE" || -z "$CSV_FILE" ]]; then
    echo "Error: -O -A -T are required."
    usage
fi

# verify ownership of the organization
checkOrganizationOwnership

# verify that the specified template repository exists and is a template repository
checkTemplateRepo

# allow the user to edit the generated repository name before creating any repositories
editRepoName

# verify the CSV file exists
if [[ ! -f "$CSV_FILE" ]]; then
    echo "Error: CSV file '$CSV_FILE' not found."
    exit 1
else
    echo "CSV file '$CSV_FILE' found."
fi

# process the class roster and create repositories
processRoster

# allows the user to clone the student repositories to their local machine if they want
echo
read -p "Would you like to clone the student repositories to your local machine? (Y/N)" CLONE

if [[ "$CLONE" =~ ^[Yy]$ ]]; then
    cloneRepositories
    echo "All repositories cloned."
else
    echo "Skipping repository cloning."
fi

echo "Completed"
}

classroom "$@"
