#!/bin/sh

# Sample cURL commands to demonstrate the sample application for the
# 2012 ChefConf Developer Workshop

if [ $# -lt 1 ]
then
  echo "Usage: $0 server_and_port"
  echo "(e.g., '$0 http://localhost:3000')"
  exit
fi

SERVER=$1

echo "Beginning test of the '/users' endpoint on '${SERVER}'"
echo

echo "Nothing there to start with"
curl ${SERVER}/users/thedoctor
echo
echo

echo "Create a user; returns the user"
curl -X POST -d '{"first_name": "Tom", "last_name": "Baker", "userid": "thedoctor"}' ${SERVER}/users/
echo
echo

echo "Retrieve that user"
curl ${SERVER}/users/thedoctor
echo
echo

echo "Update the user; returns updated user"
curl -X PUT -d '{"first_name": "David", "last_name": "Tennant", "userid": "thedoctor"}' ${SERVER}/users/thedoctor
echo
echo

echo "Retrieve that user; note the changes"
curl ${SERVER}/users/thedoctor
echo
echo

echo "Delete the user; returns deleted user"
curl -X DELETE ${SERVER}/users/thedoctor
echo
echo

echo "See that it's gone"
curl ${SERVER}/users/thedoctor
echo
echo
