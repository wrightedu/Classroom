# Checks if the user is authenticated with GitHub using gh
# Inputs:
#		None
# Outputs:
#		GH is authenticated or GH isnt authenticated and prompts user to authenticate
# State Changes:
#		None
isGitAuth() {

    local choice

    if gh auth status >/dev/null 2>&1; then
		echo "GH is authenticated with GitHub."
		return 0
    else
		echo "GH is not authenticated with GitHub."
        read -p "Would you like to log in now? (Y/N): " choice
		
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            gh auth login
        fi
    fi
}

# Checks if the user is an owner of the specified GitHub organization
# Inputs:
#		ORGANIZATION - the name of the GitHub organization
# Outputs:
#		Prints message whether the user is an owner of the organization or not
# State Changes:
#		None
checkOrganizationOwnership() {

    # Declare local variables
    local ORGANIZATION="$1"
    local USERNAME
    local ROLE

    USERNAME=$(gh api user --jq '.login')
    ROLE=$(gh api "/orgs/$ORGANIZATION/memberships/$USERNAME" --jq '.role' 2>/dev/null)

    if [ $? -ne 0 ]; then
        echo "$USERNAME is not a part of the $ORGANIZATION organization."
        return 1
    fi

    if [ "$ROLE" != "admin" ]; then
        echo "$USERNAME is not an owner of $ORGANIZATION"
        return 1
    fi

    echo "$USERNAME is an owner of the $ORGANIZATION"
}

# Checks if the specified GitHub username is valid
# Inputs:
#		USERNAME - the GitHub username to check
# Outputs:
#		Returns 0 if the username is valid, 1 if not
# State Changes:
#		None
isGitHubUserValid() {
	local USERNAME="$1"

    if gh api "users/$USERNAME" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Determines the current academic term based on the current date of local system
# Inputs:
#		None
# Outputs:
#		Prints the current academic term in the format of fYY, sYY, or suYY
# State Changes:
#		None
getCurrentTerm() {

    # Declare local variables
    local CURRENT_TERM=0
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
    echo "$CURRENT_TERM"
}

# Generates a repository name based on the assignment name, email identifier, and current term
# Inputs:
#		ASSIGNMENT - the assignment name
#		USERNAME - the email identifier (derived from the student's email)
#		TERM - the current academic term
# Outputs:
#		Prints the generated repository name in the format of assignment-emailidentifier-term
# State Changes:
#		None
generateRepoName() {
    
    # Declare local variables
    local ASSIGNMENT="$1"
    local USERNAME="$2"
    local TERM="$3"
    local REPO_NAME

    REPO_NAME="${ASSIGNMENT}-${USERNAME}-${TERM}"
    echo "$REPO_NAME"
}

# Allows the user to edit the assignment name and/or term for repository naming
# Inputs:
#		ASSIGNMENT - the assignment name
#		CURRENT_TERM - the current academic term
# Outputs:
#		Prints the final assignment name and term after user edits
# State Changes:
#		None
editRepoName() {

    # Declare local variables
    local ASSIGNMENT="$1"
    local CURRENT_TERM="$2"

    local REPO_NAME
    local choice

    REPO_NAME="${ASSIGNMENT}-email-${CURRENT_TERM}"

    # Allow the user to edit the assignment name and/or term for repository naming
    while true
    do
        echo
        echo "Based on your input, repository names will be in the following format:"
        echo "$REPO_NAME"
        echo
        echo "1. Use default format"
        echo "2. Edit assignment name (currently \`$ASSIGNMENT\`)"
        echo "3. Edit term (currently \`$CURRENT_TERM\`)"
        echo "4. Cancel and exit"
        echo

        read -p "Enter your choice (1-4): " choice

        case $choice in
            1)
                break
                ;;
            2)
                read -p "Enter new assignment name: " ASSIGNMENT
                REPO_NAME="${ASSIGNMENT}-email-${CURRENT_TERM}"
                ;;
            3)
                read -p "Enter new term (e.g., f26, s27, su27): " CURRENT_TERM
                REPO_NAME="${ASSIGNMENT}-email-${CURRENT_TERM}"
                ;;
            4)
                echo "Exiting..."
                exit 1
                ;;
            *)
                echo "Invalid choice. Please enter a number between 1 and 4."
                ;;
        esac
    done

    echo "$ASSIGNMENT,$CURRENT_TERM"
}

