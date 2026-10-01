#!/bin/bash
# Function to clone repositories from a CSV file into an assignment directory
# Inputs:
#       REPO_FILE - CSV file containing repository names and links
#       ASSIGNMENT - Assignment name
#       CURRENT_TERM - Current academic term
#       If no arguments are provided, prompts the user to select a CSV file
# Outputs:
#       Clones repositories into a directory named assignment-term
# State Changes:
#       Creates an assignment-term directory and clones repositories into it
cloneRepositories() {

    # Declare local variables
    local REPO_FILE="$1"
    local ASSIGNMENT="$2"
    local CURRENT_TERM="$3"

    local CLONE_DIR
    local NAME
    local REPO_LINK
    local REPO_NAME

    local CSV_FILES=()
    local CSV_COUNT
    local SELECTION
    local CONFIRM
    local FILE

    # If no repository file was passed, look for CSV files
    # in the current directory
    if [[ -z "$REPO_FILE" ]]; then

        for FILE in ./*.csv; do
            [[ -f "$FILE" ]] && CSV_FILES+=("$FILE")
        done

        CSV_COUNT=${#CSV_FILES[@]}

        # No CSV files found
        if [[ "$CSV_COUNT" -eq 0 ]]; then
            echo "Error: No CSV files found in $(pwd)."
            echo "Run cloneRepositories from a directory containing a repository links CSV file."
            return 1
        fi

        # Only one CSV file found
        if [[ "$CSV_COUNT" -eq 1 ]]; then
            echo "Found CSV file:"
            echo "  ${CSV_FILES[0]}"
            echo

            read -p "Would you like to use this file? (Y/N) [Y]: " CONFIRM
            CONFIRM="${CONFIRM:-Y}"

            if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
                echo "Repository cloning cancelled."
                return 0
            fi

            REPO_FILE="${CSV_FILES[0]}"

        # Multiple CSV files found
        else
            echo "CSV files found:"
            echo

            for ((i=0; i<CSV_COUNT; i++)); do
                echo "$((i + 1)). ${CSV_FILES[$i]}"
            done

            echo
            read -p "Select the repository links CSV file (1-$CSV_COUNT): " SELECTION

            # Validate selection
            if [[ ! "$SELECTION" =~ ^[0-9]+$ ]] ||
               (( SELECTION < 1 || SELECTION > CSV_COUNT )); then
                echo "Error: Invalid selection."
                return 1
            fi

            REPO_FILE="${CSV_FILES[$((SELECTION - 1))]}"
        fi

        echo
        echo "Selected: $REPO_FILE"
    fi

    # Verify the repository links file exists
    if [[ ! -f "$REPO_FILE" ]]; then
        echo "Error: CSV file '$REPO_FILE' not found."
        return 1
    fi

    #
    # If assignment and term were not passed, determine them
    # from the repository links filename.
    #
    # Expected format:
    # assignment-term-repo-links.csv
    #
    if [[ -z "$ASSIGNMENT" || -z "$CURRENT_TERM" ]]; then

        local FILE_NAME
        local BASE_NAME

        FILE_NAME="${REPO_FILE##*/}"
        BASE_NAME="${FILE_NAME%-repo-links.csv}"

        if [[ "$FILE_NAME" =~ -((f|s|su)[0-9]{2})-repo-links\.csv$ ]]; then

            CURRENT_TERM="${BASH_REMATCH[1]}"
            ASSIGNMENT="${BASE_NAME%-$CURRENT_TERM}"

        else
            echo "Error: '$FILE_NAME' does not appear to be a repository links CSV file."
            echo "Expected filename format:"
            echo "  <assignment>-<term>-repo-links.csv"
            return 1
        fi
    fi

    CLONE_DIR="${ASSIGNMENT}-${CURRENT_TERM}"

    echo
    echo "Using repository links file: $REPO_FILE"
    echo "Assignment: $ASSIGNMENT"
    echo "Term: $CURRENT_TERM"

    # Create the assignment directory if it does not exist
    if [[ ! -d "$CLONE_DIR" ]]; then
        mkdir -p "$CLONE_DIR"

        if [[ $? -ne 0 ]]; then
            echo "Error: Could not create directory '$CLONE_DIR'."
            return 1
        fi
    fi

    echo "Cloning repositories into: $(pwd)/$CLONE_DIR"
    echo

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

        # Skip repository if it has already been cloned
        if [[ -d "$CLONE_DIR/$REPO_NAME" ]]; then
            echo "Repository already exists. Skipping."
            continue
        fi

        # Clone repository into assignment directory
        if ! gh repo clone "$REPO_LINK" "$CLONE_DIR/$REPO_NAME"; then
            echo "Error: Failed to clone $REPO_NAME."
        fi

    done < "$REPO_FILE"

    echo
    echo "Finished cloning repositories."
    echo "Repositories cloned to: $(pwd)/$CLONE_DIR"
}

