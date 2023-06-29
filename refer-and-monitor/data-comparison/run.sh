#!/usr/bin/env bash
set -euo pipefail

start_date=$1
end_date=${2:-$(date +'%Y-%m-%d')}
if [ -z "$start_date" ]; then
  echo "Usage: $0 <yyyy-mm-dd> [yyyy-mm-dd]"
  exit 1
fi

echo "Analysing data from $start_date to $end_date..."

echo -n Exporting Delius data...
oracle_password=$(aws ssm get-parameter --name '/delius-prod/delius/delius-database/db/delius_app_schema_password' --profile delius-prod --with-decryption --query Parameter.Value --output text)
docker run \
   --volume "$(pwd):/scripts" \
   --add-host=host.docker.internal:host-gateway \
   ghcr.io/oracle/oraclelinux8-instantclient:21 \
   sqlplus -s "delius_app_schema/$oracle_password@host.docker.internal:1521/PRDNDA" \
   '@/scripts/delius_reconciliation.sql' '/scripts/csv/delius.csv' "$start_date" "$end_date"
sed -i '1d' './csv/delius.csv'
echo Done

echo -n Exporting Refer and Monitor data...
interventions_creds=$(kubectl get secret/postgres14 -n hmpps-interventions-prod -ojson | jq '.data | map_values(@base64d)')
PGPASSWORD="$(echo "$interventions_creds" | jq -r '.database_password')" \
psql --host=localhost --port=5433 \
  --dbname="$(echo "$interventions_creds" | jq -r '.database_name')" \
  --username="$(echo "$interventions_creds" | jq -r '.database_username')" \
  --set start_date="$start_date" \
  --set end_date="$end_date" \
  --file ram_reconciliation.sql > 'csv/ram.csv'
sed -i '1s/.*/\U&/' csv/ram.csv
echo Done

echo
python3 analysis.py "${@:3}" > office-location.sql
