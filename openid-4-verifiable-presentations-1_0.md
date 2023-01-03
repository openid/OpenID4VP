%%%
title = "OpenID for Verifiable Presentations"
abbrev = "openid-4-vp"
ipr = "none"
workgroup = "connect"
keyword = ["security", "openid", "ssi"]

[seriesInfo]
name = "Internet-Draft"
value = "openid-4-verifiable-presentations-1_0-14"
status = "standard"

[[author]]
initials="O."
surname="Terbu"
fullname="Oliver Terbu"
organization="Spruce Systems, Inc."
    [author.address]
    email = "oliver.terbu@spruceid.com"

[[author]]
initials="T."
surname="Lodderstedt"
fullname="Torsten Lodderstedt"
organization="yes.com"
    [author.address]
    email = "torsten@lodderstedt.net"

[[author]]
initials="K."
surname="Yasuda"
fullname="Kristina Yasuda"
organization="Microsoft"
    [author.address]
    email = "kristina.yasuda@microsoft.com"

[[author]]
initials="A."
surname="Lemmon"
fullname="Adam Lemmon"
organization="Convergence.tech"
    [author.address]
    email = "adam@convergence.tech"
    
[[author]]
initials="T."
surname="Looker"
fullname="Tobias Looker"
organization="Mattr"
    [author.address]
    email = "tobias.looker@mattr.global"

%%%

.# Abstract

This specification defines a protocol for requesting and presenting Verifiable Credentials. 

{mainmatter}

# Introduction

This specification defines a mechanism on top of OAuth 2.0 [@!RFC6749] that enables presentation of Verifiable Credentials. W3C [@VC_DATA] formats as well as other Credential formats, like [@ISO.18013-5] and AnonCreds [@Hyperledger.Indy], are supported. 

OAuth 2.0 [@!RFC6749] is used as a base protocol as it provides the required rails to build simple, secure, and developer friendly credential presentation on top of it. Moreover, implementers can, in a single interface, support credential presentation and the issuance of access tokens for access to APIs based on Verifiable Credentials in the Wallet. OpenID Connect [@!OpenID.Core] deployments can also extend their implementations using this specification with the ability to transport Verifiable Presentations. 

This specification can also be combined with [@!SIOPv2], if implementers require OpenID Connect features, such as the issuance of subject-signed ID tokens.

# Terminology

Credential

  A set of claims about a subject made by an Issuer.

Note: the definition of a term "credential" in this specification is different from that in [@!OpenID.Core].

Verifiable Credential (VC)

  A tamper-evident credential that has authorship of the Issuer that can be cryptographically verified. Can be of any format used in the Issuer-Holder-Verifier Model, including, but not limited to those defined in [@VC_DATA], [@ISO.18013-5] and [@Hyperledger.Indy] (AnonCreds).

W3C Verifiable Credential

  A Verifiable Credential compliant to the [@VC_DATA] specification.

Presentation

  Data derived from one or more Verifiable Credentials that can be from the same or different issuers that is shared with a specific verifier.

Verifiable Presentation (VP)

  A tamper-evident presentation that has authorship of the Holder that can be cryptographically verified to provide Cryptographic Holder Binding. Can be of any format used in the Issuer-Holder-Verifier Model, including, but not limited to those defined in [@VC_DATA], [@ISO.18013-5] and [@Hyperledger.Indy] (AnonCreds).

W3C Verifiable Presentation

  A Verifiable Presentations compliant to the [@VC_DATA] specification.

Issuer

  An entity that creates Verifiable Credentials.

Holder

  An entity that receives Verifiable Credentials and has control over them to present them to the Verifiers as Verifiable Presentations.

Verifier

  An entity that requests, checks and extracts the claims from Verifiable Presentations.

Issuer-Holder-Verifier Model

  A model for claims sharing where claims are issued in the form of Verifiable Credentials independent of the process of presenting them as Verifiable Presentation to the Verifiers. Issued Verifiable Credential can (but must not necessarily) be used multiple times.

Cryptographic Holder Binding

  Ability of the Holder to prove legitimate possession of a Verifiable Credential by proving control over the same private key during the issuance and presentation. Mechanism might depend on the Crednetial Format. For example, in `jwt_vc_json` Credential Format, a VC with Cryptographic Holder Binding contains a public key or a reference to a public key that matches to the private key controlled by the Holder. Claim-based or biometrics-based holder binding is also possible.

Base64url Encoding

  Base64 encoding using the URL- and filename-safe character set defined in Section 5 of [@!RFC4648], with all trailing '=' characters omitted (as permitted by Section 3.2 of [@!RFC4648]) and without the inclusion of any line breaks, whitespace, or other additional characters. Note that the base64url encoding of the empty octet sequence is the empty string. (See Appendix C of [@!RFC7515] for notes on implementing base64url encoding without padding.)

Wallet

  Entity used by the Holder to receive, store, present, and manage Verifiable Credentials and key material. There is no single deployment model of a Wallet: Verifiable Credentials and keys can both be stored/managed locally, or by using a remote self-hosted service, or a remote third party service. In the context of this specification, the Wallet acts as an OAuth 2.0 Authorization Server (see [@!RFC6749]) towards the Credential Verifier which acts as the OAuth 2.0 Client. 


# Scope

This specification defines mechanisms to

* request presentation of Verifiable Credentials in arbitrary formats.
* provide a verifier with one or more Verifiable Presentations in a secure fashion. 
* customize the protocol to the specific needs of a particular credential format. Examples are given for credential formats as specified in [@VC_DATA], [@ISO.18013-5] and [@Hyperledger.Indy].
* combine the credential presentation with user authentication through [@SIOPv2]. 
* combine the credential presentation with the issuance of OAuth access tokens. 

# Overview 

This specification defines a mechanism on top of OAuth 2.0 to request and provide Verifiable Presentations. Verifiable Presentations are requested by adding a parameter `presentation_definition` as defined by [@!DIF.PresentationExchange] to an OAuth 2.0 Authorization Request. The Verifiable Presentations are returned to the Verifier in a `vp_token` response parameter, depending on the grant type either in the authorization or the token response. 

OpenID for Verifiable Presentations supports scenarios where the Authorization Request is sent from the Verifier to the Wallet using redirects on the same device (same-device flow) and where the Authorization Request is passed across devices (cross-device flow).

