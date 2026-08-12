#!/bin/bash

WSU_classroom() (

SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")

source "$SCRIPT_DIR/classroom_git_checks.sh"
source "$SCRIPT_DIR/classroom_helper.sh"

# if git is intalled run git authenticator
if ! isGitInstalled; then
	return 1
fi

isGitAuth

# process the command line arguments
# if no arguments are provided, display usage information and exit
if [ $# -eq 0 ]; then
    echo "No arguments provided."
    usage
    return 1
fi

OPTIND=1

while getopts ":h?O:A:T:C:" opt; do
    case $opt in
        h|\?)
            usage
	        return 0
            ;;
        O)
	        ORGANIZATION="$OPTARG"
            ;;
        A)
            ASSIGNMENT="$OPTARG"

	        local CURRENT_TERM=$(getCurrentTerm)
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
            return 1
            ;;
        *)
            echo "Error: Invalid option -$OPTARG"
            usage
            return 1
            ;;
    esac
done

# make sure both an organization and assignment were provided
if [[ -z "$ORGANIZATION" || -z "$ASSIGNMENT" || -z "$TEMPLATE" || -z "$CSV_FILE" ]]; then
    echo "Error: -O -A -T -C are required."
    usage
    return 1
fi

# verify ownership of the organization
checkOrganizationOwnership

# verify that the specified template repository exists and is a template repository
checkTemplateRepo $TEMPLATE

# allow the user to edit the generated repository name before creating any repositories
editRepoName

# verify the CSV file exists
if [[ ! -f "$CSV_FILE" ]]; then
    echo "Error: CSV file '$CSV_FILE' not found."
    exit 1
else
    echo "CSV file '$CSV_FILE' found."
fi

CREATE_TA_REPOS="N"
GRANT_TA_ACCESS="N"

if hasTAs; then
    echo
    read -p "Would you like to create repositories for TAs? (Y/N): " CREATE_TA_REPOS

    read -p "Would you like to grant TAs access to student repositories? (Y/N): " GRANT_TA_ACCESS
fi

# process the class roster and create repositories
processRoster

# creates file of student repo links for the instructor to use
exportRepoLinks

# allows the user to clone the student repositories to their local machine if they want
echo
read -p "Would you like to clone the student repositories to your local machine? (Y/N)" CLONE

if [[ "$CLONE" =~ ^[Yy]$ ]]; then
    cloneRepositories
    echo "All repositories cloned."
else
    echo "Skipping repository cloning."
fi

configurationSummary
)
