# README #

### Current WG-Draft

The current WG-Draft version is built automatically from the main branch and can be accessed at:

* 1.0: https://openid.github.io/OpenID4VP/openid-4-verifiable-presentations-1_0-wg-draft.html
* 1.1: https://openid.github.io/OpenID4VP/openid-4-verifiable-presentations-1_1-wg-draft.html

### Building the HTML

The easiest way to build the HTML is to use the [`danielfett/markdown2rfc`](https://hub.docker.com/r/danielfett/markdown2rfc) docker image. For example, to build the `1.1` version of the spec, do the following:

**bash / zsh / sh**

```
cd 1.1
docker run -v `pwd`:/data danielfett/markdown2rfc openid-4-verifiable-presentations-1_1.md
```

**fish**

```
cd 1.1
docker run -v (pwd):/data danielfett/markdown2rfc openid-4-verifiable-presentations-1_1.md
```

### Conformance tests

Conformance tests are available for testing whether both Wallets and
Verifiers are compliant with this specification, see:

https://openid.net/certification/conformance-testing-for-openid-for-verifiable-presentations/

### Contribution guidelines ###

* There are two ways to contribute, creating issues and pull requests
* All proposals are discussed in the WG on the list and in our regular calls before being accepted and merged.

### Who do I talk to? ###

* The WG can be reached via the mailing list [openid-specs-digital-credentials-protocols@lists.openid.net](mailto:openid-specs-digital-credentials-protocols@lists.openid.net) (join the ML [here](https://lists.openid.net/mailman/listinfo/openid-specs-digital-credentials-protocols)).

