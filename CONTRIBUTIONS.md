# Contributing

## Background Knowledge

Read through the [Architecture Guide](ARCHITECTURE.md) before making any contributions.

## Standards

All code should comply with a modified version of the [PEP-8 standard](https://pep8.org/), excluding line lengths. Keep line lengths to around 100 characters. No hard limit.

All Bash code should follow the existing formatting and organization used throughout the project.

Functions should include comments describing their purpose, inputs, outputs, and state changes using the following format:

```bash
# Description of what the function does
# Inputs:
#       VARIABLE - Description of the input
# Outputs:
#       Description of the function's output or behavior
# State Changes
#       Description of what changed in the function
functionName() {
    ...
}
```

### Function Placement

Place new functions in the file that best matches their responsibility.

- `wsu_classroom.sh` should contain the main program flow and user interaction.
- `classroom_git_checks.sh` should contain validation, checking, naming, and roster-processing logic.
- `classroom_helper.sh` should contain supporting operations used by the other scripts.

## Workspace Setup

### Dependencies

This project requires Bash and the GitHub CLI (`gh`).

The GitHub CLI must be installed before the script can run. The script automatically checks for the GitHub CLI when it starts.

Installation instructions for the GitHub CLI can be found in the [GitHub CLI documentation.](https://cli.github.com/)

Read through the [README](README.md) before making any contributions for script setup and more details on versionings.

## Workflow

1. [Fork](https://docs.github.com/en/get-started/quickstart/fork-a-repo) this repository
2. [Create a branch](https://docs.github.com/en/github/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-and-deleting-branches-within-your-repository) off the development branch for the edits you wish to make
3. Make a [pull request](https://docs.github.com/en/github/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request) in this repository from your branch to the development branch of this repository.
