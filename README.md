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

Our github actions workflows consist of 3 parts: CI, Release and Deploy. Let's first talk about the CI steps.

![image](https://user-images.githubusercontent.com/2432275/151698000-4304327b-bf83-4333-af82-5a0ae4b08b2b.png)

First step in the CI workflow is the detect-noop step. It basically detects if it makes sense to run the rest of the steps. If we are only changing documentation or some other details, we don't want to run tests or push images. This is important to be gentle on github action's provided free time, but also to save credits if you are on the paid plan.

The other steps run in parallel since they don't have any dependencies.

The `lint` step will check for general linting issues, like style guide patterns, errors not handled etc. It will also send annotations directly into the PR diff if the change is coming from a PR.

The `unit-tests` step will just run the unit tests with `make test` target of the Makefile and fail the run if tests fail.

The `publish-artifacts` step will login to dockerhub, build docker images, push them and sign them using cosign from sigstore.

All those steps use caching mechanisms of github actions to avoid having long running jobs so we can get artifacts published quickly.

## Release Steps

![image](https://user-images.githubusercontent.com/2432275/151698388-29b9ce30-620a-41f6-a75c-ea67ecadd971.png)

The realse steps are a bit more sequential. It is only triggered if a git tag is pushed to the repo. The first step is the `Create Release` step. It basically consists of building the changelog of the release based on the git history and creating a github release with the tag name.

The second and third steps run in parallel. The `Promote Container Image` step will basically the latest image pushed from main branch and tag it in dockerhub with the same tag as we had in the git release. While this happens we also try to check if our chart is linted correctly and check for templating issues on it.

The last step is the `release-helm` step. Right now we are not pushing chart version bumps to the repo. `Chart.yaml` just holds a placeholder value for versions and we bump it while releasing using simple `sed` commands. After bumping the versions we use the github action provided by [chart-releaser-action](https://github.com/helm/chart-releaser-action) to create a github release named `helm-chart-{TAG}` that will also hold the bundled chart artifact in it. At the end of this step an github actions event is dispatched to trigger the Deploy workflow.

## Deployment steps
![image](https://user-images.githubusercontent.com/2432275/151699025-5c4904ba-fb68-48b4-9b42-2e014abce186.png)


## Running locally

## Missing pieces

## PR checks



