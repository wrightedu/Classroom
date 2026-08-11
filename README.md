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

- Bash
- Git
- GitHub CLI & Authernitcated
- GitHub Organization Access
- Template Repository
- Class Roster CSV File

## Installation

1. **Clone the Repository**

Clone the WSU Classroom repository to your local machine:

```bash
git clone git@github.com:wrightedu/Classroom.git
```

Then navigate into the cloned repository.

2. **Keep the Repository Up to Date**

Before using WSU Classroom, make sure your local copy is up to date:

```bash
git pull
```

3. **Source WSU Classroom**

WSU Classroom is intended to be sourced so that the `WSU_classroom` command is available from the user's shell.

Add the following line to your `~/.bashrc`, replacing the path with the location of your cloned WSU Classroom repository:

```bash
source /path/to/wsu-classroom/wsu_classroom.sh
```

4. **Reload the Shell Configuration**

After updating `~/.bashrc`, reload the configuration:

```bash
source ~/.bashrc
```


Alternatively, close and reopen the terminal.

Once configured, the `WSU_classroom` command will be available from the command line.

## Usage

Once WSU Classroom has been installed and configured, run the tool using the `WSU_classroom `command.

```bash
WSU_classroom -O <organization> -A <assignment> -T <template> -C <csv_file>
```

**Options**

| Option | Description |
| --- | --- |
| `-h` | Displays the help message and exits. |
| `-O` | Specifies the GitHub organization where repositories will be created. |
| `-A` | Specifies the assignment name used when generating repository names. |
| `-T` | Specifies the GitHub template repository used to create repositories. |
| `-C` | Specifies the CSV file containing the class roster. |

> [!IMPORTANT]  
> The `-O`, `-A`, `-T`, and `-C` options are required.

### Comamnd-Line Options

### Example

## Class Roster Format

### Roles

## Repository Naming

## How it Works

## Generated Output
