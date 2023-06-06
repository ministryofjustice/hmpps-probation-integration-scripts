# Interventions Data Comparison

Scripts to identify and analyse differences between Interventions referrals and appointments vs Delius contacts.

## Prerequisites

* Access to Delius DB (via AWS IAM), and R&M DB (via GitHub Team)
* AWS CLI
* Docker
* Git
* Jq
* Kubectl
* Python

## Instructions

### Setup
Forward the Delius DB port to your local machine:
```shell
ssh delius-db-1.probation.service.justice.gov.uk -L1521:localhost:1521
```

Forward the R&M DB port to your local machine:
```shell
git clone https://github.com/ministryofjustice/hmpps-interventions-ops
hmpps-interventions-ops/setup_port_forward.sh hmpps-interventions-prod
```

### Run
Use the [run.sh](./run.sh) script to export data and summarise the differences for a given date range:
```shell
./run.sh '2023-06-01' '2023-06-03'
```

Run with debug logging to output the individual differences for further analysis:
```shell
./run.sh '2023-06-01' '2023-06-03' --log=debug
```

Sample output:
```
Analysing data from 2023-06-03 to 2023-06-06...
Exporting Delius data...Done
Exporting Refer and Monitor data...Done

Stats:
 {'DIFFERENT': 787, 'MATCHING': 3592, 'MISSING': 171}

Differences by field:
 {'APPOINTMENT_ID': 87,
 'ATTENDED': 471,
 'COMPLIED': 530,
 'CONTACT_END_TIME': 14,
 'CONTACT_LAST_UPDATED_BY_RAM': 170,
 'REFERENCE_NUMBER': 3,
 'REFERRAL_LAST_UPDATED_BY_RAM': 108,
 'STATUS': 24}

Missing by type:
 {'Action Plan Approved': 14,
 'Action Plan Submitted': 25,
 'End of Service': 54,
 'Service Delivery Appointment': 53,
 'Supplier Assessment Appointment': 25}

Missing by reason:
 {'COMPLETION_IN_R&M': 63, 'UNCLASSIFIED': 15}
```

CSV reports are created in the `csv` directory. Examples: [example/csv](./example/csv).
