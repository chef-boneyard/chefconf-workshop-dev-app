# chefconf-workshop-dev-app

This is a simple REST server for use in Opscode's Developer Training classes.

## Install

    bundle install --binstubs
    # kick bundle exec to the curb
    export PATH=.:$PATH

## Run Tests:

    padrino rake sq:migrate:up -e test
    padrino rake spec

## Run the App

    padrino start