# Function to check if the user has pushed to the repository before the deadline
# Inputs:
#       -D DUE_DATE - Due date in the format "MM/DD/YYYY HH:MM AM/PM"
#       <repo-directory> - Directory containing the cloned repositories
# Outputs:
#       Prints whether the user has pushed to the repository before the deadline or not
# State Changes:
#       None
checkDueDate() {
    local DUE_DATE
    local REPO_DIR
    local DEADLINE

    OPTIND=1

    while getopts ":D:" opt; do
        case $opt in
            D)
                DUE_DATE="$OPTARG"
                ;;
            *)
                echo "Usage: checkDueDate -D \"MM/DD/YYYY HH:MM AM/PM\" <repo-directory>"
                return 1
                ;;
        esac
    done

    shift $((OPTIND -1))

    REPO_DIR="$1"

    if [[ -z "$DUE_DATE" || -z "$REPO_DIR" ]]; then
        echo "Usage: checkDueDate -D \"MM/DD/YYYY HH:MM AM/PM\" <repo-directory>"
        return 1
    fi

    DEADLINE=$(formatDueDate "$DUE_DATE") || {
        echo "Error: Invalid due date format. Please use \"MM/DD/YYYY HH:MM AM/PM\"."
        return 1
    }

    checkClonedRepos "$REPO_DIR" "$DEADLINE"
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

    if [[ "$1" == "-h" && "$#" -eq 1 ]]; then
        usage
        return 0
    fi

    # process the command line arguments
    # if no arguments are provided, display usage information and exit
    if [ $# -eq 0 ]; then
        echo "No arguments provided."
        usage
        return 1
    fi

    # reset the option index for getopts
    OPTIND=1

    while getopts ":hO:A:T:C:" opt; do
        case $opt in
            h)
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
                echo "Run 'WSU_classroom -h' for usage information."
                repoGenerationUsage
                return 1
                ;;
            \?)
                echo "Error: Invalid option -$OPTARG"
                echo "Run 'WSU_classroom -h' for usage information."
                repoGenerationUsage
                return 1
                ;;
        esac
    done

    # make sure both an organization and assignment were provided
    if [[ -z "$ORGANIZATION" || -z "$ASSIGNMENT" || -z "$TEMPLATE" || -z "$CSV_FILE" ]]; then
        echo "Error: -O -A -T -C are required."
        repoGenerationUsage
        return 1
    fi

    # check if the user is authenticated with GitHub
    isGitAuth

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
        read -p "Would you like to create repositories for TAs? (Y/N) [N]: " CREATE_TA_REPOS
        CREATE_TA_REPOS="${CREATE_TA_REPOS:-N}"

        read -p "Would you like to grant TAs access to student repositories? (Y/N) [Y]: " GRANT_TA_ACCESS
        GRANT_TA_ACCESS="${GRANT_TA_ACCESS:-Y}"
    fi

    # process the class roster and create repositories
    processRoster "$CSV_FILE" "$ORGANIZATION" "$ASSIGNMENT" "$CURRENT_TERM" "$TEMPLATE" "$CREATE_TA_REPOS" "$GRANT_TA_ACCESS"

    # allows the user to clone the student repositories to their local machine if they want
    echo
    read -p "Would you like to clone the student repositories to your local machine? (Y/N) [N]: " CLONE
    CLONE="${CLONE:-N}"

    if [[ "$CLONE" =~ ^[Yy]$ ]]; then
        cloneRepositories \
        "${ASSIGNMENT}-${CURRENT_TERM}-repo-links.csv" \
        "$ASSIGNMENT" \
        "$CURRENT_TERM"
    else
        echo "Skipping repository cloning."
    fi

    # display a summary of the configuration and actions taken
    configurationSummary "$ORGANIZATION" "$ASSIGNMENT" "$CURRENT_TERM" "$TEMPLATE" "$CSV_FILE" "$CREATE_TA_REPOS" "$GRANT_TA_ACCESS" 
)
