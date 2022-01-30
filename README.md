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

The deployment step is only triggered if an github actions event named deploy is sent from the release workflow.

Since I wanted to check the steps in my GKE clusters, I have included steps to configure and get access to gcloud and an specific cluster config. Those steps can be ignored if you are able to run these steps against a simpler cluster, one that you can just point to using a kubeconfig.

You can also change line 11 of that workflow to `GCLOUD: ""` or delete it to skip those steps.

First thing that is done here is to check if the signature matches what we expect from previous steps. If the signing/verifying was not done with the correct key pair we would get errors here.

The deploy step will then build the helm chart and call `make deploy` making the env var TAG be the current tag that triggered the whole process.

`make deploy` calls 2 scripts. The first one is `./deploy/scripts/write_kubeconfig.sh` which will get the contents of the env var $KUBECONFIGCONTENTS and write to the default Kubeconfig path `~/.kube/config` (it will only do that if the current kube context does not have the same server url as the one that you are trying to setup).

The second script is `./deploy/scripts/deploy.sh "${TAG}"`, which will try to install helm and kubectl (if you don't have them already in your PATH), and then just call helm install for the built chart using the image with the right tag.

## Running locally

Some of the CI steps or general Makefile targets that also make sense to run locally:

```
# linting
make lint

# formating
make fmt

# build and push
BUILD_ARGS="--push --platform linux/amd64,linux/arm64" make docker.build

# generate cosign keypair
cosign generate-key-pair

# sign the image
cosign sign --key cosign.key \
            -a "repo=${REPO}" \
            -a "ref=${SHA}" \
            knelasevero/wecolme:${TAG}

# verify signature
cosign verify --key cosign.pub knelasevero/wecolme:${TAG}

```

### How to deploy from your local machine to a specific Kubeconfig

First set your $KUBECONFIGCONTENT env var:

```
export KUBECONFIGCONTENT=`cat /path/to/.kube/config`
```

Choose a tag to deploy and run `make deploy` with it set:

```
TAG=0.0.4-alpha-6 make deploy
```

If you want to deploy to a specific namespace you can also use the script directly:

```
./deploy/scripts/deploy.sh "${TAG}" "${NS}"
```

## Checking the running workload

After installing the helm chart to your cluster you can check it by port forwarding or deploying an Ingress (if you have an Ingress Controller set up).

```
# open/split 2 terminals

# in first terminal
kubectl port-forward svc/welcome 8080:8080 -n ${NS}

# in second terminal
curl localhost:8080

# or just open localhost:8080 in a browser
```

## Missing pieces

The helm package was supposed to be available at a subdomain of my domain: charts.welcome.knela.dev but something did not work as intended. Since I did not have time to look deeper we are just building the chart from the repo every time.

As mentioned in the section that talks about tests, the unit test setup could be improved and a simple e2e test setup could have also been added.

An optional ingress resource and other ServiceAccount or RBAC configs could have also be added to the helm templating letting the user choose what he wants passing flags while installing with helm.

## PR checks

To keep it simple sonar cloud was added to the repo with the Open Source integration that is free. It checks for code duplication, code smells, vulnerabilities and known bugs. It also gives the code a score. Sonar Cloud checks every commit when they are sent to an open PR (with the out of the box integration). 

![image](https://user-images.githubusercontent.com/2432275/151699966-a53f1968-96b8-43cd-91cd-98056324c2e2.png)


