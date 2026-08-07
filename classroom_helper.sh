GENERATED_REPO_LINKS=()

# Gives TA's read access to every student's repo
# Inputs:
#       TA - GitHub username of the TA
#       STUDENT - GitHub username of the student
# Outputs:
#       Grants the TA read access to the student's repository
grantTAAccess() {

    local TA="$1"
    local STUDENT_EMAIL="$2"

    local EMAIL_ID
    EMAIL_ID=$(generateEmailIdentifier "$STUDENT_EMAIL")

    getCurrentTerm
    generateRepoName "$ASSIGNMENT" "$EMAIL_ID" "$CURRENT_TERM"

    echo "Giving $TA read access to $REPO_NAME"

    gh api \
        -X PUT \
        "/repos/$ORGANIZATION/$REPO_NAME/collaborators/$TA" \
        -f permission="pull" >/dev/null </dev/null
}

# Creates a private repo for a student
# Inputs:
#       USERNAME - GitHub username of the student
# Outputs:
#       Creates a private repository and grants the student write access
createStudentRepo() {

    local EMAIL="$1"
    local USERNAME="$2"

    local EMAIL_ID
    EMAIL_ID=$(generateEmailIdentifier "$EMAIL")

    getCurrentTerm
    generateRepoName "$ASSIGNMENT" "$EMAIL_ID" "$CURRENT_TERM"

    echo "Creating student repository $REPO_NAME"

    gh repo create "$ORGANIZATION/$REPO_NAME" \
        --template "$TEMPLATE" \
        --private >/dev/null </dev/null

    gh api \
        -X PUT \
        "/repos/$ORGANIZATION/$REPO_NAME/collaborators/$USERNAME" \
        -f permission="push" >/dev/null </dev/null

    GENERATED_REPO_LINKS+=("https://github.com/$ORGANIZATION/$REPO_NAME")
}

# Exports the generated repository links to a text file
# Inputs:
#       None
# Outputs:
#       Creates a text file containing the links to the generated repositories
exportRepoLinks() {
    local OUTPUT_FILE="${ASSIGNMENT}-${CURRENT_TERM}-repo-links.txt"

    if [[ ${#GENERATED_REPO_LINKS[@]} -eq 0 ]]; then
        echo "No repositories were created. No links to export."
        return
    fi

    printf "%s\n" "${GENERATED_REPO_LINKS[@]}" > "$OUTPUT_FILE"
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

    local EMAIL_ID
    EMAIL_ID=$(generateEmailIdentifier "$EMAIL")

    getCurrentTerm
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
