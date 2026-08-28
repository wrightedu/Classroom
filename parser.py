import csv
import sys

"""
    Parses Pilot quiz output and creates a roster CSV formatted for the WSU Classroom script.
    Inputs:
        input_file - Path to the Pilot quiz output CSV file
        output_file - Path/name of the roster CSV file to create
    Outputs:
        Creates a CSV file containing Name, Email, Role, and Username
        Returns True after the roster file is successfully created
    State Changes:
        Creates or overwrites the specified output CSV file
"""

def parse_data(input_file, output_file):

    students = {}

    # Read the input CSV
    with open(input_file, "r", newline="", encoding="utf-8-sig") as infile:
        reader = csv.DictReader(infile)

        for row in reader:

            first_name = row["FirstName"].strip()
            last_name = row["LastName"].strip()
            question = row["Q Text"].strip()
            answer = row["Answer Match"].strip()

            # Use the student's ID to group their answers together
            student_id = row["Org Defined ID"].strip()

            if student_id not in students:
                students[student_id] = {
                    "name": f"{first_name} {last_name}",
                    "email": "",
                    "github": ""
                }

            # Determine what the answer represents
            if "email" in question.lower():
                students[student_id]["email"] = answer

            elif "github username" in question.lower():
                students[student_id]["github"] = answer

    # Write the extracted information
    with open(output_file, "w", newline="", encoding="utf-8") as outfile:

        writer = csv.writer(outfile)
        writer.writerow(["Name", "Email", "Role", "Username"])

        for student in students.values():

            writer.writerow([
                student["name"],
                student["email"],
                "Student",
                student["github"]
            ])

    print(f"Successfully created '{output_file}'.")
    return True


def main():

    if len(sys.argv) != 2:
        print("Usage: python3 extract.py <csv_file>")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = "roster.csv"

    if not parse_data(input_file, output_file):
        sys.exit(1)


if __name__ == "__main__":
    main()
