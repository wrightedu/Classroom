#!/bin/bash
# Function to clone repositories from a CSV file during the WSU Classroom script execution or as a standalone function
# Inputs:
#       User input - CSV file containing repository names and links
#       User input - Directory to clone the repositories into
# Outputs:
#       Clones the repositories into the specified directory
# State Changes:
#       Repositories are cloned into the specified directory
cloneRepositories() {

    local REPO_FILE
    local CLONE_DIR
    local CREATE
    local NAME
    local REPO_LINK
    local REPO_NAME

    # Ask the user for the repository links CSV file
    read -p "Enter the repository links CSV file: " REPO_FILE

    # Verify the repository links file exists
    if [[ ! -f "$REPO_FILE" ]]; then
        echo "Error: CSV file '$REPO_FILE' not found."
        return 1
    fi

    echo "Using repository links file: $REPO_FILE"

    # Ask where the repositories should be cloned
    read -p "Enter the directory to clone repositories into: " CLONE_DIR
    # handling tildes
    eval CLONE_DIR="$CLONE_DIR"

    # Create the directory if it does not exist
    if [[ ! -d "$CLONE_DIR" ]]; then
        read -p "Directory does not exist. Create it? (Y/N): " CREATE

        if [[ "$CREATE" =~ ^[Yy]$ ]]; then
            mkdir -p "$CLONE_DIR"
        else
            echo "Skipping repository cloning."
            return 0
        fi
    fi

    # Read repository information from the CSV file
    while IFS=',' read -r NAME REPO_LINK || [[ -n "$NAME" ]]
    do
        # Skip header
        [[ "$NAME" == "Name" ]] && continue

        # Remove carriage returns
        NAME=${NAME//$'\r'/}
        REPO_LINK=${REPO_LINK//$'\r'/}

        # Skip empty repository links
        [[ -z "$REPO_LINK" ]] && continue

        # Get repository name from the repository URL
        REPO_NAME="${REPO_LINK##*/}"

        echo "Cloning $NAME: $REPO_NAME..."

        gh repo clone "$REPO_LINK" "$CLONE_DIR/$REPO_NAME"

    done < "$REPO_FILE"

    echo "Finished cloning repositories."
}

# Main function for the WSU Classroom script
# Inputs:
#       -O ORGANIZATION - GitHub organization
#       -A ASSIGNMENT - Assignment name
#       -T TEMPLATE - Template repository
#       -C CSV_FILE - Class roster CSV file
# Outputs:
#       Creates repositories for students and TAs, grants TAs access to student repositories, and optionally clones the repositories to the local machine
# State Changes:
#       Repositories are created for students and TAs, TAs are granted access to student repositories, and repositories may be cloned to the local machine
WSU_classroom() (

    # Declare local variables
    local SCRIPT_DIR
    local ORGANIZATION
    local ASSIGNMENT
    local TEMPLATE
    local CSV_FILE
    local CURRENT_TERM
    local REPO_NAME
    local CREATE_TA_REPOS="N"
    local GRANT_TA_ACCESS="N"
    local CLONE

    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    source "$SCRIPT_DIR/classroom_git_checks.sh"
    source "$SCRIPT_DIR/classroom_helper.sh"

    # check if the user is authenticated with GitHub
    isGitAuth

    # process the command line arguments
    # if no arguments are provided, display usage information and exit
    if [ $# -eq 0 ]; then
        echo "No arguments provided."
        usage
        return 1
    fi

    # reset the option index for getopts
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

	            CURRENT_TERM=$(getCurrentTerm)
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
    checkOrganizationOwnership "$ORGANIZATION"

    # verify that the specified template repository exists and is a template repository
    checkTemplateRepo "$TEMPLATE"

    # allow the user to edit the generated repository name before creating any repositories
    editRepoName "$ASSIGNMENT" "$CURRENT_TERM"

    # verify the CSV file exists
    if [[ ! -f "$CSV_FILE" ]]; then
        echo "Error: CSV file '$CSV_FILE' not found."
            return 1
    else
        echo "CSV file '$CSV_FILE' found."
    fi  

    # check if the CSV file contains TAs and prompt the user to create TA repositories and grant access to student repositories
    if hasTAs "$CSV_FILE"; then
        echo
        read -p "Would you like to create repositories for TAs? (Y/N): " CREATE_TA_REPOS

        read -p "Would you like to grant TAs access to student repositories? (Y/N): " GRANT_TA_ACCESS
    fi

    # process the class roster and create repositories
    processRoster "$CSV_FILE" "$ORGANIZATION" "$ASSIGNMENT" "$CURRENT_TERM" "$TEMPLATE" "$CREATE_TA_REPOS" "$GRANT_TA_ACCESS"

    # allows the user to clone the student repositories to their local machine if they want
    echo
    read -p "Would you like to clone the student repositories to your local machine? (Y/N): " CLONE

    if [[ "$CLONE" =~ ^[Yy]$ ]]; then
        cloneRepositories
        echo "All repositories cloned."
    else
        echo "Skipping repository cloning."
    fi

    # display a summary of the configuration and actions taken
    configurationSummary "$ORGANIZATION" "$ASSIGNMENT" "$CURRENT_TERM" "$TEMPLATE" "$CSV_FILE" "$CREATE_TA_REPOS" "$GRANT_TA_ACCESS" 
)
