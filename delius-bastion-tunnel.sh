#!/usr/bin/env bash

PASS_ENTRY=
PROXY_HOST=

# Create a pipe
PIPE=$(mktemp -u)
mkfifo -m 600 "$PIPE"

# Attach it to file descriptior 3
exec 3<>"$PIPE"

# Delete the directory entry
rm "$PIPE"

# Write your password in the pipe
pass show "$PASS_ENTRY" | head -1 >&3

# Connect with sshpass -d
sshpass -d3 ssh -L 1521:localhost:1521 "$PROXY_HOST"

# Close the pipe when done
exec 3>&-
