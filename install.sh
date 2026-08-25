#!/bin/bash

set -e

INSTALL_DIR="$HOME/.wsu_classroom"
REPO="wrightedu/Classroom"
BRANCH="main"

echo "======================================"
echo "       WSU Classroom Installer"
echo "======================================"
echo

# check if git is installed

if ! command -v git >/dev/null 2>&1; then
    echo "Error: Git is not installed."
    echo "Please install Git and try again."
    exit 1
fi

echo "Git is installed."

# Check if Python 3 is installed
# Optional requirement, but needed for data parser.

if ! command -v pyhton3 >/dev/null 2>&1; then
    echo "Warning: Python 3 is not installed."
    echo "Python 3 is required to use the Pilot quiz data parser."
    echo "WSU Classroom can still be used without the parser."
    echo
    echo "To install Python 3, visit:"
    echo "https://www.python.org/downloads/"
fi

# check if gh (GitHub CLI) is installed

if ! command -v gh >/dev/null 2>&1; then
    echo "Error: GitHub CLI (gh) is not installed."
    echo "Please install GitHub CLI from:"
    echo "https://cli.github.com/"
    exit 1
fi

echo "GitHub CLI is installed."

# check GitHub authentication

if ! gh auth status >/dev/null 2>&1; then
    echo
    echo "GitHub authentication is required."
    echo "Starting GitHub login..."
    gh auth login
fi

echo "GitHub authentication confirmed."

# install or update WSU Classroom

echo

if [ -d "$INSTALL_DIR/.git" ]; then

    echo "Existing WSU Classroom installation found."
    echo "Checking for updates..."

    git -C "$INSTALL_DIR" fetch origin
    git -C "$INSTALL_DIR" checkout "$BRANCH"
    git -C "$INSTALL_DIR" pull origin "$BRANCH"

    echo
    echo "WSU Classroom is up to date."

elif [ -d "$INSTALL_DIR" ]; then

    echo "Error: $INSTALL_DIR already exists,"
    echo "but it is not a WSU Classroom installation."
    exit 1

else

    echo "Installing WSU Classroom..."

    gh repo clone "$REPO" "$INSTALL_DIR" -- --branch "$BRANCH"

    echo
    echo "WSU Classroom repository installed."

fi

# make main script executable

chmod +x "$INSTALL_DIR/wsu_classroom.sh"

# determine the shell configuration file to update

SHELL_NAME=$(basename "$SHELL")

case "$SHELL_NAME" in
    bash)
        SHELL_CONFIG="$HOME/.bashrc"
        ;;
    zsh)
        SHELL_CONFIG="$HOME/.zshrc"
        ;;
    *)
        echo
        echo "Error: Unsupported shell '$SHELL_NAME'."
        echo "WSU Classroom currently supports Bash and Zsh."
        exit 1
        ;;
esac

touch "$SHELL_CONFIG"

# add WSU Classroom to shell config

SOURCE_LINE="source \"$INSTALL_DIR/wsu_classroom.sh\""

if grep -Fq "$SOURCE_LINE" "$SHELL_CONFIG"; then
    echo "WSU Classroom is already configured in $SHELL_CONFIG."
else
    echo >> "$SHELL_CONFIG"
    echo "# WSU Classroom" >> "$SHELL_CONFIG"
    echo "$SOURCE_LINE" >> "$SHELL_CONFIG"

    echo "Added WSU Classroom to $SHELL_CONFIG."
fi

# installation complete

echo
echo "======================================"
echo "       Installation Complete!"
echo "======================================"
echo
echo "WSU Classroom is installed at:"
echo "  $INSTALL_DIR"
echo
echo "To finish setup, restart your terminal"
echo "or run:"
echo
echo "  source \"$SHELL_CONFIG\""
echo
echo "Then test WSU Classroom with:"
echo
echo "  WSU_classroom -h"
echo
