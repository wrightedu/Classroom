# Gives TA's read access to every student's repo
# Inputs:
#       TA - GitHub username of the TA
#       STUDENT - GitHub username of the student
# Outputs:
#       Grants the TA read access to the student's repository
grantTAAccess() {

    local TA="$1"
    local STUDENT="$2"

    getCurrentTerm
    generateRepoName "$ASSIGNMENT" "$STUDENT" "$CURRENT_TERM"

    echo "Giving $TA read access to $REPO_NAME"

    gh api \
        -X PUT \
        "/repos/$ORGANIZATION/$REPO_NAME/collaborators/$TA" \
        -f permission="pull" </dev/null
}

# Creates a private repo for a student
# Inputs:
#       USERNAME - GitHub username of the student
# Outputs:
#       Creates a private repository and grants the student write access
createStudentRepo() {

    local USERNAME="$1"

    getCurrentTerm
    generateRepoName "$ASSIGNMENT" "$USERNAME" "$CURRENT_TERM"

    echo "Creating student repository $REPO_NAME"

    gh repo create "$ORGANIZATION/$REPO_NAME" \
        --template "$TEMPLATE" \
        --private </dev/null

    # Give the student write access
    gh api \
        -X PUT \
        "/repos/$ORGANIZATION/$REPO_NAME/collaborators/$USERNAME" \
        -f permission="push" </dev/null
}

#! How are we formatting TA Repo's/ Do they even need repos
# Creates a private repo for a TA
# Inputs:
#       USERNAME - GitHub username of the TA
# Outputs:
#       Creates a private repository and grants the TA write access
createTARepo() {

    local USERNAME="$1"

    getCurrentTerm
    generateRepoName "$ASSIGNMENT" "$USERNAME" "$CURRENT_TERM"

    echo "Creating TA repository $REPO_NAME"

    gh repo create "$ORGANIZATION/$REPO_NAME" --private </dev/null

    # Give the TA write access to their own repository
    gh api \
        -X PUT \
        "/repos/$ORGANIZATION/$REPO_NAME/collaborators/$USERNAME" \
        -f permission="push" </dev/null
}
