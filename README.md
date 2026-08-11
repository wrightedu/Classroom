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
- GitHub CLI & Authenticated
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

**Flags**

| Option | Argument | Description |
| --- | --- | --- |
| `-h` | None | Displays the help message and exits. |
| `-O` | Organization | Specifies the GitHub organization where repositories will be created. |
| `-A` | Assignment | Specifies the assignment name used to generate repository names. |
| `-T` | Template | Specifies the GitHub template repository used to create student repositories. |
| `-C` | CSV File | Specifies the class roster CSV file to process. |

> [!IMPORTANT]  
> The `-O`, `-A`, `-T`, and `-C` options are required.

When the command is run, WSU Classroom validates the provided configuration and processes the class roster. During execution, the user may be prompted for additional options, including TA repository creation, TA access to student repositories, and cloning student repositories to the local machine.

Use the help option to display the available command-line options:

```bash
WSU_classroom -h
```

## Class Roster Format

WSU Classroom requires a CSV file containing the class roster and majority of it can be obtained from Pilot. The CSV file must use the following column format:

```csv
Name,Email,Role,Username
```

| Column | Description | Get From Pilot? |
| --- | --- | --- |
| `Name` | The first and last name of the roster member. | Yes |
| `Email` | The email address used to generate the repository identifier. | Yes |
| `Role` | The individual's role in the course. | Yes |
| `Username` | The individual's GitHub username. | No |

### Supported Roles

The following roles are supported:

- **Student** – A student repository is created using the specified template repository.
- **TA** – Can optionally receive a repository and read access to student repositories.
- **Teacher / Instructor** – Identifies the course instructor. No repository is created.

## Repository Naming

WSU Classroom automatically generates repository names using the assignment name, the student's email identifier, and the current academic term.

Repository names use the following format:

`<assignment>-<email-id>-<term>`

**For example:**

`project-1-koppin5-f26`

The email identifier is generated using the portion of the student's email address before the @ symbol, with periods removed.

***For example:**

`koppin.5@wright.edu → koppin5`

Academic terms are represented using the following format:

| Term | Format | Example |
| --- | --- | --- |
| Fall | fYY | f26 |
| Spring | sYY | s27 |
| Summer | suYY | su27 |

## How it Works

## Generated Output

## Troubleshooting
