import logging
import re
from argparse import ArgumentParser
from pprint import pformat
from dictdiffer import diff
import csv

# input
DELIUS_FILE = "./csv/delius.csv"
RAM_FILE = "./csv/ram.csv"

# output
MISSING_BY_TYPE_FILE = "./csv/missing_contacts_by_type.csv"
DIFFERENCES_BY_FIELD_FILE = "./csv/differences_by_field.csv"


def parse_csv(file):
    """Create a dict of CSV headings to values"""
    with open(file) as csv_file:
        # Parse CSV file
        parsed = csv.reader(csv_file)

        # Create a dict of CSV heading to values
        headings = next(parsed)
        rows = (dict(zip(headings, line)) for line in parsed)

        # Create a dict with a unique key for each specific contact
        keyed = {}
        for row in rows:
            k = f'{row["REFERRAL_ID"]} {row["CONTACT_START_TIME"]} {row["CONTACT_NOTES"]}'
            keyed[k] = row

        return keyed


def write_csv(data, filename):
    """Write a dict of keyed rows to a CSV file"""
    rows = [row for row in data.values()]
    column_names = set().union(*(row.keys() for row in data.values()))
    with open(filename, "w") as file:
        writer = csv.DictWriter(file, fieldnames=["Date"] + sorted(list(column_names - {"Date"})))
        writer.writeheader()
        writer.writerows(rows)


def classify_missing_appointments(ram_row):
    """Identify why an appointment has been deleted from Delius"""
    identifier = ""
    if (ram_row["STATUS"]) == "Completed":
        identifier = "COMPLETION_IN_R&M"
    else:
        identifier = "UNCLASSIFIED"

    return identifier


def check_missing():
    # These are not in Delius at all
    stats["MISSING"] = stats.get("MISSING", 0) + 1

    # What kind of activity is it?
    contact_type_key = ram_row.get(
        "CONTACT_NOTES", "DATA_EXPORT_SYNCHRONISATION")

    # Appointment contacts may be missing as future appointments
    # with no outcome are deleted when a referral is completed
    if re.match(".*Appointment", contact_type_key) or contact_type_key == "End of Service":
        # Classify missing appointments
        problem_id = classify_missing_appointments(ram_row)

        # Count missing appointment issues
        missing_by_reason[problem_id] = missing_by_reason.get(
            problem_id, 0) + 1

    # Count missing contacts by type
    missing_by_type[contact_type_key] = missing_by_type.get(
        contact_type_key, 0) + 1

    # Count missing contacts by date and type
    date = ram_row["CONTACT_START_TIME"][:10]
    missing_by_date_and_type.setdefault(date, {
        'Date': date,
        'Action Plan Approved': 0,
        'Action Plan Submitted': 0,
        'End of Service': 0,
        'Service Delivery Appointment': 0,
        'Supplier Assessment Appointment': 0
    })
    missing_by_date_and_type[date][contact_type_key] = missing_by_date_and_type[date].get(
        contact_type_key, 0) + 1


def check_differences():
    diffs = list(diff(ram_row, delius_row, ignore=["NAME", "OUTCOME", "STATUS_AT"]))
    if len(diffs) == 1 and (diffs[0][1] == "CONTACT_MANUALLY_UPDATED_IN_DELIUS" or diffs[0][1] == "REFERRAL_MANUALLY_UPDATED_IN_DELIUS"):
        # Ignore updates in Delius that don't affect fields we're interested
        diffs = []

    if diffs:
        # These are different between R&M and Delius - log so we can eyeball
        logging.debug("%s | %s | %s", key,
                      ram[key]["SERVICE_USERCRN"], ram[key]["NAME"])
        logging.debug("%s\n", diffs)

        # Count the differences
        stats["DIFFERENT"] = stats.get("DIFFERENT", 0) + 1

        # Count the differences by field
        for item in diffs:
            differences_by_field[item[1]] = differences_by_field.get(
                item[1], 0) + 1

            date = ram_row["CONTACT_START_TIME"][:10]
            differences_by_date_and_field.setdefault(date, {'Date': date})
            differences_by_date_and_field[date][item[1]] = differences_by_date_and_field[date].get(
                item[1], 0) + 1

    else:
        # These are all gravy - whoo!
        stats["MATCHING"] = stats.get("MATCHING", 0) + 1


if __name__ == "__main__":
    parser = ArgumentParser()
    parser.add_argument("--log")
    args = parser.parse_args()
    args.log = args.log or "INFO"

    logging.basicConfig(level=getattr(logging, args.log.upper()))

    delius = parse_csv(DELIUS_FILE)
    ram = parse_csv(RAM_FILE)

    missing_by_type = {
        'Action Plan Approved': 0,
        'Action Plan Submitted': 0,
        'End of Service': 0,
        'Service Delivery Appointment': 0,
        'Supplier Assessment Appointment': 0
    }
    missing_by_date_and_type = {}
    missing_by_reason = {}
    stats = {}
    differences_by_field = {}
    differences_by_date_and_field = {}

    for key, _ in ram.items():
        ram_row = ram[key]

        if key in delius:
            # Save out the CSV row for diffing
            delius_row = delius[key]
        else:
            # Categorise contacts that are missing from Delius
            check_missing()

            # Set the Delius row to be the R&M row - i.e. ignore the diff
            delius_row = ram[key]

        # Diff the two CSV rows
        check_differences()

    # Remove missing from the matching total
    stats["MATCHING"] = stats.get("MATCHING", 0) - stats.get("MISSING", 0)

    # Print out some bits and bobs
    logging.info("\nStats:\n %s\n", pformat(stats))
    logging.info("\nDifferences by field:\n %s\n",
                 pformat(differences_by_field))
    logging.debug("\nDifferences by date and field:\n %s\n",
                  pformat(differences_by_date_and_field))
    logging.info("\nMissing by type:\n %s\n", pformat(missing_by_type))
    logging.debug("\nMissing by date and type:\n %s\n",
                  pformat(missing_by_date_and_type))
    logging.info("\nMissing by reason:\n %s\n", pformat(missing_by_reason))

    # Write out the reports
    write_csv(missing_by_date_and_type, MISSING_BY_TYPE_FILE)
    write_csv(differences_by_date_and_field, DIFFERENCES_BY_FIELD_FILE)
