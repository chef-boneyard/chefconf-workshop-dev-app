# chefconf-workshop-dev-app

This is a simple REST server for use in Opscode's Developer Training classes.

## Install

    bundle install --binstubs
    # kick bundle exec to the curb
    export PATH=.:$PATH
    cp config/database.rb.example config/database.rb

## Run Tests:

    padrino rake sq:migrate:up -e test
    padrino rake spec

## Run the App

    padrino start

## Example CURL Interactions

    ./curl_test_commands.sh http://localhost:3000

Be sure to use an appropriate server address (if testing locally, the port
Padrino uses may be different; if testing the app on a VM, use the
appropriate host).
