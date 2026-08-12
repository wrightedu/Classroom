GENERATED_REPO_LINKS=()
SUCCESSFUL_REPOS=()

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
    return 0
}

# Gives TA's read access to every student's repo
# Inputs:
#       TA - GitHub username of the TA
#       STUDENT - GitHub username of the student
# Outputs:
#       Grants the TA read access to the student's repository
grantTAAccess() {

    local TA="$1"
    local STUDENT_EMAIL="$2"

    local EMAIL_ID=$(generateEmailIdentifier "$STUDENT_EMAIL")

    local CURRENT_TERM=$(getCurrentTerm)
    generateRepoName "$ASSIGNMENT" "$EMAIL_ID" "$CURRENT_TERM"

    echo "Giving $TA read access to $REPO_NAME"

    gh api \
        -X PUT \
        "/repos/$ORGANIZATION/$REPO_NAME/collaborators/$TA" \
        -f permission="pull" >/dev/null </dev/null
}

# Creates a private repo for a student
# Inputs:
#       NAME - Name of the student
#       EMAIL - Email address of the student
#       USERNAME - GitHub username of the student
# Outputs:
#       Creates a private repository and grants the student write access
#       Adds the repository link to GENERATED_REPO_LINKS
createStudentRepo() {

    local NAME="$1"
    local EMAIL="$2"
    local USERNAME="$3"

    local EMAIL_ID=$(generateEmailIdentifier "$EMAIL")

    local CURRENT_TERM=$(getCurrentTerm)
    generateRepoName "$ASSIGNMENT" "$EMAIL_ID" "$CURRENT_TERM"

    echo "Creating student repository $REPO_NAME"

    if gh repo create "$ORGANIZATION/$REPO_NAME" \
        --template "$TEMPLATE" \
        --private >/dev/null </dev/null
    then
        ((SUCCESSFUL_REPOS++))

        gh api \
            -X PUT \
            "/repos/$ORGANIZATION/$REPO_NAME/collaborators/$USERNAME" \
            -f permission="push" >/dev/null </dev/null

        GENERATED_REPO_LINKS+=(
            "$NAME,https://github.com/$ORGANIZATION/$REPO_NAME"
        )
    else
        echo "Error: Failed to create repository $REPO_NAME"
    fi
}

# Exports the generated repository links to a text file
# Inputs:
#       None
# Outputs:
#       Creates a text file containing the links to the generated repositories in the format "Name,Repository Link" and sorts them alphabetically by name
exportRepoLinks() {
    local OUTPUT_FILE="${ASSIGNMENT}-${CURRENT_TERM}-repo-links.csv"

    if [[ ${#GENERATED_REPO_LINKS[@]} -eq 0 ]]; then
        echo "No repositories were created. No links to export."
        return
    fi

    echo "Name,Repository Link" > "$OUTPUT_FILE"

    printf "%s\n" "${GENERATED_REPO_LINKS[@]}" \
        | awk -F',' '{
            split($1, name, " ")
            print name[length(name)] "," $0
        }' \
        | sort -t',' -k1,1 \
        | cut -d',' -f2- \
        >> "$OUTPUT_FILE"

    echo "Repository links exported to $OUTPUT_FILE"
}

# Generates an identifier from an email address by extracting the part before the '@' symbol
# Inputs:
#       EMAIL - Email address of the student
# Outputs:
#       Returns the identifier (part before '@') of the email address
generateEmailIdentifier() {

    local EMAIL="$1"
    local IDENTIFIER="${EMAIL%@*}"
    IDENTIFIER="${IDENTIFIER//./}"

    echo "$IDENTIFIER"
}

#! How are we formatting TA Repo's/ Do they even need repos
# Creates a private repo for a TA
# Inputs:
#       USERNAME - GitHub username of the TA
# Outputs:
#       Creates a private repository and grants the TA write access
createTARepo() {

    local EMAIL="$1"
    local USERNAME="$2"

    local EMAIL_ID=$(generateEmailIdentifier "$EMAIL")

    local CURRENT_TERM=$(getCurrentTerm)
    generateRepoName "$ASSIGNMENT" "$EMAIL_ID" "$CURRENT_TERM"

    echo "Creating TA repository $REPO_NAME"

    gh repo create "$ORGANIZATION/$REPO_NAME" \
        --private >/dev/null </dev/null

    gh api \
        -X PUT \
        "/repos/$ORGANIZATION/$REPO_NAME/collaborators/$USERNAME" \
        -f permission="push" >/dev/null </dev/null
}

# Checks if there are any TAs in the CSV file
# Inputs:
#       CSV_FILE - CSV file containing names, GitHub usernames, and roles
# Outputs:
#       Returns 0 if there are TAs, 1 otherwise
hasTAs() {
    while IFS=',' read -r NAME EMAIL ROLE USERNAME || [[ -n "$NAME" ]]
    do
        ROLE=${ROLE//$'\r'/}
        if [[ "$ROLE" == "TA" ]]; then
            return 0
        fi
    done < "$CSV_FILE"

    return 1
}

# Displays a summary of the configuration and results
# Inputs:
#       ORGANIZATION - GitHub organization
#       ASSIGNMENT - Assignment name
#       CURRENT_TERM - Current academic term
#       TEMPLATE - Template repository
#       CSV_FILE - Class roster CSV file
#       CREATE_TA_REPOS - Whether TA repositories were created
#       GRANT_TA_ACCESS - Whether TAs received access to student repositories
#       SUCCESSFUL_REPOS - Number of successfully created student repositories
# Outputs:
#       Prints a summary of the configuration and results, including counts of students, TAs,
configurationSummary() {

    local STUDENT_COUNT=0
    local TA_COUNT=0
    local INSTRUCTOR_COUNT=0

    INVALID_USERNAMES=()

    while IFS=',' read -r NAME EMAIL ROLE USERNAME || [[ -n "$NAME" ]]
    do
        # Skip header
        [[ "$NAME" == "Name" ]] && continue

        NAME=${NAME//$'\r'/}
        EMAIL=${EMAIL//$'\r'/}
        ROLE=${ROLE//$'\r'/}
        USERNAME=${USERNAME//$'\r'/}

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

        # Check for invalid GitHub usernames
        if ! isGitHubUserValid "$USERNAME"; then
            INVALID_USERNAMES+=("$USERNAME")
        fi

    done < "$CSV_FILE"

    echo
    echo "========================================"
    echo "        CONFIGURATION SUMMARY"
    echo "========================================"
    echo
    echo "Organization:          $ORGANIZATION"
    echo "Assignment:            $ASSIGNMENT"
    echo "Term:                  $CURRENT_TERM"
    echo "Template:              $TEMPLATE"
    echo "Roster:                $CSV_FILE"
    echo
    echo "Students:              $STUDENT_COUNT"
    echo "TAs:                   $TA_COUNT"
    echo "Instructors:           $INSTRUCTOR_COUNT"
    echo "Invalid usernames:     ${#INVALID_USERNAMES[@]}"
    echo "Successful repos:      $SUCCESSFUL_REPOS"
    echo
    echo "Create TA repos:       $CREATE_TA_REPOS"
    echo "Grant TA access:       $GRANT_TA_ACCESS"
    echo

    if [[ ${#INVALID_USERNAMES[@]} -gt 0 ]]; then
        echo
        echo "Invalid GitHub usernames:"

        for USERNAME in "${INVALID_USERNAMES[@]}"
        do
            echo "  - $USERNAME"
        done
    fi

    echo
    echo "========================================"
}
