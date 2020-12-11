> ### WORK IN PROGRESS Gleam + Elli + PGO codebase containing real world examples (CRUD, auth, advanced patterns, etc) that WILL adhere to the [RealWorld](https://github.com/gothinkster/realworld) spec and API.

This codebase was created to demonstrate a fully fledged fullstack application built with [Gleam](https://gleam.run) including CRUD operations, authentication, routing, pagination, and more. Some day, hopefully, this will be the case!

For more information on how to this will work with other frontends/backends, head over to the [RealWorld](https://github.com/gothinkster/realworld) repo.


# How it works

> TODO. It doesn't fully work yet!

# Getting started

Compile:
```sh
rebar3 compile
```

Run tests:
```sh
rebar3 eunit
```

For tests, the test database will be automatically re-set
before running the tests.

Set up the database for development:
```
$ rebar3 shell --apps pgo
1> 'conduit@db':reset(<<"conduit_dev"/utf8>>).
```

Run the app with access to the Erlang REPL:
```sh
rebar3 shell
```

The web service will be started at `localhost:4000`

# Database credentials

By default, the application will try to access `postgresql://postgres:postgres@localhost:5432`. You can customize this with:
```
export POSTGRES_HOST=localhost
export POSTGRES_PORT=5432
export POSTGRES_USER=postgres
export POSTGRES_PASSWORD=postgres
```

# TODO:
- [ ] jwt tokens handling using the jose library
- [ ] hashing passwords, configuring salt, document generating salt
- [ ] build release in a separate github actions workflow, run integration tests against it (`test/run-api-tests.sh`)
- [ ] articles crud
- [ ] articles tags
- [ ] following users

... and many more. These are just examples of things missing. Feel free to send PRs for any of them, I'm doing this just to learn Gleam in my spare time so the more the merrier!