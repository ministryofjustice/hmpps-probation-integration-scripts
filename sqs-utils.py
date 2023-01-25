import json
import sys

import boto3

sqs = boto3.client("sqs", region_name="eu-west-2")


def read_sqs_messages(queue_url):
    """
    Reads then deletes all messages from an SQS queue, and prints the
    JSON to stdout line-by-line.

    Example usage for reading messages to a file:
     NAMESPACE=... SECRET_NAME=... source aws-creds-from-k8s.sh && \
     python3 sqs-utils.py read "$SQS_QUEUE_URL" | tee sqs-messages.log

    :param queue_url: The URL of the SQS queue.
    :return:
    """
    response = sqs.receive_message(QueueUrl=queue_url, MaxNumberOfMessages=10)

    count = 0
    while "Messages" in response:
        for message in response["Messages"]:
            print(json.dumps(json.loads(message["Body"])))
            sqs.delete_message(QueueUrl=queue_url,
                               ReceiptHandle=message["ReceiptHandle"])
            count = count + 1

        response = sqs.receive_message(
            QueueUrl=queue_url, MaxNumberOfMessages=10)

    print(f"Total messages: {count}", file=sys.stderr)


def send_sqs_messages(queue_url):
    """
    Send messages to the specified SQS queue. Reads each line from stdin,
    parses it as a single JSON message, and sends it to the queue.

    Example usage for sending messages from a file:

     NAMESPACE=... SECRET_NAME=... source aws-creds-from-k8s.sh && \
     cat sqs-messages.log | python3 sqs-utils.py send "$SQS_QUEUE_URL" | tee send-output.log

    :param queue_url: The URL of the SQS queue.
    :return:
    """
    success = 0
    failure = 0
    for line in sys.stdin:
        message = json.loads(line)
        message_attributes = dict((k, {"StringValue": v["Value"], "DataType": "String"})
                                  for k, v in message["MessageAttributes"].items())
        response = sqs.send_message(MessageBody=json.dumps(message),
                                    MessageAttributes=message_attributes,
                                    QueueUrl=queue_url)
        print(response)
        if response["ResponseMetadata"]["HTTPStatusCode"] == 200:
            success += 1
        else:
            failure += 1

    print(f"Successfully sent {success} messages. Failures={failure}")


if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("Usage: {} <read|send> <sqs_queue_url>".format(
            sys.argv[0]), file=sys.stderr)
        sys.exit(1)

    if sys.argv[1] == "read":
        read_sqs_messages(sys.argv[2])
    elif sys.argv[1] == "send":
        send_sqs_messages(sys.argv[2])
