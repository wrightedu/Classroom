# GitHub Classroom Replacement Script

A Bash script that automates the creation of student GitHub repositories for a course using the GitHub CLI (`gh`).

## Features

- Verifies that `gh` is installed
- Verifies that the user is authenticated with GitHub
- Verifies that the authenticated user is an owner of the specified GitHub organization
- Generates repositories based off the supplied CSV file and uses consistent naming conventions such as: `assignment-githubusername-term`

## Requirements

- Bash
- GitHub CLI (`gh`)
- GitHub CLI authenticated with an account that is an organization owner -> `gh auth login`
- CSV File of students containin: Name, GitHub Username, Role
- Specified path for your template repository
    - If the template repository is withing your organization, the path must specify that: WSU-YOUR_ORGANIZATION_NAME/template-repo-name

