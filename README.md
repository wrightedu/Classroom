# WSU Classroom

## Overview

WSU Classroom is a Bash-based command-line tool designed to simplify the creation and management of GitHub repositories for university courses. It provides an alternative to GitHub Classroom by allowing instructors to create and manage repositories using a class roster and a GitHub template repository.

The tool uses the GitHub CLI to interact with GitHub organizations, create repositories for students, manage repository access for teaching assistants, and generate information instructors can use to manage their course repositories.

## Features

- **Automated Repository Creation** – Creates private repositories for students using a specified GitHub template repository.
- **Roster-Based Creation** – Uses a CSV class roster containing student, TA, and instructor information to determine repository creation and access.
- **Repository Naming** – Automatically generates consistent repository names using the assignment name, student's email identifier, and current academic term. There is also an option to completely override the name that is generated.
- **GitHub Validation** – Verifies GitHub CLI installation and authentication, organization ownership, GitHub usernames, and template repositories before performing repository operations.
- **Teaching Assistant Support** – Optionally creates repositories for TAs and grants TAs read access to student repositories if there are TAs in the roster and is read as a role.
- **Repository Link Export** – Generates a CSV file containing student names and links to their newly created repositories and is sorted alphabetically by last name.
- **Repository Cloning** – Provides the option to clone all created student repositories to a specified local directory. Will also create a directory if you would like one.
- **Configuration Summary** – Displays a summary after processing, including course configuration, roster counts, invalid GitHub usernames, and successfully created repositories.

## Prerequisites

## Installation

## Usage

### Comamnd-Line Options

### Example

## Class Roster Format

### Roles

## Repository Naming

## How it Works

## Generated Output
