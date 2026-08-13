# Checks if gh is installed to user's system
# Inputs:
#		None
# Outputs:
#		GH is installed or GH isnt installed and prompts user to install it
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

# Checks if the user is authenticated with GitHub using gh
# Inputs:
#		None
# Outputs:
#		GH is authenticated or GH isnt authenticated and prompts user to authenticate
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
                return 1
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
    local GENERATED_REPO_LINKS
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
                    createTARepo "$EMAIL" "$USERNAME" "$ORGANIZATION" "$ASSIGNMENT" "$CURRENT_TERM"
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
