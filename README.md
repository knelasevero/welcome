# Welcome app

This repo shows you one way to build, lint, sign, verify quality, release, verify signature and deploy a simple Go application.

The workflows described here are heavily inspired by the ones at [external-secrets](https://github.com/external-secrets/external-secrets) which were also inspired by [crossplane](https://github.com/crossplane/crossplane).

## The App

The Go application written here is just an example app to be able to build something. At `main.go` we allow all origins
to avoid any trouble while testing and listen at port 8080 at the root path to respond a simple json message (When you are building your real app, only allow the expected caller domains here).

Routes are defined at the package `routes` in `routes.go`, but we only have one route initially. This route calls our controller.

Our controller is inside our controller package in `welcome.go`. Here we just write our simple json response with the response
writer and return 500 if we are not able to.

### Tests

Since this is a very simple example app, I have chosen to just write a simple test method testing the output of the controller.

With more logic inside your controller and with more branching inside your code consider using [table driven tests](https://dave.cheney.net/2019/05/07/prefer-table-driven-tests). They will help you avoid duplication, and let you quickly input test cases into your test suite.

## Building, running and testing the app

To build the app locally you can run:

```
make build
```

And the executable binaries will be placed at ./bin/welcome-{TAGETOS}-{TARGETARCH}.

To run it locally, you can run from the built binaries or just use `make run`:

```
./bin/welcome-linux-amd64
or
make run
```

To run tests you can simply:

```
make test
```

To get more Makefile help, you can run:

```
make help
```

## CI steps



## Release Steps

## Deployment steps

## Running locally

## Missing pieces

## PR checks



