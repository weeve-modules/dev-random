#!/bin/sh
echo "Entrypoint script"
echo $# Args: $@
echo "Environment:"
env

if test [ -f /mounted ] ; then
    echo "Mounted"
else
    exit Error: Expected a mounted file at /mounted
fi

# echo head -n 4096 /dev/urandom | sha256sum
# mystring=$(head -n 4096 /dev/urandom | sha256sum) | cut -f 1 -d " "

# Get 4096 bytes of random data. Take the 256 hash. Do not keep the dash after the string. Assign to variable.
randomstring=$(head -n 4096 /mounted | sha256sum | cut -f 1 -d " ")
# echo $mystring
echo "Generated random hash $randomstring from host"

# Build a JSON string. The JSON data may have spaces, newlines, etc.
JSON_STRING=$( jq -n -r --arg hs "$randomstring" '{"random hash": $hs}' )
echo $JSON_STRING

# Can't simply use -d $JSON_STRING, as this has newlines, spaces.
# Instead, pipe it into the command.
echo "POST to http://$ENDPOINT:$PORT"
echo $JSON_STRING | curl -d @- -H "Content-Type: application/json" -X POST http://$ENDPOINT:$PORT