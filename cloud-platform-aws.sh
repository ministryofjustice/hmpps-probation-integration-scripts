#!/usr/bin/env bash
##
## Execute AWS CLI commands in a temporary debug pod, using the shared service account
##
## Add to your ~/.bashrc:
##   echo 'function cloud-platform-aws() { /path/to/cloud-platform-aws.sh "$@"; }' >> ~/.bashrc
##
## Usage:
##   cloud-platform-aws <dev|preprod|prod> <command>
##
## Examples:
##   * List all probation-integration SQS queues:
##     cloud-platform-aws prod sqs list-queues --queue-name-prefix probation-integration
##
##   * Get a queue URL
##     cloud-platform-aws prod sqs get-queue-url --queue-name probation-integration-prod-approved-premises-and-delius-dlq
##
##   * Get a queue ARN
##     cloud-platform-aws prod sqs get-queue-attributes --attribute-names QueueArn --queue-url https://sqs.eu-west-2.amazonaws.com/754256621582/probation-integration-prod-approved-premises-and-delius-dlq
##
##   * Get the number of messages on a queue
##     cloud-platform-aws prod sqs get-queue-attributes --attribute-names ApproximateNumberOfMessages --queue-url https://sqs.eu-west-2.amazonaws.com/754256621582/probation-integration-prod-approved-premises-and-delius-dlq
##
##   * Purge a queue
##     cloud-platform-aws prod sqs purge-queue --queue-url https://sqs.eu-west-2.amazonaws.com/754256621582/probation-integration-prod-approved-premises-and-delius-dlq
##
##   * Re-drive a DLQ
##     cloud-platform-aws prod sqs start-message-move-task --source-arn arn:aws:sqs:eu-west-2:754256621582:probation-integration-prod-approved-premises-and-delius-dlq
##
## Known issues:
##   * Sometimes, the debug pod isn't cleaned up when the script exits which can cause an AlreadyExists error on the next run.
##     To fix this, delete the pod manually: `kubectl -n <namespace> delete pod "${USER}-debug"`
##

env=$1
shift 1
kubectl run \
--namespace="hmpps-probation-integration-services-$env" \
--image=ghcr.io/ministryofjustice/hmpps-devops-tools:latest \
--restart=Never --stdin=true --tty=true --rm \
--overrides='{"spec":{"serviceAccount":"hmpps-probation-integration-services"}}' \
"${USER}-debug" -- "$@"