Implementations can use any pre-existing OAuth grant type and response type in conjunction with this specifications to support different deployment architectures. This specification also introduces a new OAuth response mode `direct_post` to support the cross device flow (see (#response_mode_post)). 

This specification supports any Credential format used in the Issuer-Holder-Verifier Model, including, but not limited to those defined in [@VC_DATA], [@ISO.18013-5] and [@Hyperledger.Indy] (AnonCreds) even in the same transaction. The examples given in the main part of this specification use W3C Verifiable Credentials, but examples in other Credential formats are given in  (#alternative_credential_formats). 

Implementations can also be build on top of OpenID Connect Core, since OpenID Connect Core is based on OAuth 2.0. To benefit from the subject-signed ID Token feature, this specification can also be combined with the Self-Issued OP v2 specification [@SIOPv2].

# Authorization Request {#vp_token_request}

The authorization request follows the definition given in [@!RFC6749]. 

The following new parameters are defined by this specification:  

* `presentation_definition`: CONDITIONAL. A string containing a `presentation_definition` JSON object as defined in Section 4 of [@!DIF.PresentationExchange]. See (#request_presentation_definition) for more details. 
* `presentation_definition_uri`: CONDITIONAL. A string containing an HTTPS URL pointing to a resource where a `presentation_definition` JSON object as defined in Section 4 of [@!DIF.PresentationExchange] can be retrieved . See (#request_presentation_definition_uri) for more details.
* `nonce`: REQUIRED. This parameter follows the definition given in [@!OpenID.Core]. It is used to securely bind the Verifiable Presentation(s) provided by the AS to the particular transaction.
* `response_mode` OPTIONAL. as defined in [@!OAuth.Responses]. If the parameter is not present, the default value is `fragment`. This parameter is also used to request signing & encryption (see (#jarm)) as well as to ask the Wallet to send the response to the Verifier via an HTTPS connection (see (#response_mode_post)). 

Additional considerations need to be considered for the following parameters defined in [@!RFC6749]:

* `response_type`: REQUIRED. This specification can be used with all response types as defined in the registry established by [@!RFC6749]. This specification introduces the new response type `vp_token`. This response type asks the Authorization Server (AS) to return a `vp_token` authorization response parameter. 
* `scope`: OPTIONAL. The Wallet MAY allow verifiers to request presentation of  Verifiable Credentials by utilizing a pre-defined scope value. See (#request_scope) for more details.

Note: A request MUST contain either a `presentation_definition` or a `presentation_definition_uri` or a single `scope` value representing a presentation definition, those three ways to request credential presentation are mutually exclusive. The Wallet MUST refuse any request violating this requirement. 

A public key to be used by the Wallet as an input to the key agreement to encrypt Authorization Response (see (#jarm)) MAY be passed by the Verifier using `jwks` or `jwks_uri` claim within the `client_metadata` request parameter (see (#client_metadata_parameters)). 

This is an example request: 

```
  GET /authorize?
    response_type=vp_token
    &client_id=https%3A%2F%2Fclient.example.org%2Fcb
    &redirect_uri=https%3A%2F%2Fclient.example.org%2Fcb
    &presentation_definition=...
    &nonce=n-0S6_WzA2Mj HTTP/1.1
```

## `presentation_definition` Parameter{#request_presentation_definition}

This parameter contains a JSON object conforming to the syntax defined for `presentation_definition` parameters in Section 4 of [@!DIF.PresentationExchange].

The following shows an example `presentation_definition` parameter:

<{{examples/request/vp_token_type_only.json}}

This simple example requests the presentation of a credential of a certain type.

The following example shows how the RP can request selective disclosure or certain claims from a credential of a particular type.

<{{examples/request/vp_token_type_and_claims.json}}

RPs can also ask for alternative Verifiable Credentials being presented, which is shown in the next example:

<{{examples/request/vp_token_alternative_credentials.json}}

The VC and VP formats supported by an AS should be published in its metadata (see (#as_metadata_parameters)). The formats supported by a client may be set up using the client metadata parameter `vp_formats` (see (#client_metadata_parameters)). The AS MUST ignore any `format` property inside a `presentation_definition` object if that `format` was not included in the `vp_formats` property of the client metadata. 

Note that when the Client is requesting presentation of a VP containing a VC, Client MUST indicate in the `vp_formats` parameter, supported formats of both VC and VP.

## `presentation_definition_uri` Parameter {#request_presentation_definition_uri}

`presentation_definition_uri` is used to the retrieve the `presentation_definition` from the resource at the specified URL, rather than being passed by value. The AS will send a GET request without additional parameters. The resource MUST be exposed without further need to authenticate or authorize. 

The protocol for the `presentation_definition_uri` MUST be HTTPS.

For example the parameter value "https://server.example.com/presentationdefs?ref=idcard_presentation_request" will result in the following request 

```
  GET /presentationdefs?ref=idcard_presentation_request HTTP/1.1
  Host: server.example.com
```

and response.

```
HTTP/1.1 200 OK
...
Content-Type: application/json

{
    "id": "vp token example",
    "input_descriptors": [
        {
            "id": "id card credential",
            "format": {
                "ldp_vc": {
                    "proof_type": [
                        "Ed25519Signature2018"
                    ]
                }
            },
            "constraints": {
                "fields": [
                    {
                        "path": [
                            "$.type"
                        ],
                        "filter": {
                            "type": "string",
                            "pattern": "IDCardCredential"
                        }
                    }
                ]
            }
        }
    ]
}
```
## Using `scope` Parameter to Request Verifiable Credential(s) {#request_scope}

Wallets MAY support requesting presentation of Verifiable Credentials using OAuth 2.0 scope values. 

Such a scope value MUST be an alias for a well-defined presentation definition as it will be 
refered to in the `presentation_submission` response parameter. 

The concrete scope values and the mapping between a certain scope value and the respective 
presentation definition is out of scope of this specification. 

Possible options include normative text in a specification defining scope values along with a description of their
semantics or machine readable definitions in the Wallet's server metadata, mapping a scope value to an equivalent 
`presentation_definition` object as defined in [@!DIF.PresentationExchange]. 

The definition MUST allow the verifier to determine the identifiers for presentation definition and input descriptors 
used in the respective presentation submission response parameter as well as the credential formats and types in 
the `vp_token` response parameter.  

It is RECOMMENDED to use collision-resistant scopes values.

Below is a non-normative example of an Authorization Request using the scope value `com.example.IDCardCredential_presentation`, 
which is an alias for the first presentation definition example given in (#request_presentation_definition):

```
  GET /authorize?
    response_type=vp_token
    &client_id=https%3A%2F%2Fclient.example.org%2Fcb
    &redirect_uri=https%3A%2F%2Fclient.example.org%2Fcb
    &scope=com.example.healthCardCredential_presentation
    &nonce=n-0S6_WzA2Mj HTTP/1.1
```

## Authorization Request in a Cross-Device flow

There are use-cases when the Authorization Request is being displayed on a device different from a device on which the requested Credential is stored. In those cases, an Authorization Request can be passed across devices by being rendered as a QR Code. 

The usage of the response mode `direct_post` (see (#response_mode_post)) in conjunction with `request_uri` is RECOMMENDED, since authorization request size might be large and might not fit in a QR code.

## `aud` of a Request Object

When an RP is sending a Request Object as defined in Section 6.1 of [@!OpenID.Core] or [@!RFC9101], the `aud` Claim value depends on whether the recipient of the request can be identified by the RP or not:

- the `aud` Claim MUST equal to the `issuer` Claim value, when Dynamic Discovery is performed.
- the `aud` Claim MUST be "https://self-issued.me/v2", when Static Discovery Metadata is used.

Note: "https://self-issued.me/v2" is a symbolic string and can be used as an `aud` Claim value even when this specification is used standalone, without SIOPv2. 

# Response {#vp_token_response}

## vp_token and Response Types

Whether `vp_token` is provided to the Client in the Authorization Response or Token Response depends on the response type used in the request (see (#vp_token_request)).

- If the response type value is `vp_token` or `vp_token id_token`, the `vp_token` is provided in the authorization response, with or without Self-Issued ID Token as defined in [@!SIOPv2].
- In all other cases, such as when response type is `code`, when the parameter `presentation_definition` is present in the Authorization Request, the `vp_token` is provided in the Token Response.

## Response Type vp_token {#response_type_vp_token}

This specification defines the response type `vp_token`. 

The reponse type `vp_token` can be used with different response modes as defined in [@!OAuth.Responses]. The default encoding is `fragment`, i.e. the Authorization Response parameters are encoded in the fragment added to the `redirect_uri` when redirecting back to the Client.

When response type is `vp_token`, response consists of the following parameters:

* `vp_token` REQUIRED. String parameter that MUST either contain a single Verifiable Presentation or an array of Verifiable Presentations. Each Verifiable Presentation MUST be represented as a JSON string (that is a Base64url encoded value) or a JSON object depending on a format as defined in Annex E of [@!OpenID.VCI]. If Appendix E of [@!OpenID.VCI] defines a rule for encoding the respective credential format in the credential response, this rules MUST also be followed when encoding credentials of this format in the `vp_token` response parameter. Otherwise, this specification does not require any additional encoding when a credential format is already represented as a JSON object or a JSON string.
* `presentation_submission`. REQUIRED. The `presentation_submission` element as defined in [@!DIF.PresentationExchange] links the input descriptor identifiers in the corresponding request to the respective Verifiable Presentations within the VP Token. The root of the path expressions in the descriptor map is the respective Verifiable Presentation, pointing to the respective Verifiable Credentials.
* `state` OPTIONAL. as defined in [@!RFC6749]

The `presentation_submission` element MUST be included as a separate response parameter alongside the vp_token. Clients MUST ignore any `presentation_submission` element included inside a VP.

Including the `presentation_submission` parameter as a separate response parameter allows the AS to provide the RP with additional information about the format and structure in advance of the processing of the VP Token, and can be used even with the credential formats that do not allow for the direct inclusion of `presentation_submission` parameters inside a credential itself.

In case the AS returns a single Verifiable Presentation in the VP Token, the `descriptor_map` would then contain a simple path expression "$".

The following is an example response to a request of a response type `vp_token`, where the `presentation_submission` is a separate response parameter: 

```
  HTTP/1.1 302 Found
  Location: https://client.example.org/cb#
    presentation_submission=...
    &vp_token=...
```

This is an example of a VP Token containing a single Verifiable Presentation

<{{examples/response/vp_token_raw_ldp_vp.json}}

with a matching `presentation_submission`.

<{{examples/response/presentation_submission.json}}

A `descriptor_map` element MUST contain a `path_nested` parameter referring to the actual credential carried in the respective Verifiable Presentation. 

This is an example of a VP Token containing multiple Verifiable Presentations,   

<{{examples/response/vp_token_multiple_vps.json}}

with a matching `presentation_submission` parameter.

<{{examples/response/presentation_submission_multiple_vps.json}}

## Signed and Encrypted Responses {#jarm}

Implementations MAY use JARM [@!JARM] to sign, or sign and encrypt the response on the application level. Furthermore, this specification allows for JARM with encrypted, unsigned responses, in which case, the JWT containing the response parameters is only encrypted.

For authorization responses with response type `vp_token`, the response JWT contains the following parameters as defined in (#response_type_vp_token):

* `vp_token` 
* `presentation_submission`
* `state`  

The key material used for encryption and signing SHOULD be determined using existing metadata mechanisms. 

To obtain Verifier's public key for the input to the key agreement to encrypt the Authorization Response, the Wallet MUST use `jwks` or `jwks_uri` claim within the `client_metadata` request parameter, or within the metadata defined in the Entity Configuration when [@!OpenID.Federation] is used.

To sign the Authorization Response, the Wallet MUST use a private key that corresponds to a public key made available in its metadata.

## Response Mode "direct_post" {#response_mode_post}

There are use-cases when the Authorization Request was received from a Verifier that is unreachable using redirects (i.e. it is on another device) from the Wallet on which the requested Credential is stored.

For such use-cases, this specification defines a new Response Mode `direct_post` to enable the Wallet to send the response to the Verifier via an HTTPS connection.

This specification defines the following Response Mode in accordance with [@!OAuth.Responses]:

direct_post
  In this mode, Authorization Response parameters are encoded in the body using the `application/x-www-form-urlencoded` content type and sent using the HTTP `POST` method instead of redirecting back to the Client.
  
HTTP POST request MUST be sent to the URL obtained from the `redirect_uri` parameter in the Authorization Request.

Note that Response Mode "direct_post" could be less secure than redirect-based Response Mode. For details, see (#session-binding).

The following is a non-normative example request object with Response Mode `direct_post`:

```json
{
   "client_id": "https://client.example.org/post",
   "redirect_uri": "https://client.example.org/post",
   "response_type": "vp_token",
   "response_mode": "direct_post"
   "presentation_definition": {...},
   "nonce": "n-0S6_WzA2Mj"
}
```

that could be used in a request URL like this (either directly or as QR Code). 

```
https://wallet.example.com?
    client_id=https%3A%2F%2Fclient.example.org%2Fcb
    &request_uri=https%3A%2F%2Fclient.example.org%2F567545564
```

The respective HTTP POST response to the Verifier would look like this:

```
  POST /post HTTP/1.1
    Host: client.example.org
    Content-Type: application/x-www-form-urlencoded

    presentation_submission=...&
    vp_token=...

```

Note that in the Cross-Device Flow, the Wallet can change the UI based on the Verifier's response to the HTTP POST request.

## Error Response

The error response follows the rules as defined in [@!RFC6749], with the following additional clarifications:

`invalid_scope`: 

- Requested scope value is invalid, unknown, or malformed.

`invalid_request`:

- The request contains more than a `presentation_definition` parameter or a `presentation_definition_uri` parameter or a 
scope value representing a presentation definition.

`invalid_client`:

- `client_metadata` or `client_metadata_uri` parameters defined in (#client_metadata_parameters) are present, but the Wallet recognizes `client_id` and knows metadata associated with it.
- Pre-registered client metadata has been found based on the `client_id`, but `client_metadata` parameter is also present.

Usage of `client_metadata` or `client_metadata_uri` parameters with `client_id` that the AS might be seeing for the first time is mutualy exclusive with the registration mechanism where Self-Issued OP assigns `client_id` to the RP after receiving RP's metadata.

This document also defines the following additional error codes and error descriptions:

`vp_formats_not_supported`

- The Wallet does not support any of the formats requested by the RP such as those included in the `vp_formats` registration parameter.

# Wallet Invocation {#wallet-invocation}

The Verifier has the choice of the following mechanisms to invoke a Wallet:

- Custom URL scheme as an `authorization_endpoint` (for example, `openid4vp://` as defined in (#openid4vp-profile))
- Domain-bound Universal Links/App link as an `authorization_endpoint`
- no specific `authorization_endpoint`, user scanning a QR code with Authorization Request using a manually opened Wallet, instead of an arbitrary camera application on a user-device (neither custom URL scheme nor Universal/App link is used)

# Authorization Server Metadata {#as_metadata_parameters}

This specification introduces additional AS metadata to enable Client and AS to determine credential formats, proof types and algorithms to be used in a protocol exchange.

## Additional Authorization Server Metadata parameters

This specification defines new server metadata parameters according to [@!RFC8414].

The AS publishes the formats it supports using the `vp_formats_supported` metadata parameter. 

* `presentation_definition_uri_supported`: OPTIONAL. Boolean value specifying whether the RP supports the transfer of `presentation_definition` by reference, with true indicating support. If omitted, the default value is true. 
* `vp_formats_supported`: REQUIRED. An object containing a list of key value pairs, where the key is a string identifying a credential format supported by the AS. Valid credential format identifiers values are defined in Annex E of [@!OpenID.VCI]. Other values may be used when defined in the profiles of this specification. The value is an object containing a parameter defined below:
* `alg_values_supported`: An object where the value is an array of case sensitive strings that identify the cryptographic suites that are supported. Cryptosuites for Verifiable Credentials in `jwt_vc_json`, `jwon_vc_json-ld`, `jwt_vp_json`, `jwon_vp_json-ld` formats should use algorithm names defined in [IANA JOSE Algorithms Registry](https://www.iana.org/assignments/jose/jose.xhtml#web-signature-encryption-algorithms). Cryptosuites for Verifiable Credentials in `ldp_vc` and `ldp_vp` format should use signature suites names defined in [Linked Data Cryptographic Suite Registry](https://w3c-ccg.github.io/ld-cryptosuite-registry/). Cryptosuites for Verifiable Credentials in `mso_mdoc` format should use signature suites names defined in ISO/IEC 18013-5:2021. Parties using other credential formats will need to agree upon the meanings of the values used, which may be context-specidic.

Below is a non-normative example of a `vp_formats_supported` parameter:

```
vp_formats_supported": {
‌ "jwt_vc": {
  ‌ "alg_values_supported": [
    ‌ "ES256K",
    ‌ "ES384"
  ‌ ]
‌ },
‌ "jwt_vp": {
  ‌ "alg_values_supported": [
    ‌ "ES256K",
     "EdDSA"
  ‌ ]
‌ }
}
```

## Obtaining Authorization Server Metadata

Client utilizing this specification has multiple options to obtain AS's metadata:

* Client obtains AS metadata prior to a transaction, e.g using [@!RFC8414] or out-of-band mechanisms. See (#as_metadata_parameters) for the details.
* Client has pre-obtained static set of AS metadata. See (#openid4vp-profile) for the example.

# Client Metadata

This specification introduces additional Client metadata to enable Client and AS to determine credential formats, proof types and algorithms to be used in a protocol exchange.

## Additional Client Metadata Parameters {#client_metadata_parameters}

This specification defines the following new client metadata parameters according to [@!RFC7591]:

* `vp_formats`: REQUIRED. An object defining the formats and proof types of verifiable presentations and verifiable credentials that a RP supports. Valid format identifier values are defined in Annex E of [@!OpenID.VCI] and include `jwt_vc_json`, `jwt_vc_json-ld`, `ldp_vc`, `jwt_vp_json`, `jwt_vp_json-ld`, `ldp_vp`, and `mso_mdoc`. Deployments can extend the formats supported, provided Issuers, Holders and Verifiers all understand the new format.
* `client_metadata` 
  * OPTIONAL. This parameter enables RP Metadata to be passed in a single, self-contained parameter. The value is a JSON object containing RP Registration Metadata values. The client metadata parameter value is represented in an OAuth 2.0 request as a UTF-8 encoded JSON object. MUST NOT be present if `client_metadata_uri` parameter is present.
* `client_metadata_uri` 
  * OPTIONAL. This parameter enables RP Registration Metadata to be passed by reference, rather than by value. The `request_uri` value is a URL referencing a resource containing a RP Registration Metadata Object. The scheme used in the `client_metadata_uri` value MUST be https. The `client_metadata_uri` value MUST be reachable by the AS. MUST NOT be present if `client_metadata` parameter is present.

Claims to be included in `client_metadata` and `client_metadata_uri` parameters are defined in Section 4.3 and Section 2.1 of the OpenID Connect Dynamic RP Registration 1.0 [@!OpenID.Registration] specification as well as [@!RFC7591].

## Obtaining Client Metadata 

AS utilizing this specification has multiple options to exchange metadata:

* AS obtains Client metadata prior to a transaction, e.g using [@!RFC7591] or out-of-band mechanisms. See (#pre-registered-rp) for the details.
* Client provides metadata to the AS just-in-time in the Authorization Request using one of the following mechanisms defined in this specification:
    * `client_metadata` or `client_metadata_uri` parameter when `client_id` equals `redirect_uri` (see (#simplest-registration) for the details), or `client_id` is a Decentralized Identifier (see (#DID) for the details).
    * Entity Statement when OpenID Federation 1.0 Automatic Registration is used (see (#opeid-federation) for the details).

Just-in-time metadata exchange allows OpenID4VP to be used in deployments models where the AS does not or cannot support pre-registration of Client metadata.

### Pre-Registered Relying Party {#pre-registered-rp}

When the Wallet has obtained Client metadata prior to a transaction, e.g using [@!RFC7591] or out-of-band mechanisms, `client_id` MUST equal to the client identifier the RP has obtained from the Wallet during pre-registration. When the Authorization Request is signed, the public key for signature verification MUST be (re-)obtained using pre-registration process.

In this case, `client_metadata` and `client_metadata_uri` parameters defined in (#client_metadata_parameters) MUST NOT be present in the Authorization Request. 

Below is an example for an RP registering using Dynamic Client Registration:

<{{examples/client_metadata/client_code_format.json}}

### Non-Pre-Registered Relying Party {#non-pre-registered-rp} 

When the RP has not pre-registered, it may pass its metadata to the AS in the Authorization Request.

No registration response is returned. A successful Authorization Response implicitly indicates that the client metadata parameters were accepted.

#### `client_id` equals `redirect_uri` {#simplest-registration}

In the simplest option, the Client can proceed without registration as if it had registered with the Wallet and obtained the following Client Registration Response:

* `client_id`
  * `redirect_uri` value of the RP.

In this case, the Authorization Request cannot be signed and all client metadata parameters MUST be passed using client metadata parameter defined in (#client_metadata_parameters).

Below is a non-normative example of a request when `client_id` equals `redirect_uri`.

```
  HTTP/1.1 302 Found
  Location: https://client.example.org/universal-link?
    response_type=vp_token
    &client_id=https%3A%2F%2Fclient.example.org%2Fcb
    &redirect_uri=https%3A%2F%2Fclient.example.org%2Fcb
    &presentation_definition=...
    &nonce=n-0S6_WzA2Mj
    &client_metadata=%7B%22vp_formats%22:%7B%22jwt_vp%22:%
    7B%22alg%22:%5B%22EdDSA%22,%22ES256K%22%5D%7D,%22ldp
    _vp%22:%7B%22proof_type%22:%5B%22Ed25519Signature201
    8%22%5D%7D%7D%7D
```

#### Decentralized Identifiers {#DID}

The `client_id` MAY be expressed as a Decentralized Identifier as defined in [@!DID-Core].

The Authorization Request MUST be signed. A public key to verify the signature MUST be obtained from the `verificationMethod` property of a DID Document. Since DID Document may include multiple public keys, a particular public key used to sign the request in question MUST be identified by the `kid` in the header. To obtain the DID Document, AS MUST use DID Resolution defined by the DID method used by the RP.

All RP metadata other than the public key MUST be obtained from the `client_metadata` parameter as defined in (#client_metadata_parameters).

Below is a non-normative example of a request when `client_id` is a DID, sent as a request object using `request_uri`:

<{{examples/client_metadata/client_client_id_did.json}}

#### OpenID Federation 1.0 Automatic Registration {#opeid-federation}

When Relying Party's `client_id` is expressed as an `https` URI, and does not equal to a `redirect_uri` value when using simple string comparison ([@!RFC3986] section 6.2.1), Automatic Registration defined in [@!OpenID.Federation] MUST be used. The Relying Party's Entity Identifier defined in Section 1.2 of [@!OpenID.Federation] MUST be `client_id`. 

The Authorization Request MUST be signed. The AS MUST obtain the public key from the `jwks` property in the Relying Party's Entity Statement defined in Section 3.1 of [@!OpenID.Federation]. Metadata other than the public keys MUST also be obtained from the Entity Statement.

Note that to use Automatic Registration, clients would be required to have an individual identifier and an associated public key(s), which is not always the case for the public/native app clients.

# Implementation Considerations

## Static Configuration Values of the Authorization Servers

This document lists profiles that define static configuration values of Authorization Servers and defines one set of static configuration values that can be used by the RP when it is unable to perform dynamic discovery and is not using any of the profiles.

### Profiles that Define Static Configuration Values

Below is a list of profiles that define static configuration values of Authorization Servers:

- [JWT VC Presentation Profile](https://identity.foundation/jwt-vc-presentation-profile/)

### A Set of Static Configuration Values bound to `openid4vp://` {#openid4vp-profile}

Below is a set of static configuration values that can be used with `vp_token` as a supported `response_type`, bound to a custom URL scheme `openid4vp://` as an `authorization_endpoint`:

```json
{
  "authorization_endpoint": "openid4vp:",
  "response_types_supported": [
    "vp_token"
  ],
  "vp_formats_supported": {
    "jwt_vp": {
      "alg": ["ES256"]
    },
    "jwt_vc": {
      "alg": ["ES256"]
    }
  },
  "request_object_signing_alg_values_supported": [
    "ES256"
  ]
}
```

## Support for Federations/Trust Schemes

Often RPs will want to request Verifiable Credentials from an issuer who is a participant of a federation, or adheres to a known trust scheme, rather than from a specific issuer, for example, a "BSc Chemistry Degree" credential from a US University rather than from a specifically named university.

In order to facilitate this, federations will need to determine how an issuer can indicate in a Verifiable Credential that they are a member of one or more federations/trust schemes. Once this is done, the RP will be able to create a `presentation_definition` that includes this filtering criteria. This will enable the Wallet to select all the Verifiable Credentials that match this criteria and then by some means (for example, by asking the user) determine which matching Verifiable Credential to return to the RP. Upon receiving this Verifiable Credential, the RP will be able to call its federation API to determine if the issuer is indeed a member of the federation/trust scheme that it says it is.

Indicating the federations/trust schemes used by an issuer MAY be achieved by defining a `termsOfUse` property [@!VC_DATA].

Note: [@!VC_DATA] describes terms of use as "can be utilized by an issuer ... to communicate the terms under which a Verifiable Credential ... was issued."

The following terms of use may be defined:

```json
{
   "termsOfUse":[
      {
         "type":"<uri that identifies this type of terms of use>",
         "federations":[
            "<list of federations/trust schemes the issuer asserts it is a member of>"
         ]
      }
   ]
}
```

Federations that conform to those specified in [@OpenID.Federation] are identified by the `type` `urn:ietf:params:oauth:federation`. Individual federations are identified by the entity id of the trust anchor. If the federation decides to use trust marks as signs of whether an entity belongs to a federation or not then the federation is identified by the `type` `urn:ietf:params:oauth:federation_trust_mark` and individual federations are identified by the entity id of the trust mark issuer.

Trust schemes that conform to the TRAIN [@TRAIN] trust scheme are identified by the `type` `https://train.trust-scheme.de/info`. Individual federations are identified by their DNS names.

An example `claims` parameter containing a `presentation_definition` that filters VCs based on their federation memberships is given below.

<{{examples/request/vp_token_federation.json}}

This example will chose a VC that has been issued by a university that is a member of the `ukuniversities.ac.uk` federation and that uses the TRAIN terms of use specification for asserting federation memberships.

## Nested Verifiable Presentations

Current version of this document does not support presentation of a VP nested inside another VP, even though [@!DIF.PresentationExchange] specification theoretically supports this by stating that the nesting of `path_nested` objects "may be any number of levels deep".

One level of nesting `path_nested` objects is sufficient to describe a VC included inside a VP.

# Security Considerations {#security_considerations}

## Sending VP Token using Response Mode "direct_post" {#session-binding}

When HTTP "POST" method is used to send VP Token, there is no session for the Verifier to validate whether the Response is sent by the same Wallet that has received the Authorization Request. It is RECOMMENDED for the Verifiers to implement mechanisms to strengthen such binding.

## Preventing Replay Attacks {#preventing-replay}

To prevent replay attacks, Verifiable Presentation container objects MUST be linked to `client_id` and `nonce` from the Authentication Request. The `client_id` is used to detect presentation of Verifiable Credentials to a different party other than the intended. The `nonce` value binds the presentation to a certain authentication transaction and allows the verifier to detect injection of a presentation in the OpenID Connect flow, which is especially important in flows where the presentation is passed through the front-channel. 

Note: These values MAY be represented in different ways in a Verifiable Presentation (directly as claims or indirectly be incorporation in proof calculation) according to the selected proof format denoted by the format claim in the Verifiable Presentation container.

Note: This specification assumes that a Verifiable Credential is always presented with a cryptographic proof of possession which can be a Verifiable Presentation. This cryptographic proof of possession is bound to audience and transaction as described in this section.

Here is a non-normative example for format=`jwt_vp` (only relevant part):

```json
{
  "iss": "did:example:ebfeb1f712ebc6f1c276e12ec21",
  "jti": "urn:uuid:3978344f-8596-4c3a-a978-8fcaba3903c5",
  "aud": "s6BhdRkqt3",
  "nonce": "343s$FSFDa-",
  "nbf": 1541493724,
  "iat": 1541493724,
  "exp": 1573029723,
  "vp": {
    "@context": [
      "<https://www.w3.org/2018/credentials/v1",>
      "<https://www.w3.org/2018/credentials/examples/v1">
    ],
    "type": ["VerifiablePresentation"],

    "verifiableCredential": [""]
  }
}
```

In the example above, the requested `nonce` value is included as the `nonce` and `client_id` as the `aud` value in the proof of the Verifiable Presentation.

Here is a non-normative example for format=`ldp_vp` (only relevant part):

```json
{
  "@context": [ ... ],
  "type": "VerifiablePresentation",
  "verifiableCredential": [ ... ],
  "proof": {
    "type": "RsaSignature2018",
    "created": "2018-09-14T21:19:10Z",
    "proofPurpose": "authentication",
    "verificationMethod": "did:example:ebfeb1f712ebc6f1c276e12ec21#keys-1",    
    "challenge": "343s$FSFDa-",
    "domain": "s6BhdRkqt3",
    "jws": "eyJhbGciOiJSUzI1NiIsImI2NCI6ZmFsc2UsImNyaXQiOlsiYjY0Il19..kTCYt5
      XsITJX1CxPCT8yAV-TVIw5WEuts01mq-pQy7UJiN5mgREEMGlv50aqzpqh4Qq_PbChOMqs
      LfRoPsnsgxD-WUcX16dUOqV0G_zS245-kronKb78cPktb3rk-BuQy72IFLN25DYuNzVBAh
      4vGHSrQyHUGlcTwLtjPAnKb78"
  }
}
```

In the example above, the requested `nonce` value is included as the `challenge` and `client_id` as the `domain` value in the proof of the Verifiable Presentation.

## Validation of Verifiable Presentations

A verifier MUST validate the integrity, authenticity, and holder binding of any Verifiable Presentation provided by an OP according to the rules of the respective presentation format. 

This requirement holds true even if those Verifiable Presentations are embedded within a signed OpenID Connect assertion, such as an ID Token or a UserInfo response. This is required because Verifiable Presentations might be signed by the same holder but with different key material and/or the OpenID Connect assertions may be signed by a third party (e.g., a traditional OP). In both cases, just checking the signature of the respective OpenID Connect assertion does not, for example, check the holder binding.

Note: Some of the available mechanisms are outlined in Section 4.3.2 of [@!DIF.PresentationExchange].

It is NOT RECOMMENDED for the Subject to delegate the presentation of the credential to a third party.

## Fetching Presentation Definitions by Reference

In many instances the referenced server will be operated by a known federation or other trusted operator, and the URL's domain name will already be widely known. OPs (including SIOPs) using this URI can mitigate request forgeries by having a pre-configured set of trusted domain names and only fetching presentation_definitions from these sources. In addition, the presentation definitions could be signed by a trusted authority, such as the ICO or federation operator.

## User Authentication using Verifiable Credentials

Clients intending to authenticate the end-user utilizing a claim in a verifable credential MUST ensure this claim is stable for the end-user as well locally unique and never reassigned within the credential issuer to another end-user. Such a claim MUST also only be used in combination with the issuer identifier to ensure global uniqueness and to prevent attacks where an attacker obtains the same claim from a different issuer and tries to impersonate the legitimate user. 

{backmatter}

<reference anchor="VC_DATA" target="https://www.w3.org/TR/vc-data-model">
  <front>
    <title>Verifiable Credentials Data Model 1.0</title>
    <author fullname="Manu Sporny">
      <organization>Digital Bazaar</organization>
    </author>
    <author fullname="Grant Noble">
      <organization>ConsenSys</organization>
    </author>
    <author fullname="Dave Longley">
      <organization>Digital Bazaar</organization>
    </author>
    <author fullname="Daniel C. Burnett">
      <organization>ConsenSys</organization>
    </author>
    <author fullname="Brent Zundel">
      <organization>Evernym</organization>
    </author>
    <author fullname="David Chadwick">
      <organization>University of Kent</organization>
    </author>
   <date day="19" month="Nov" year="2019"/>
  </front>
</reference>

<reference anchor="SIOPv2" target="https://openid.bitbucket.io/connect/openid-connect-self-issued-v2-1_0.html">
  <front>
    <title>Self-Issued OpenID Provider V2</title>
    <author ullname="Kristina Yasuda">
      <organization>Microsoft</organization>
    </author>
    <author fullname="Michael B. Jones">
      <organization>Microsoft</organization>
    </author>
    <author fullname="Tobias Looker">
      <organization>Mattr</organization>
    </author>
   <date day="20" month="Jul" year="2021"/>
  </front>
</reference>

<reference anchor="OpenID.Core" target="http://openid.net/specs/openid-connect-core-1_0.html">
  <front>
    <title>OpenID Connect Core 1.0 incorporating errata set 1</title>
    <author initials="N." surname="Sakimura" fullname="Nat Sakimura">
      <organization>NRI</organization>
    </author>
    <author initials="J." surname="Bradley" fullname="John Bradley">
      <organization>Ping Identity</organization>
    </author>
    <author initials="M." surname="Jones" fullname="Michael B. Jones">
      <organization>Microsoft</organization>
    </author>
    <author initials="B." surname="de Medeiros" fullname="Breno de Medeiros">
      <organization>Google</organization>
    </author>
    <author initials="C." surname="Mortimore" fullname="Chuck Mortimore">
      <organization>Salesforce</organization>
    </author>
   <date day="8" month="Nov" year="2014"/>
  </front>
</reference>

<reference anchor="DIF.PresentationExchange" target="https://identity.foundation/presentation-exchange">
        <front>
          <title>Presentation Exchange 2.0.0</title>
		  <author fullname="Daniel Buchner">
            <organization>Microsoft</organization>
          </author>
          <author fullname="Brent Zundel">
            <organization>Evernym</organization>
          </author>
          <author fullname="Martin Riedel">
            <organization>Consensys Mesh</organization>
          </author>
          <author fullname="Kim Hamilton Duffy">
            <organization>Centre Consortium</organization>
          </author>
        </front>
</reference>

<reference anchor="DID-Core" target="https://www.w3.org/TR/2021/PR-did-core-20210803/">
        <front>
        <title>Decentralized Identifiers (DIDs) v1.0</title>
        <author fullname="Manu Sporny">
            <organization>Digital Bazaar</organization>
        </author>
        <author fullname="Amy Guy">
            <organization>Digital Bazaar</organization>
        </author>
        <author fullname="Markus Sabadello">
            <organization>Danube Tech</organization>
        </author>
        <author fullname="Drummond Reed">
            <organization>Evernym</organization>
        </author>
        <date day="3" month="Aug" year="2021"/>
        </front>
</reference>

<reference anchor="TRAIN" target="https://oid2022.compute.dtu.dk/index.html">
        <front>
          <title>A novel approach to establish trust in Verifiable Credential
issuers in Self-Sovereign Identity ecosystems using TRAIN</title>	  
           <author fullname="Isaac Henderson Johnson Jeyakumar">
            <organization>University of Stuttgart</organization>
          </author>
          <author fullname="David W Chadwick">
            <organization>Crossword Cybersecurity</organization>
          </author>
          <author fullname="Michael Kubach">
            <organization>Fraunhofer IAO</organization>
          </author>
   <date day="8" month="July" year="2022"/>
        </front>
</reference>

<reference anchor="OpenID-Discovery" target="https://openid.net/specs/openid-connect-discovery-1_0.html">
  <front>
    <title>OpenID Connect Discovery 1.0 incorporating errata set 1</title>
    <author initials="N." surname="Sakimura" fullname="Nat Sakimura">
      <organization>NRI</organization>
    </author>
    <author initials="J." surname="Bradley" fullname="John Bradley">
      <organization>Ping Identity</organization>
    </author>
    <author initials="B." surname="de Medeiros" fullname="Breno de Medeiros">
      <organization>Google</organization>
    </author>
    <author initials="E." surname="Jay" fullname="Edmund Jay">
      <organization> Illumila </organization>
    </author>
   <date day="8" month="Nov" year="2014"/>
  </front>
</reference>

<reference anchor="OpenID.Registration" target="https://openid.net/specs/openid-connect-registration-1_0.html">
        <front>
          <title>OpenID Connect Dynamic Client Registration 1.0 incorporating errata set 1</title>
		  <author fullname="Nat Sakimura">
            <organization>NRI</organization>
          </author>
          <author fullname="John Bradley">
            <organization>Ping Identity</organization>
          </author>
          <author fullname="Michael B. Jones">
            <organization>Microsoft</organization>
          </author>
          <date day="8" month="Nov" year="2014"/>
        </front>
 </reference>

<reference anchor="Hyperledger.Indy" target="https://www.hyperledger.org/use/hyperledger-indy">
        <front>
          <title>Hyperledger Indy Project</title>
          <author>
            <organization>Hyperledger Indy Project</organization>
          </author>
          <date year="2022"/>
        </front>
</reference>

<reference anchor="JARM" target="https://openid.net/specs/oauth-v2-jarm-final.html">
        <front>
          <title>JWT Secured Authorization Response Mode for OAuth 2.0 (JARM)</title>
		  <author fullname="Torsten Lodderstedt">
            <organization>yes.com</organization>
          </author>
          <author fullname="Brian Campbell">
            <organization>Ping Identity</organization>
          </author>
          <date day="9" month="Nov" year="2022"/>
        </front>
 </reference>

<reference anchor="ISO.18013-5" target="https://www.iso.org/standard/69084.html">
        <front>
          <title>ISO/IEC 18013-5:2021 Personal identification — ISO-compliant driving licence — Part 5: Mobile driving licence (mDL)  application</title>
          <author>
            <organization> ISO/IEC JTC 1/SC 17 Cards and security devices for personal identification</organization>
          </author>
          <date year="2021"/>
        </front>
</reference>

<reference anchor="OAuth.Responses" target="https://openid.net/specs/oauth-v2-multiple-response-types-1_0.html">
        <front>
        <title>OAuth 2.0 Multiple Response Type Encoding Practices</title>
        <author initials="B." surname="de Medeiros" fullname="Breno de Medeiros">
            <organization>Google</organization>
        </author>
        <author initials="M." surname="Scurtescu" fullname="M. Scurtescu">
            <organization>Google</organization>
        </author>        
        <author initials="P." surname="Tarjan" fullname="Facebook">
            <organization>Evernym</organization>
        </author>
        <author initials="M." surname="Jones" fullname="Michael B. Jones">
            <organization>Microsoft</organization>
        </author>
        <date day="25" month="Feb" year="2014"/>
        </front>
</reference>

<reference anchor="OpenID.VCI" target="https://openid.net/specs/openid-4-verifiable-credential-issuance-1_0.html">
        <front>
          <title>OpenID for Verifiable Credential Issuance</title>
          <author initials="T." surname="Lodderstedt" fullname="Torsten Lodderstedt">
            <organization>yes.com</organization>
          </author>
          <author initials="K." surname="Yasuda" fullname="Kristina Yasuda">
            <organization>Microsoft</organization>
          </author>
          <author initials="T." surname="Looker" fullname="Tobias Looker">
            <organization>Mattr</organization>
          </author>
          <date day="20" month="June" year="2022"/>
        </front>
</reference>

<reference anchor="OpenID.Federation" target="https://openid.net/specs/openid-connect-federation-1_0.html">
        <front>
          <title>OpenID Connect Federation 1.0 - draft 17></title>
		  <author fullname="R. Hedberg, Ed.">
            <organization>Independent</organization>
          </author>
          <author fullname="Michael B. Jones">
            <organization>Microsoft</organization>
          </author>
          <author fullname="A. Solberg">
            <organization>Uninett</organization>
          </author>
          <author fullname="S. Gulliksson">
            <organization>Schibsted</organization>
          </author>
          <author fullname="John Bradley">
            <organization>Yubico</organization>
          </author>
          <date day="9" month="Sept" year="2021"/>
        </front>
 </reference>

# Examples {#alternative_credential_formats}

OpenID for Verifiable Presentations is credential format agnostic, i.e. it is designed to allow applications to request and receive Verifiable Presentations and Verifiable Credentials in any format, not limited to the formats defined in [@!VC_DATA]. This section aims to illustrate this with examples utilizing different credential formats. Customization of OpenID for Verifiable Presentation for credential formats other than those defined in [@!VC_DATA] uses extensions points of Presentation Exchange [@!DIF.PresentationExchange]. 

## JWT VCs

### Example Credential

The following is an JWT-based W3C Verifiable Credential that will be used through this section.

<{{examples/credentials/jwt_vc.json}}

### Presentation Request

This is an example presentation request. 

<{{examples/request/request.txt}}

The requirements regarding the credential to be presented are conveyed in the `presentation_definition` parameter. It's content is is given in the following example.

<{{examples/request/pd_jwt_vc.json}}

It contains a single `input_descriptor`, which sets the desired format to JWT VC and defines a constraint over the `vc.type` parameter to select Verifiable Credentials of type `IDCredential`. 

### Presentation Response

An example presentation response look like this:

<{{examples/response/response.txt}}

The content of the `presentation_submission` is given in the following: 

<{{examples/response/ps_jwt_vc.json}}

It refers to the VP in the `vp_token` parameter provided in the same response, which looks as follows.

<{{examples/response/jwt_vp.json}}

Note: the VP's `nonce` claim contains the value of the `nonce` of the presentation request and the `aud` claims contains the client id of the verifier. This allows the verifier to detect replay of a presentation as recommened in (#preventing-replay). 

## LDP VCs

The following is an LDP-based W3C Verifiable Credential that will be used through this section.

<{{examples/credentials/ldp_vc.json}}

### Presentation Request

This is an example presentation request. 

<{{examples/request/request.txt}}

The requirements regarding the credential to be presented are conveyed in the `presentation_definition` parameter. It's content is is given in the following example.

<{{examples/request/pd_ldp_vc.json}}

It contains a single `input_descriptor`, which sets the desired format to LDP VC and defines a constraint over the `type` parameter to select Verifiable Credentials of type `IDCardCredential`. 

### Presentation Response

An example presentation response look like this:

<{{examples/response/response.txt}}

The content of the `presentation_submission` is given in the following: 

<{{examples/response/ps_ldp_vc.json}}

It refers to the VP in the `vp_token` parameter provided in the same response, which looks as follows.

<{{examples/response/ldp_vp.json}}

Note: the VP's `challenge` claim contains the value of the `nonce` of the presentation request and the `domain` claims contains the client id of the verifier. This allows the verifier to detect replay of a presentation as recommened in (#preventing-replay). 

## AnonCreds

AnonCreds is a credential format defined as part of the Hyperledger Indy project [@Hyperledger.Indy].

To be able to request AnonCreds, there needs to be a set of identifiers for Verifiable Credentials, Verifiable Pesentations ("proofs" in Indy terminology) and crypto schemes. For the purpose of this example, the following identifiers are used: 

* `ac_vc`: designates a credential in AnonCreds format. 
* `ac_vp`: designates a presentation in AnonCreds format.
* `CLSignature2019`: identifies the CL-signature scheme used in conjunction with AnonCreds.

### Example Credential

The following is an example AnonCred credential that will be used through this section. 

<{{examples/credentials/ac_vc.json}}

The most important parts for the purpose of this example are `scheme_id` parameter and `values` parameter that contains the actual End-user claims. 

### Presentation Request 

#### Request Example

The example presentation request looks as follows:

<{{examples/request/request.txt}}

The following is the content of the `presentation_definition` parameter.

<{{examples/request/pd_ac_vc.json}}

The `format` object of the `input_descriptor` uses the format identifier `ac_vc` as defined above and sets the `proof_type` to `CLSignature2019` to denote this descriptor requires a credential in AnonCreds format signed with a CL signature (Camenisch-Lysyanskaya siganture). The rest of the expressions operate on the AnonCreds JSON structure.

The `constraints` object requires the selected credential to conform with the schema definition `did:indy:idu:test:3QowxFtwciWceMFr7WbwnM:2:BasicScheme:0\\.1`, which is denoted as a constraint over the AnonCred's `schema_id` parameter. 

#### Request Example with Selective Release of Claims

The next example leverages the AnonCreds' capabilities for selective disclosure by requesting a subset of the claims in the credential to be disclosed to the verifier.

The presentation looks the same as above. The difference is in the `presentation_definition` parameter as shown in the following:

<{{examples/request/pd_ac_vc_sd.json}}

This example is identic to the previous one with the following exceptions: It sets the elememt `limit_disclosure` of the constraint to `require` and adds two more constraints for the individual claims `given_name` and `family_name`. Since such claims are stored underneath a `values` container in an AnonCred, `values` is part of the path to identify the respective claim. 

### Presentation Response

The presentation response looks the same as fot the other examples.

<{{examples/response/response.txt}}

It contains the `presentation_submission` and `vp_token` parameters.  

The `presentation submission` looks like this:

<{{examples/response/ps_ac_vc_sd.json}}

The `descriptor_map` refers to the input descriptor `ref2` and tells the verifier that there is a proof of AnonCred credential (`format` is `ac_vp`) directly in the vp_token (path is the root designated by `$`). Furthermore it indicates using `nested_path` parameter that the user claims can be found embedded in the proof underneath `requested_proof.revealed_attr_groups.ref2`.

The following is a VP Token example.

<{{examples/response/ac_vp_sd.json}}

## ISO mobile Driving Licence (mDL)

This section illustrates how a mobile driving licence (mDL) credential expressed using a data model and data sets defined in [@ISO.18013-5] can be presented from the End-User's device directly to the RP using this specification.

To request an ISO/IEC 18013-5:2021 mDL, following identifiers are used for the purposes of this example:

* `mdl_iso_cbor`: designates a mobile driving licence (mDL) credential encoded as CBOR, expressed using a data model and data sets defined in [@ISO.18013-5].
* `mdl_iso_json`: designates a mobile driving licence (mDL) credential encoded as JSON, expressed using a data model and data sets defined in [@ISO.18013-5].

### Presentation Request 

The presentation request looks the same as for the other examples since the difference is in the content of the `presentation_definition` parameter. 

<{{examples/request/request.txt}}

The content of the `presentation_definition` parameter is as follows:

<{{examples/request/pd_mdl_iso_cbor.json}}

To start with, the `format` parameter of the `input_descriptor` is set to `mdl_iso_cbor`, i.e. it requests presentation of a mDL in CBOR format. 

To request user claims in ISO/IEC 18013-5:2021 mDL, a `doctype` and `namespace` of the claim needs to be specified. Moreover, the verifiers needs to indicate whether it intends to retain obtained user claims or not, using `intent_to_retain` property.

Note: `intent_to_retain` is a property introduced in this example to meet requirements of [@ISO.18013-5].

Setting `limit_disclosure` property defined in [@!DIF.PresentationExchange] to `required` enables selective release by instructing the Wallet to submit only the data parameters specified in the fields array. Selective release of claims is a requirement built into an ISO/IEC 18013-5:2021 mDL data model.

### Presentation Response

The presentation response looks the same as for the other examples.

<{{examples/response/response.txt}}

The following shows the `presentation_submission` content:

<{{examples/response/ps_mdl_iso_cbor.json}}

The `descriptor_map` refers to the input descriptor `mDL` and tells the verifier that there is an ISO/IEC 18013-5:2021 mDL (`format` is `mdl_iso_cbor`) in CBOR encoding directly in the `vp_token` (path is the root designated by `$`). 

When ISO/IEC 18013-5:2021 mDL is expressed in CBOR the `nested_path` parameter cannot be used to point to the location of the requested claims. The user claims will always be included in the `issuerSigned` item. `nested_path` parameter can be used, however, when a JSON-encoded ISO/IEC 18013-5:2021 mDL is returned.

The following is a non-normative example of an ISO/IEC 18013-5:2021 mDL encoded as CBOR in diagnostic notation (line wraps within values are for display purposes only) as conveyed in the `vp_token`parameter.

<{{examples/response/mdl_iso_cbor.json}}

In the `deviceSigned` item, `deviceAuth` item includes a signature by the deviceKey the belongs to the End-User. It is used to prove legitimate possession of the crdential, since the Issuer has signed over the deviceKey during the issuance of the credential. Note that deviceKey does not have to be HW-bound.

In the `issueSigned` item, `issuerAuth` item includes Issuer's signature over the hashes of the user claims, and `namespaces` items include user claims within each namespace that the End-User agreed to reveal to the verifier in that transaction.

Note that user claims in the `deviceSigned` item correspond to self-attested claims inside a Self-Issued ID Token (none in the example below), and user claims in the `issuerSigned` item correspond to the user claims included in a VP Token signed by a trusted third party.

Note that the reason why hashes of the user claims are included in the `issuerAuth` item lies in the selective release mechanism. Selective release of the user claims in an ISO/IEC 18013-5:2021 mDL is performed by the Issuer signing over the hashes of all the user claims during the issuance, and only the actual values of the claims that the End-User has agreed to reveal to teh Verifier being included during the presentation. 

The example in this section is also applicable to the electronic identification Verifiable Credentials expressed using data models defined in ISO/IEC TR 23220-2.

TBD: are `nonce` and `client_id` included into the mDL to detect replay?

## Combining this specificaiton with SIOPv2

This section shows how SIOP and OpenID for Verifiable Presentations can be combined to present Verifiable Credentials and pseudonymously authenticate an end-user using subject controlled key material.

### Request

This is an example request.

```
  GET /authorize?
    response_type=id_token
    &scope=openid
    &id_token_type=subject_signed
    &client_id=https%3A%2F%2Fclient.example.org%2Fcb
    &redirect_uri=https%3A%2F%2Fclient.example.org%2Fcb
    &presentation_definition=...
    &nonce=n-0S6_WzA2Mj HTTP/1.1
  Host: wallet.example.com
```

The differences to the example requests in the previous sections are:

* `response_type` is set to `id_token`. If the request also includes a `presentation_definition` parameter, the Wallet is supposed to return the `presentation_submission` and `vp_token` parameters in the same response as the `id_token` parameter. 
* The request includes the `scope` parameter with value `openid` making this a OpenID Connect request. Additionally, the request also contains the parameter `id_token_type` with value `subject_signed` requesting a Self-Issuer ID Token, i.e. the request is a SIOP request. 

### Response

The example response looks like this.

```
  HTTP/1.1 302 Found
  Location: https://client.example.org/cb#
    id_token=
    &presentation_submission=...
    &vp_token=...
```

In addition to the `presentation_submission` and `vp_token`, it also contains an `id_token`.

The `id_token` content is shown in the following.

```json
{
  "iss": "did:example:NzbLsXh8uDCcd6MNwXF4W7noWXFZAfHkxZsRGC9Xs",
  "sub": "did:example:NzbLsXh8uDCcd6MNwXF4W7noWXFZAfHkxZsRGC9Xs",
  "aud": "https://client.example.org/cb",
  "nonce": "n-0S6_WzA2Mj",
  "exp": 1311281970,
  "iat": 1311280970
}
```

Note: the `nonce` and `aud` are set to the `nonce` of the request and the client id of the verifier, respectively, in the same way as for the verifier, Verifiable Presentations to prevent replay. 

# IANA Considerations

* Response Type Name: `vp_token`
* Change Controller: OpenID Foundation Artifact Binding Working Group - openid-specs-ab@lists.openid.net
* Specification Document(s): https://openid.net/specs/openid-4-verifiable-presentations-1_0.html

* Response Type Name: `vp_token id_token`
* Change Controller: OpenID Foundation Artifact Binding Working Group - openid-specs-ab@lists.openid.net
* Specification Document(s): https://openid.net/specs/openid-4-verifiable-presentations-1_0.html

Note: Plan to register the following response types in the [OAuth Authorization Endpoint Response Types IANA Registry](https://www.iana.org/assignments/oauth-parameters/oauth-parameters.xhtml#endpoint).

# Acknowledgements {#Acknowledgements}

We would like to thank John Bradley, Brian Campbell, David Chadwick, Giuseppe De Marco, Daniel Fett, George Fletcher, Fabian Hauck, Joseph Heenan, Alen Horvat, Andrew Hughes, Edmund Jay, Michael B. Jones, Gaurav Khot, Ronald Koenig, Kenichi Nakamura, Nat Sakimura, Arjen van Veen, and Jacob Ward for their valuable feedback and contributions that helped to evolve this specification.

# Notices

Copyright (c) 2022 The OpenID Foundation.

The OpenID Foundation (OIDF) grants to any Contributor, developer, implementer, or other interested party a non-exclusive, royalty free, worldwide copyright license to reproduce, prepare derivative works from, distribute, perform and display, this Implementers Draft or Final Specification solely for the purposes of (i) developing specifications, and (ii) implementing Implementers Drafts and Final Specifications based on such documents, provided that attribution be made to the OIDF as the source of the material, but that such attribution does not indicate an endorsement by the OIDF.

The technology described in this specification was made available from contributions from various sources, including members of the OpenID Foundation and others. Although the OpenID Foundation has taken steps to help ensure that the technology is available for distribution, it takes no position regarding the validity or scope of any intellectual property or other rights that might be claimed to pertain to the implementation or use of the technology described in this specification or the extent to which any license under such rights might or might not be available; neither does it represent that it has made any independent effort to identify any such rights. The OpenID Foundation and the contributors to this specification make no (and hereby expressly disclaim any) warranties (express, implied, or otherwise), including implied warranties of merchantability, non-infringement, fitness for a particular purpose, or title, related to this specification, and the entire risk as to implementing this specification is assumed by the implementer. The OpenID Intellectual Property Rights policy requires contributors to offer a patent promise not to assert certain patent claims against other contributors and against implementers. The OpenID Foundation invites any interested party to bring to its attention any copyrights, patents, patent applications, or other proprietary rights that may cover technology that may be required to practice this specification.

# Document History

   [[ To be removed from the final specification ]]

   -14

   * added support for signed and encrypted authorization responses based on JARM
   * clarified response encoding for authorization responses
   * moved invocation/just-in-time client metadata exchange/AS Discovery sections from siopv2 to openid4vp

   -13

   * added scope support

   -12

   * add Cross-Device flow (using SIOP v2 text)
   * Added Client Metadata Section (based on SIOP v2 text)

   -11

   * changed base protocol to OAuth 2.0
   * consolidated the examples
  
   -10

   * Added AnonCreds example
   * Added ISO mobile Driving Licence (mDL) example

   -09

   * added support for passing presentation_definition by reference
   * added description how to requset credential issued by a member of a federation

   -08

   * reflected editorial comments received during pre-implementer's draft review period

   -07

   * added text on other credential formats
   * fixed inconsistency in security consideration regarding nonce

   -06

   * added additional security considerations
   * removed support for embedding Verifiable Presentations in ID Token or UserInfo response
   * migrated to Presentation Exchange 2.0

   -05

   * moved presentation submission parameters outside of Verifiable Presentations (ID Token or UserInfo)

   -04

   * added presentation submission support
   * cleaned up examples to use `nonce` & `client_id` instead of `vp_hash` for replay detection
   * fixed further nits in examples
   * added and reworked references to other specifications

   -03

   * aligned with SIOP v2 spec

   -02

   * added `presentation_definition` as sub parameter of `verifiable_presentation` and VP Token

   -01

   * adopted DIF Presentation Exchange request syntax
   * added security considerations regarding replay detection for Verifiable Credentials

   -00 

   *  initial revision
