# Initializes WSU Classroom configuration in the current course directory
# Inputs:
#       -O ORGANIZATION - GitHub organization (optional)
#       -A ASSIGNMENT - Assignment name (optional)
#       -T TEMPLATE - Template repository (optional)
#       -C CSV_FILE - Class roster (optional)
# Outputs:
#       Creates .wsu_classroom/.env and assignment.conf
# State Changes:
#       Creates or replaces local configuration with confirmation
initClassroom() {
    local ORGANIZATION=""
    local ASSIGNMENT=""
    local TEMPLATE=""
    local CSV_FILE=""
    local CONFIG_DIR=".wsu_classroom"
    local CONFIRM
    local OPTIND=1
    local opt

    while getopts ":hO:A:T:C:" opt; do
        case "$opt" in
            O) ORGANIZATION="$OPTARG" ;;
            A) ASSIGNMENT="$OPTARG" ;;
            T) TEMPLATE="$OPTARG" ;;
            C) CSV_FILE="$OPTARG" ;;
            h)
                echo "Usage: WSU_classroom init [-O org] [-A assignment] [-T owner/repo] [-C roster.csv]"
                return 0
                ;;
            :)
                echo "Error: -$OPTARG requires an argument."
                return 1
                ;;
            \?)
                echo "Error: Invalid option -$OPTARG"
                return 1
                ;;
        esac
    done

    shift $((OPTIND - 1))

    if (( $# > 0 )); then
        echo "Error: Unexpected argument: $1"
        return 1
    fi

    # Warn before overwriting existing configuration
    if [[ -e "$CONFIG_DIR/.env" || -e "$CONFIG_DIR/assignment.conf" ]]; then

        echo "Warning: Existing configuration detected."
        read -r -p "Overwrite configuration? (y/N): " CONFIRM

        if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
            echo "Initialization cancelled."
            return 0
        fi
    fi

    # Prompt for missing configuration values
    while [[ -z "$ORGANIZATION" ]]; do
        read -r -p "GitHub organization: " ORGANIZATION || return 1
    done

    while [[ -z "$ASSIGNMENT" ]]; do
        read -r -p "Assignment name: " ASSIGNMENT || return 1
    done

    while [[ -z "$TEMPLATE" ]]; do
        read -r -p "Template repository (owner/repo): " TEMPLATE || return 1
    done

    while [[ -z "$CSV_FILE" ]]; do
        read -r -p "Roster CSV file: " CSV_FILE || return 1
    done

    # Validate configuration values
    if [[ ! "$ORGANIZATION" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*$ || ! "$ASSIGNMENT" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ || ! "$TEMPLATE" =~ ^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$ ]]; then
        echo "Error: Invalid organization, assignment, or template."
        return 1
    fi

    # Prevent unsafe values in sourced configuration
    if [[ "$CSV_FILE" == *$'\n'* ||
          "$CSV_FILE" == *$'\r'* ]]; then
        echo "Error: Invalid roster path."
        return 1
    fi

    if [[ ! -f "$CSV_FILE" ]]; then
        echo "Warning: Roster '$CSV_FILE' does not exist yet."
    fi

    # Create configuration directory
    if ! mkdir -p "$CONFIG_DIR"; then
        echo "Error: Could not create $CONFIG_DIR."
        return 1
    fi

    # Create temporary configuration files
    local ENV_TMP
    local ASSIGNMENT_TMP

    ENV_TMP=$(mktemp "$CONFIG_DIR/.env.tmp.XXXXXX") || return 1
    ASSIGNMENT_TMP=$(mktemp "$CONFIG_DIR/assignment.tmp.XXXXXX") || {
        rm -f "$ENV_TMP"
        return 1
    }

    chmod 600 "$ENV_TMP" "$ASSIGNMENT_TMP"

    printf 'WSU_ORG=%q\n' "$ORGANIZATION" > "$ENV_TMP"

    {
        printf 'WSU_ASSIGNMENT=%q\n' "$ASSIGNMENT"
        printf 'WSU_TEMPLATE=%q\n' "$TEMPLATE"
        printf 'WSU_CSV=%q\n' "$CSV_FILE"
    } > "$ASSIGNMENT_TMP"

    if ! mv -f "$ENV_TMP" "$CONFIG_DIR/.env" || ! mv -f "$ASSIGNMENT_TMP" "$CONFIG_DIR/assignment.conf"; then
        rm -f "$ENV_TMP" "$ASSIGNMENT_TMP"
        echo "Error: Failed to save configuration."
        return 1
    fi

    # Save or update the assignment-to-template mapping
    local MAPPINGS_FILE="$CONFIG_DIR/assignments.conf"
    local MAPPINGS_TMP

    MAPPINGS_TMP=$(mktemp "$CONFIG_DIR/assignments.tmp.XXXXXX") || return 1

    # Preserve mappings for other assignments
    if [[ -f "$MAPPINGS_FILE" ]]; then
        awk -F= -v assignment="$ASSIGNMENT" \
            '$1 != assignment' "$MAPPINGS_FILE" > "$MAPPINGS_TMP"
    fi

    # Add or update the selected assignment
    printf '%s=%s\n' "$ASSIGNMENT" "$TEMPLATE" >> "$MAPPINGS_TMP"

    if ! mv -f "$MAPPINGS_TMP" "$MAPPINGS_FILE"; then
        rm -f "$MAPPINGS_TMP"
        echo "Error: Failed to save assignment mapping."
        return 1
    fi

    echo
    echo "========================================"
    echo "   WSU CLASSROOM INITIALIZED"
    echo "========================================"
    echo "Organization: $ORGANIZATION"
    echo "Assignment:   $ASSIGNMENT"
    echo "Template:     $TEMPLATE"
    echo "Roster:       $CSV_FILE"
    echo "Directory:    $(pwd)/$CONFIG_DIR"
    echo
    echo "Initialization complete!"
}

# Retrieves the template repository for a given assignment from the assignments.conf file
# Inputs:
#       ASSIGNMENT_NAME - Name of the assignment to retrieve the template for
# Outputs:
#       Prints the template repository in owner/repository format if found
#       Returns 0 if found, 1 if not found or if the configuration file does not exist
# State Changes:
#       None
getAssignmentTemplate() {
    local ASSIGNMENT_NAME="$1"
    local CONFIG_FILE=".wsu_classroom/assignments.conf"
    local NAME
    local TEMPLATE_REPO

    [[ -f "$CONFIG_FILE" ]] || return 1

    while IFS='=' read -r NAME TEMPLATE_REPO || [[ -n "$NAME" ]]; do
        # Ignore empty lines and comments
        [[ -z "$NAME" || "$NAME" == \#* ]] && continue

        if [[ "$NAME" == "$ASSIGNMENT_NAME" ]]; then
            printf '%s\n' "$TEMPLATE_REPO"
            return 0
        fi
    done < "$CONFIG_FILE"

    return 1
}

# Displays the usage information for the WSU Classroom tools
# Inputs:
#       None
# Outputs:
#       Prints usage information for WSU_classroom, cloneRepositories,
#       checkDueDate, and checkInvites commands
# State Changes:
#       None
usage() {
    echo
    echo "                                  WSU Classroom"
    echo "=========================================================================================="
    echo "Usage:"
    echo "  WSU_classroom -O <organization> -A <assignment> -T <template> -C <csv_file>"
    echo "  WSU_classroom init [-O organization] [-A assignment] [-T template] [-C csv_file]"
    echo "  WSU_classroom -h"
    echo
    echo "Required Options:"
    echo "  -O organization   GitHub organization where repositories will be created"
    echo "  -A assignment     Assignment name used when generating repository names"
    echo "  -T template       GitHub template repository in owner/repository format"
    echo "  -C csv_file       Class roster CSV containing Name, Email, Role, and Username"
    echo
    echo "=========================================================================================="
    echo
    echo "Other Options:"
    echo "  -h                Show this help message and exit"
    echo
    echo "=========================================================================================="
    echo
    echo "Additional Commands:"
    echo
    echo "  cloneRepositories"
    echo "      Clone repositories listed in a generated repository-links CSV file."
    echo "      The command prompts for the CSV file and destination directory."
    echo
    echo "  checkDueDate -D \"MM/DD/YYYY [HH:MM AM/PM]\" <repository-directory>"
    echo "      Check cloned student repositories for an eligible push on or before"
    echo "      the assignment deadline."
    echo
    echo "      -D due_date      Assignment deadline."
    echo "                       If no time is provided, defaults to 11:59 PM."
    echo
    echo "  checkInvites -O <organization> -A <assignment> -C <csv_file>"
    echo "      Check student repository invitation statuses and optionally resend"
    echo "      missing or pending invitations."
    echo
    echo "      -O organization   GitHub organization containing the repositories."
    echo "      -A assignment     Assignment name used in repository names."
    echo "      -C csv_file       Class roster CSV containing Name, Email, Role, and Username."
    echo
    echo "  WSU_classroom init"
    echo "      Initialize WSU Classroom in the current course directory."
    echo "      Creates .wsu_classroom/.env and assignment.conf."
    echo "      Prompts for missing configuration values."
    echo
    echo "=========================================================================================="
    return 0
}

# Displays the usage information for the repository generation command
# Inputs:
#       None
# Outputs:
#       Prints usage information for the repository generation command
# State Changes:
#       None
repoGenerationUsage() {
    echo
    echo "Usage: WSU_classroom -O <organization> -A <assignment> -T <template> -C <csv_file>"
    echo
    echo "Required Options:"
    echo "  -O organization   GitHub organization where repositories will be created"
    echo "  -A assignment     Assignment name used when generating repository names"
    echo "  -T template       GitHub template repository in owner/repository format"
    echo "  -C csv_file       Class roster CSV containing Name, Email, Role, and Username"
    echo
    echo "Run 'WSU_classroom -h' for more information."
    return 0
}

# Grants a TA read access to a student's repository
# Inputs:
#       TA - GitHub username of the TA
#       STUDENT_EMAIL - Email address of the student
#       ORGANIZATION - GitHub organization
#       ASSIGNMENT - Assignment name
#       CURRENT_TERM - Current academic term
# Outputs:
#       Grants the TA read access to the student's repository
# State Changes:
#       The TA is granted read access to the student's repository
grantTAAccess() {

    # Declare local variables
    local TA="$1"
    local STUDENT_EMAIL="$2"
    local ORGANIZATION="$3"
    local ASSIGNMENT="$4"
    local CURRENT_TERM="$5"

    local EMAIL_ID
    local REPO_NAME

    EMAIL_ID=$(generateEmailIdentifier "$STUDENT_EMAIL")
    REPO_NAME=$(generateRepoName "$ASSIGNMENT" "$EMAIL_ID" "$CURRENT_TERM")

    echo "Giving $TA read access to $REPO_NAME"

    gh api \
        -X PUT \
        "/repos/$ORGANIZATION/$REPO_NAME/collaborators/$TA" \
        -f permission="pull" >/dev/null </dev/null
}

# Creates a private repository for a student and grants the student write access
# Inputs:
#       NAME - Name of the student
#       EMAIL - Email address of the student
#       USERNAME - GitHub username of the student
#       ORGANIZATION - GitHub organization
#       ASSIGNMENT - Assignment name
#       CURRENT_TERM - Current academic term
#       TEMPLATE - Template repository to use for creating the new repository
# Outputs:
#       Creates a private repository for the student and grants the student write access
# State Changes:
#       A private repository is created for the student, and the student is granted write access
createStudentRepo() {

    # Declare local variables
    local NAME="$1"
    local EMAIL="$2"
    local USERNAME="$3"
    local ORGANIZATION="$4"
    local ASSIGNMENT="$5"
    local CURRENT_TERM="$6"
    local TEMPLATE="$7"

    local EMAIL_ID
    local REPO_NAME

    EMAIL_ID=$(generateEmailIdentifier "$EMAIL")
    REPO_NAME=$(generateRepoName "$ASSIGNMENT" "$EMAIL_ID" "$CURRENT_TERM")

    echo "Creating student repository $REPO_NAME"

    # Create the repository using the specified template and grant the student write access
    if gh repo create "$ORGANIZATION/$REPO_NAME" \
        --template "$TEMPLATE" \
        --private >/dev/null </dev/null
    then
        gh api \
            -X PUT \
            "/repos/$ORGANIZATION/$REPO_NAME/collaborators/$USERNAME" \
            -f permission="push" >/dev/null </dev/null
        return 0
    else
        echo "Error: Failed to create repository $REPO_NAME" >&2
        return 1
    fi
}

# Exports the generated repository links to a CSV file
# Inputs:
#       ASSIGNMENT - Assignment name
#       CURRENT_TERM - Current academic term
#       GENERATED_REPO_LINKS - Array of generated repository links
# Outputs:
#       Creates a CSV file containing the repository links
# State Changes:
#       A CSV file is created containing the repository links
exportRepoLinks() {

    # Declare local variables
    local ASSIGNMENT="$1"
    local CURRENT_TERM="$2"
    
    shift 2

    local GENERATED_REPO_LINKS=("$@")
    local OUTPUT_FILE="${ASSIGNMENT}-${CURRENT_TERM}-repo-links.csv"

    # Check if there are any generated repository links to export
    if [[ ${#GENERATED_REPO_LINKS[@]} -eq 0 ]]; then
        echo "No repositories were created. No links to export."
        return 1
    fi

    # Only write the header when csv file does not exist
    if [[ ! -f "$OUTPUT_FILE" ]]; then
        echo "Name,Repository Link" > "$OUTPUT_FILE"
    fi

    # Sort the generated repository links by name and export them to the CSV file
    printf "%s\n" "${GENERATED_REPO_LINKS[@]}" \
    | awk -F',' '{
        split($1, name, " ")
        print name[length(name)] "," $0
    }' \
    | sort -t',' -k1,1 \
    | cut -d',' -f2- \
    >> "$OUTPUT_FILE"

    echo "Exported repo links to $(pwd)/$OUTPUT_FILE"
}

# Generates a unique identifier from an email address by removing the domain and any periods
# Inputs:
#       EMAIL - Email address to generate the identifier from
# Outputs:
#       Returns the unique identifier derived from the email address
# State Changes:
#       None
generateEmailIdentifier() {

    # Declare local variables
    local EMAIL="$1"
    local IDENTIFIER="${EMAIL%@*}"
    
    IDENTIFIER="${IDENTIFIER//./}"

    echo "$IDENTIFIER"
}

# Creates a private repository for a TA and grants the TA write access
# Inputs:
#       EMAIL - Email address of the TA
#       USERNAME - GitHub username of the TA
#       ORGANIZATION - GitHub organization
#       ASSIGNMENT - Assignment name
#       CURRENT_TERM - Current academic term
# Outputs:
#       Creates a private repository for the TA and grants the TA write access
# State Changes:
#       A private repository is created for the TA, and the TA is granted write access
createTARepo() {

    # Declare local variables
    local EMAIL="$1"
    local USERNAME="$2"
    local ORGANIZATION="$3"
    local ASSIGNMENT="$4"
    local CURRENT_TERM="$5"
    local TEMPLATE="$6"

    local EMAIL_ID
    local REPO_NAME

    EMAIL_ID=$(generateEmailIdentifier "$EMAIL")
    REPO_NAME=$(generateRepoName "$ASSIGNMENT" "$EMAIL_ID" "$CURRENT_TERM")

    echo "Creating TA repository $REPO_NAME"

    if gh repo create "$ORGANIZATION/$REPO_NAME" \
        --template "$TEMPLATE" \
        --private >/dev/null </dev/null
    then
        gh api \
            -X PUT \
            "/repos/$ORGANIZATION/$REPO_NAME/collaborators/$USERNAME" \
            -f permission="push" >/dev/null </dev/null

        return 0
    else
        echo "Error: Failed to create TA repository $REPO_NAME" >&2
        return 1
    fi
}

# Checks if the CSV file contains any TAs
# Inputs:
#       CSV_FILE - CSV file containing names, GitHub usernames, and roles
# Outputs:
#       Returns 0 (true) if the CSV file contains any TAs, otherwise returns 1 (false)
# State Changes:
#       None
hasTAs() {

    # Declare local variables
    local CSV_FILE="$1"
    local NAME
    local EMAIL
    local ROLE
    local USERNAME

    while IFS=',' read -r NAME EMAIL ROLE USERNAME || [[ -n "$NAME" ]]
    do
        ROLE=${ROLE//$'\r'/}

        if [[ "$ROLE" == "TA" ]]; then
            return 0
        fi

    done < "$CSV_FILE"

    return 1
}

# Displays a summary of the configuration and actions taken
# Inputs:
#       ORGANIZATION - GitHub organization
#       ASSIGNMENT - Assignment name
#       CURRENT_TERM - Current academic term
#       TEMPLATE - Template repository to use for creating new repositories
#       CSV_FILE - CSV file containing names, GitHub usernames, and roles
#       CREATE_TA_REPOS - Flag indicating whether to create TA repositories
#       GRANT_TA_ACCESS - Flag indicating whether to grant TAs access to student repositories
# Outputs:
#       Prints a summary of the configuration and actions taken to the console
# State Changes:
#       None
configurationSummary() {

    # Declare local variables
    local ORGANIZATION="$1"
    local ASSIGNMENT="$2"
    local CURRENT_TERM="$3"
    local TEMPLATE="$4"
    local CSV_FILE="$5"
    local CREATE_TA_REPOS="$6"
    local GRANT_TA_ACCESS="$7"
    local STUDENT_COUNT=0
    local TA_COUNT=0
    local INSTRUCTOR_COUNT=0
    local INVALID_USERS=()
    local NAME
    local EMAIL
    local ROLE
    local USERNAME
    local INVALID_USER
    local INVALID_NAME
    local INVALID_EMAIL
    local INVALID_ROLE
    local INVALID_USERNAME
    local REPO_LINKS_FILE="$(pwd)/${ASSIGNMENT}-${CURRENT_TERM}-repo-links.csv"

    while IFS=',' read -r NAME EMAIL ROLE USERNAME || [[ -n "$NAME" ]]
    do
        # Skip header
        [[ "$NAME" == "Name" ]] && continue

        # Remove carriage returns
        NAME=${NAME//$'\r'/}
        EMAIL=${EMAIL//$'\r'/}
        ROLE=${ROLE//$'\r'/}
        USERNAME=${USERNAME//$'\r'/}

        # Skip empty lines
        if [[ -z "$NAME" && -z "$EMAIL" && -z "$ROLE" && -z "$USERNAME" ]]; then
            continue
        fi

        # Count roles
        case "$ROLE" in
            Student)
                ((STUDENT_COUNT++))
                ;;
            TA)
                ((TA_COUNT++))
                ;;
            Teacher | Instructor)
                ((INSTRUCTOR_COUNT++))
                ;;
        esac

        # Store information for invalid GitHub users
        if ! isGitHubUserValid "$USERNAME"; then
            INVALID_USERS+=("$NAME|$EMAIL|$ROLE|$USERNAME")
        fi

    done < "$CSV_FILE"

    echo
    echo "================================================"
    echo "              CONFIGURATION SUMMARY"
    echo "================================================"    
    echo
    echo "Organization:             $ORGANIZATION"
    echo "Assignment:               $ASSIGNMENT"
    echo "Term:                     $CURRENT_TERM"
    echo "Template:                 $TEMPLATE"
    echo "Roster:                   $CSV_FILE"
    echo "Repository Exported to:   $REPO_LINKS_FILE"
    echo
    echo "Students:                 $STUDENT_COUNT"
    echo "TAs:                      $TA_COUNT"
    echo "Instructors:              $INSTRUCTOR_COUNT"
    echo "Invalid usernames:        ${#INVALID_USERS[@]}"
    echo
    echo "Create TA repos:          $CREATE_TA_REPOS"
    echo "Grant TA access:          $GRANT_TA_ACCESS"

    if [[ ${#INVALID_USERS[@]} -gt 0 ]]; then
        echo
        echo "Invalid GitHub users:"

        for INVALID_USER in "${INVALID_USERS[@]}"
        do
            IFS='|' read -r \
                INVALID_NAME \
                INVALID_EMAIL \
                INVALID_ROLE \
                INVALID_USERNAME <<< "$INVALID_USER"

            echo
            echo "  $INVALID_NAME ($INVALID_ROLE)"
            echo "    Email:     $INVALID_EMAIL"
            echo "    Username:  $INVALID_USERNAME"
        done
    fi

    echo
    echo "================================================"  
}

# Formats a due date string into UTC format
# Inputs:
#       DUE_DATE - Due date string in the format "MM/DD/YYYY [HH:MM AM/PM]"
# Outputs:
#       Returns the due date in UTC format "YYYY-MM-DDTHH:MM:SSZ"
# State Changes:
#       None
formatDueDate() {
    local DUE_DATE="$1"
    local DATE_FORMAT
    local LOCAL_TIMESTAMP

    # did the user provide a time? If not, default to 11:59 PM
    case "$DUE_DATE" in
        *[AaPp][Mm])
            # add seconds to the time if not provided
            DUE_DATE="${DUE_DATE% *}:00 ${DUE_DATE##* }"
            ;;
        *)
            # no time provided, default to 11:59 PM
            DUE_DATE="$DUE_DATE 11:59:00 PM"
            ;;
    esac

    DATE_FORMAT="%m/%d/%Y %I:%M:%S %p"

    # if the user is on macOS, we need to parse differently
    if [[ "$(uname)" == "Darwin" ]]; then
        # convert the due date to a local timestamp
        LOCAL_TIMESTAMP=$(date -j -f "$DATE_FORMAT" "$DUE_DATE" "+%s") || return 1

        # convert the timestamp to UTC
        date -u -r "$LOCAL_TIMESTAMP" "+%Y-%m-%dT%H:%M:%SZ"
    else
        # linux / WSL
        date -u -d "$DUE_DATE" "+%Y-%m-%dT%H:%M:%SZ"
    fi
}

# Formats a UTC timestamp into the local timezone
# Inputs:
#       UTC_TIME - UTC timestamp in the format "YYYY-MM-DDTHH:MM:SSZ"
# Outputs:
#       Returns the timestamp in the local timezone in the format "MM/DD/YYYY HH:MM:SS AM/PM"
# State Changes:
#       None
formatLocalTime() {
    local UTC_TIME="$1"
    local TIMESTAMP

    if [[ "$(uname)" == "Darwin" ]]; then
        # Parse the GitHub timestamp as UTC
        TIMESTAMP=$(TZ=UTC date -j -f "%Y-%m-%dT%H:%M:%SZ" \
            "$UTC_TIME" "+%s") || return 1

        # Display the timestamp using the computer's local timezone
        TZ="$(readlink /etc/localtime | sed 's|.*/zoneinfo/||')" \
            date -r "$TIMESTAMP" "+%m/%d/%Y %I:%M:%S %p"
    else
        # Linux / WSL
        date -d "$UTC_TIME" "+%m/%d/%Y %I:%M:%S %p"
    fi
}
