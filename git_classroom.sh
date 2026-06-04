#!/bin/bash

# Check if the gh is installed.
isGitInstalled(){
	# Get git version, discard output, and get exit code
	if gh --version >/dev/null 2>&1; then
		echo "Git(gh) is installed."
	else
		echo "Git(gh) is not installed."

		# Ask user if they want to install git 
		read -p "Install Git(gh) now? (Y/N): " choice
	
	# Check if the user entered y or Y.
    	if [[ "$choice" =~ ^[Yy]$ ]]; then
        	sudo apt update
        	sudo apt install gh
    		fi
	fi	
}

# Check if gh is authenticated with a GitHub account.
isGitAuth(){
	# Get git auth status, discard output, and get exit code
    	if gh auth status >/dev/null 2>&1; then
		echo "Git(gh) is authenticated with GitHub."
    	else
		echo "Git(gh) is not authenticated with GitHub."

        # Ask the user if they want to log in.
        read -p "Would you like to log in now? (Y/N): " choice

        # Check if the user entered y or Y.
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            gh auth login
        fi
    fi
}

# Main

# if git is intalled run git authenticator
if isGitInstalled; then
    isGitAuth
fi