# Checks if the specified template repository exists and is a template repository
# Inputs:
#		TEMPLATE - the name of the template repository (in the format owner/repo)
# Outputs:
#		Prints message whether the template repository exists and is a template repository or not
# State Changes:
#		None
checkTemplateRepo() {
    local TEMPLATE="$1"
    if ! gh repo view "$TEMPLATE" >/dev/null 2>&1; then
        echo "Error: Template repository '$TEMPLATE' does not exist."
        return 1
    fi

    if [[ "$(gh api "repos/$TEMPLATE" --jq '.is_template')" != "true" ]]; then
        echo "Error: '$TEMPLATE' is not a template repository."
        return 1
    fi

    echo "Using template repository: $TEMPLATE"
}

# Processes the CSV file containing names, GitHub usernames, and roles, and creates repositories accordingly
# Inputs:
#		CSV_FILE - CSV file containing names, GitHub usernames, and roles
#		ORGANIZATION - GitHub organization
#		ASSIGNMENT - Assignment name
#		CURRENT_TERM - Current academic term
#		TEMPLATE - Template repository to use for creating new repositories
#		CREATE_TA_REPOS - Flag indicating whether to create TA repositories (Y/N)
#		GRANT_TA_ACCESS - Flag indicating whether to grant TAs access to student repositories (Y/N)
# Outputs:
#		Creates repositories for students and TAs, and grants access to TAs if specified
# State Changes:
#		Repositories are created for students and TAs, and TAs are granted access to student repositories if specified
processRoster() {

    # Declare local variables
    local CSV_FILE="$1"
    local ORGANIZATION="$2"
    local ASSIGNMENT="$3"
    local CURRENT_TERM="$4"
    local TEMPLATE="$5"
    local CREATE_TA_REPOS="$6"
    local GRANT_TA_ACCESS="$7"

    local TAS=()
    local STUDENTS=()
    local USED_EMAIL_IDS=()

    local NAME
    local EMAIL
    local ROLE
    local USERNAME
    local EMAIL_ID
    local USED
    local TA
    local TA_USERNAME
    local STUDENT
    local STUDENT_EMAIL
    local GENERATED_REPO_LINKS=()
    local REPO_NAME

    # Read the CSV file line by line, skipping the header, and process each entry
    while IFS=',' read -r NAME EMAIL ROLE USERNAME || [[ -n "$NAME" ]]
    do
        [[ "$NAME" == "Name" ]] && continue

        NAME=${NAME//$'\r'/}
        EMAIL=${EMAIL//$'\r'/}
        ROLE=${ROLE//$'\r'/}
        USERNAME=${USERNAME//$'\r'/}

        EMAIL_ID=$(generateEmailIdentifier "$EMAIL")

        # Check for duplicate email identifiers and report an error if found
        for USED in "${USED_EMAIL_IDS[@]}"
        do
            if [[ "$USED" == "$EMAIL_ID" ]]; then
                echo "Error: Duplicate repository identifier '$EMAIL_ID'."
                return 1
            fi
        done

        USED_EMAIL_IDS+=("$EMAIL_ID")

        # Check if the GitHub username is valid; if not, skip to the next entry
        if ! isGitHubUserValid "$USERNAME"; then
            echo "Skipping invalid GitHub username: $USERNAME"
            continue
        fi

        # Create repositories based on the role of the user (Student, TA, or Instructor/Teacher)
        case "$ROLE" in
            Student)
                STUDENTS+=("$EMAIL:$USERNAME")

                if createStudentRepo "$NAME" "$EMAIL" "$USERNAME" "$ORGANIZATION" "$ASSIGNMENT" "$CURRENT_TERM" "$TEMPLATE"
                then
                    REPO_NAME=$(generateRepoName "$ASSIGNMENT" "$EMAIL_ID" "$CURRENT_TERM")
                    GENERATED_REPO_LINKS+=("$NAME,https://github.com/$ORGANIZATION/$REPO_NAME")
                fi
                ;;

            TA)
                TAS+=("$EMAIL:$USERNAME")

                if [[ "$CREATE_TA_REPOS" =~ ^[Yy]$ ]]; then
                    createTARepo "$EMAIL" "$USERNAME" "$ORGANIZATION" "$ASSIGNMENT" "$CURRENT_TERM" "$TEMPLATE"
                fi
                ;;

            Teacher | Instructor)
                echo "$USERNAME is the instructor. No repository created."
                ;;

            *)
                echo "Unknown role: $ROLE"
                ;;
        esac

    done < "$CSV_FILE"

    if [[ "$GRANT_TA_ACCESS" =~ ^[Yy]$ ]]; then
        echo
        echo "Granting TA access..."

        for TA in "${TAS[@]}"
        do
            TA_USERNAME="${TA##*:}"

            for STUDENT in "${STUDENTS[@]}"
            do
                STUDENT_EMAIL="${STUDENT%%:*}"

                grantTAAccess "$TA_USERNAME" "$STUDENT_EMAIL" "$ORGANIZATION" "$ASSIGNMENT" "$CURRENT_TERM"
            done
        done
    fi

    exportRepoLinks "$ASSIGNMENT" "$CURRENT_TERM" "${GENERATED_REPO_LINKS[@]}"
}

