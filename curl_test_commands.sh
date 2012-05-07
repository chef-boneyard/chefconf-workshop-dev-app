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
echo "################################################################################"
echo

echo "Nothing there to start with"
curl ${SERVER}/users/thedoctor
echo
echo

echo "Create a user; returns the user"
curl -X POST -d '{"first_name": "Tom", "last_name": "Baker", "userid": "thedoctor", "groups": []}' ${SERVER}/users/
echo
echo

echo "Retrieve that user"
curl ${SERVER}/users/thedoctor
echo
echo

echo "Update the user; returns updated user"
curl -X PUT -d '{"first_name": "David", "last_name": "Tennant", "userid": "thedoctor", "groups": []}' ${SERVER}/users/thedoctor
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

echo "Beginning test of the '/groups' endpoint on '${SERVER}'"
echo "################################################################################"
echo

echo "Show the group is not there"
curl ${SERVER}/groups/doctors
echo
echo

echo "Create the group with no members; returns group"
curl -X POST -d '{"name": "doctors", "users": []}' ${SERVER}/groups
echo
echo

echo "Retrieve group with no members"
curl ${SERVER}/groups/doctors
echo
echo

echo "Create a user in the new group; returns the user"
curl -X POST -d '{"first_name": "Tom", "last_name": "Baker", "userid": "doctor4", "groups": ["doctors"]}' ${SERVER}/users/
echo
echo

echo "Retrieve user; group membership is now reflected"
curl ${SERVER}/users/doctor4
echo
echo

echo "Retrieve group; user membership is now reflected"
curl ${SERVER}/groups/doctors
echo
echo

echo "Add another user to the group"
curl -X POST -d '{"first_name": "David", "last_name": "Tennant", "userid": "doctor10", "groups": ["doctors"]}' ${SERVER}/users/
echo
echo

echo "Retrieve group again; new users show up in membership list"
curl ${SERVER}/groups/doctors
echo
echo

echo "Deleting a user removes it from any groups"
curl -X DELETE ${SERVER}/users/doctor4
echo
echo

echo "Retrieve the group again; deleted user is gone"
curl ${SERVER}/groups/doctors
echo
echo

echo "Delete the group; remaining users will no longer be shown as memmbers"
curl -X DELETE ${SERVER}/groups/doctors
echo
echo

echo "Remaining user is not a member of the group"
curl ${SERVER}/users/doctor10
echo
echo

echo "Delete last remaining user"
curl -X DELETE ${SERVER}/users/doctor10
echo
echo
