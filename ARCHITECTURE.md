# Architecture

## Root Directory

### `wsu_classroom.sh`

The core file. Creates repositories for students and TAs, grants TAs access to student repositories, and optionally clones the repositories to the local machine at time of repo generation or at a seprate time.

### `classroom_git_checks.sh`

Contains functions used to validate GitHub and user information before repository creation. This includes checking that the GitHub CLI is installed and authenticated, validating organization ownership and GitHub usernames, determining the current academic term, generating repository names, validating the template repository, and processing the class roster.

### `classroom_helper.sh`

Contains helper functions used by the main script and roster processing. This includes creating student and TA repositories, granting TAs access to student repositories, generating email identifiers, exporting generated repository links to a CSV file, checking whether a roster contains TAs, and displaying the configuration summary.

## demo-files

### `demo_no_ta_roster.csv`

Example class roster containing students and an instructor, but no TAs. Used to demonstrate how the script behaves when TA repository creation and TA access are not needed.

### `demo_roster.csv`

Example class roster containing students, TAs, and an instructor. Used to demonstrate the complete repository generation process, including optional TA repository creation and granting TAs access to student repositories.

### `demo_output.csv`

Example of the repository-links CSV generated after student repositories are successfully created. The output contains each student's name and the URL of their generated repository.

## screenshots

Folder containing screenshots of running the script for the README.md file.