# Checks if the specified GitHub user has pushed to the specified repository before the given deadline
# Inputs:
#		REPO - the repository name (in the format owner/repo)
#		USERNAME - the GitHub username to check for pushes
#		DEADLINE - the deadline timestamp in ISO 8601 format (e.g., 2024-06-30T23:59:59Z)
# Outputs:
#		Prints whether the user has pushed to the repository before the deadline or not
# State Changes:
#		None
checkRepoDueDate() {
    local REPO="$1"
    local USERNAME="$2"
    local DEADLINE="$3"
    local ISSUE_TITLE="$4"

    local PUSH_DATA
    local PUSH_TIME
    local PUSH_ACTOR
    local PUSH_SHA
    local PUSH_REF
    local LOCAL_PUSH_TIME
    local FOUND_LATE=false

    local RED='\033[0;31m'
    local GREEN='\033[0;32m'
    local YELLOW='\033[0;33m'
    local NC='\033[0m'

    PUSH_DATA=$(gh api \
        "repos/$REPO/activity?activity_type=push" \
        --paginate \
        --jq '.[] | [.timestamp, .actor.login, .after, .ref] | @tsv')

    while IFS=$'\t' read -r PUSH_TIME PUSH_ACTOR PUSH_SHA PUSH_REF; do

        if [[ "$PUSH_ACTOR" != "$USERNAME" ]]; then
            continue
        fi

        if [[ "$PUSH_REF" != "refs/heads/main" ]]; then
            continue
        fi

        LOCAL_PUSH_TIME=$(formatLocalTime "$PUSH_TIME")
        echo "Checking push: $LOCAL_PUSH_TIME"

        # Push was on time
        if [[ "$PUSH_TIME" < "$DEADLINE" || "$PUSH_TIME" == "$DEADLINE" ]]; then

            # A newer late push was found before this valid push
            if [[ "$FOUND_LATE" == true ]]; then
                printf "${YELLOW}LATE - Using previous on-time push${NC}\n"
            else
                printf "${GREEN}GOOD${NC}\n"
            fi

            echo "Push time: $LOCAL_PUSH_TIME"
            echo "Accepted SHA: $PUSH_SHA"

            # Roll the local grading copy back to the accepted push
            echo "Rolling back to the accepted push..."

            if ! git reset --hard "$PUSH_SHA"; then
                echo "Error: Failed to roll repository back to accepted push."
                return 1
            fi

            # Create an issue only if a late push required a rollback
            if [[ "$FOUND_LATE" == true && -n "$ISSUE_TITLE" ]]; then
                echo "Creating GitHub issue..."

                if ! gh issue create \
                    --repo "$REPO" \
                    --title "$ISSUE_TITLE" \
                    --body "A push was made after the assignment deadline.

The commit being graded is: $PUSH_SHA

Accepted push time: $LOCAL_PUSH_TIME"; then
                    echo "Error: Failed to create GitHub issue."
                    return 1
                fi
            fi

            return 0
        fi

        # Push occurred after the deadline
        FOUND_LATE=true
        printf "${RED}LATE${NC} - Checking previous push...\n"

    done <<< "$PUSH_DATA"

    # No valid push was found
    if [[ "$FOUND_LATE" == true ]]; then
        printf "${RED}LATE - No push found on or before the deadline.${NC}\n"
    else
        printf "${RED}NO SUBMISSION - No push found on or before the deadline.${NC}\n"
    fi

    # Create a no-submission issue if -I was provided
    if [[ -n "$ISSUE_TITLE" ]]; then
        echo "Creating GitHub issue..."

        if ! gh issue create \
            --repo "$REPO" \
            --title "$ISSUE_TITLE" \
            --body "No valid submission was found on or before the assignment deadline.

There is no commit eligible to be graded."; then
            echo "Error: Failed to create GitHub issue."
            return 1
        fi
    fi

    return 1
}

