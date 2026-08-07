#!/bin/bash

SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")

source "$SCRIPT_DIR/classroom_git_checks.sh"
source "$SCRIPT_DIR/classroom_helper.sh"

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

WSU_classroom() {
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

            getCurrentTerm
            REPO_NAME="$ASSIGNMENT-email-$CURRENT_TERM"

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

echo
read -p "Would you like to create repositories for the TAs? (Y/N)"
CREATE_TA_REPOS="$REPLY"

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

WSU_classroom "$@"
