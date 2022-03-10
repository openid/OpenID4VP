# README #

### Running Tests ###
This repository contains examples from the specifications and the JSON
schema definitions extracted as separate files in the directories
`examples` and `schema`, respectively. The directory `tests` contains
tests (written in python) that check if the examples comply to the
schema files.

To run the tests, follow these instructions:

* Build the test command using docker: 

```
docker build -t openid.net/tests-oidc4vp tests
```

* Run the tests: 

```
docker run -v `pwd`:/data openid.net/tests-oidc4vp
```

### Building the HTML

```
docker run -v `pwd`:/data danielfett/markdown2rfc openid-connect-4-verifiable-presentations-1_0.md
```

### Contribution guidelines ###

* There are two ways to contribute, creating issues and pull requests
* All proposals are discussed in the WG on the list and in our regular calls before being accepted and merged.

### Who do I talk to? ###

* The WG can be reached via the mailing list openid-specs-ekyc-ida@lists.openid.net