# Checks all cloned repositories in the specified directory for pushes before the given deadline
# Inputs:
#		REPO_DIR - Directory containing the cloned repositories
#		DEADLINE - the deadline timestamp in ISO 8601 format (e.g., 2024-06-30T23:59:59Z)
# Outputs:
#		Prints the status of each repository regarding pushes before the deadline
# State Changes:
#		None
checkClonedRepos() {
    local REPO_DIR="$1"
    local DEADLINE="$2"
    local ISSUE_TITLE="$3"
    local REPO

    # Check if the specified directory exists
    if [[ ! -d "$REPO_DIR" ]]; then
        echo "Error: Directory '$REPO_DIR' does not exist." >&2
        return 1
    fi

    # Iterate through each subdirectory in the specified directory
    for REPO in "$REPO_DIR"/*; do

        # Check if the subdirectory is a valid Git repository
        if [[ ! -d "$REPO" ]]; then
            continue
        fi

        # Check if the subdirectory is a Git repository by looking for the .git directory
        if [[ ! -d "$REPO/.git" ]]; then
            echo "Warning: '$REPO' is not a Git repository."
            continue
        fi

        echo
        echo "Checking repository: $(basename "$REPO")"

        # Use a subshell to avoid changing the current working directory of the main script
        (
            local GITHUB_REPO
            local USERNAME

            cd "$REPO" || exit 1

            echo "Pulling latest changes..."

            if ! git pull; then
                echo "Error: Failed to pull latest changes for $(basename "$REPO")." >&2
                exit 1
            fi

            # Determine the GitHub repository from the current clone
            GITHUB_REPO=$(gh repo view \
                --json nameWithOwner \
                --jq '.nameWithOwner')

            if [[ -z "$GITHUB_REPO" ]]; then
                echo "Error: Unable to determine GitHub repository."
                exit 1
            fi

            # Look for a student who has accepted their repository invitation.
            # Students receive push access while organization owners have admin access.
            USERNAME=$(gh api \
                "repos/$GITHUB_REPO/collaborators" \
                --jq '.[] |
                    select(.permissions.push == true and .permissions.admin == false) |
                    .login' \
                | head -n 1)

            # If the student has not accepted the invitation yet,
            # look for the pending write invitation instead.
            if [[ -z "$USERNAME" ]]; then
                USERNAME=$(gh api \
                    "repos/$GITHUB_REPO/invitations" \
                    --jq '.[] |
                        select(.permissions == "write") |
                        .invitee.login' \
                    | head -n 1)
            fi

            if [[ -z "$USERNAME" ]]; then
                echo "Warning: Unable to determine student GitHub username."
                exit 1
            fi

            echo "Student: $USERNAME"

            checkRepoDueDate "$GITHUB_REPO" "$USERNAME" "$DEADLINE" "$ISSUE_TITLE"
        )
    done
}
