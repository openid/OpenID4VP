%%%
title = "OpenID for Verifiable Presentations"
abbrev = "openid-4-vp"
ipr = "none"
workgroup = "connect"
keyword = ["security", "openid", "ssi"]

[seriesInfo]
name = "Internet-Draft"
value = "openid-4-verifiable-presentations-1_0-16"
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

This specification defines a mechanism on top of OAuth 2.0 [@!RFC6749] that enables presentation of Verifiable Credentials as Verifiable Presentations. Verifiable Credentials and Verifiable Presentations can be of any format, including, but not limited to W3C Verifiable Credentials Data Model [@VC_DATA], ISO mdoc [@ISO.18013-5], and AnonCreds [@Hyperledger.Indy].

OAuth 2.0 [@!RFC6749] is used as a base protocol as it provides the required rails to build simple, secure, and developer-friendly Credential presentation on top of it. Moreover, implementers can, in a single interface, support Credential presentation and the issuance of Access Tokens for access to APIs based on Verifiable Credentials in the Wallet. OpenID Connect [@!OpenID.Core] deployments can also extend their implementations using this specification with the ability to transport Verifiable Presentations. 

This specification can also be combined with [@!SIOPv2], if implementers require OpenID Connect features, such as the issuance of subject-signed ID Tokens.

# Terminology

This specification uses the terms "Access Token", "Authorization Request", "Authorization Response", "Client", "Client Authentication", "Client Identifier", "Grant Type", "Response Type", "Token Request" and "Token Response" defined by OAuth 2.0 [@!RFC6749], the terms "End-User", "Entity", "Request Object", "Request URI" as defined by OpenID Connect Core [@!OpenID.Core], the term "JSON Web Token (JWT)" defined by JSON Web Token (JWT) [@!RFC7519], the term "JOSE Header" and the term "Base64url Encoding" defined by JSON Web Signature (JWS) [@!RFC7515], and the term "Response Mode" defined by OAuth 2.0 Multiple Response Type Encoding Practices [@!OAuth.Responses].

This specification also defines the following terms. In the case where a term has a definition that differs, the definition below is authoritative.

Credential:
:  A set of one or more claims about a subject made by a Credential Issuer. Note that this definition of a term "credential" in this specification is different from that in [@!OpenID.Core].

Verifiable Credential (VC):
:  An Issuer-signed Credential whose authenticity can be cryptographically verified. Can be of any format used in the Issuer-Holder-Verifier Model, including, but not limited to those defined in [@VC_DATA], [@ISO.18013-5] (mdoc) and [@Hyperledger.Indy] (AnonCreds).

W3C Verifiable Credential:
:  A Verifiable Credential compliant to the [@VC_DATA] specification.

Presentation:
:  Data that is presented to a specific Verifier, derived from one or more Verifiable Credentials that can be from the same or different Credential Issuers.

Verifiable Presentation (VP):
:  A Holder-signed Credential whose authenticity can be cryptographically verified to provide Cryptographic Holder Binding. Can be of any format used in the Issuer-Holder-Verifier Model, including, but not limited to those defined in [@VC_DATA], [@ISO.18013-5] (mdoc) and [@Hyperledger.Indy] (AnonCreds).

W3C Verifiable Presentation:
:  A Verifiable Presentations compliant to the [@VC_DATA] specification.

Credential Issuer:
:  An entity that issues Verifiable Credentials. Also called Issuer.

Holder:
:  An entity that receives Verifiable Credentials and has control over them to present them to the Verifiers as Verifiable Presentations.

Verifier:
:  An entity that requests, receives and validates Verifiable Presentations. During presentation of Credentials, Verifier acts as an OAuth 2.0 Client towards the Wallet that is acting as an OAuth 2.0 Authorization Server. The Verifier is a specific case of OAuth 2.0 Client, just like Relying Party (RP) in [@OpenID.Core].

Issuer-Holder-Verifier Model:
:  A model for exchanging claims, where claims are issued in the form of Verifiable Credentials independent of the process of presenting them as Verifiable Presentation to the Verifiers. An issued Verifiable Credential can (but must not necessarily) be used multiple times.

Holder Binding: 
: Ability of the Holder to prove legitimate possession of a Verifiable Credential. 

Cryptographic Holder Binding:
:  Ability of the Holder to prove legitimate possession of a Verifiable Credential by proving control over the same private key during the issuance and presentation. Mechanism might depend on the Credential Format. For example, in `jwt_vc_json` Credential Format, a VC with Cryptographic Holder Binding contains a public key or a reference to a public key that matches to the private key controlled by the Holder. 

Claim-based Holder Binding:
:  Ability of the Holder to prove legitimate possession of a Verifiable Credential by proofing certain claims, e.g. name and date of birth, for example by presenting another Verifiable Credential. Claim-based Holder Binding allows long term, cross device use of a Credential as it does not depend on cryptographic key material stored on a certain device. One example of such a Verifiable Credential could be a Diploma.

Biometrics-based Holder Binding:
:  Ability of the Holder to prove legitimate possession of a Verifiable Credential by demonstrating a certain biometric trait, such as finger print or face. One example of a Verifiable Credential with biometric Holder Binding is a mobile drivers license [@ISO.18013-5], which contains a portrait of the Holder.

VP Token:
: An artifact defined in this specification that contains a single Verifiable Presentation or an array of Verifiable Presentations as defined in (#response-parameters).

Wallet:
:  An entity used by the Holder to receive, store, present, and manage Verifiable Credentials and key material. There is no single deployment model of a Wallet: Verifiable Credentials and keys can both be stored/managed locally, or by using a remote self-hosted service, or a remote third-party service. In the context of this specification, the Wallet acts as an OAuth 2.0 Authorization Server (see [@!RFC6749]) towards the Credential Verifier which acts as the OAuth 2.0 Client.

# Overview 

This specification defines a mechanism on top of OAuth 2.0 to request and present Verifiable Credentials as Verifiable Presentations.

As the primary extension, OpenID for Verifiable Presentations introduces the VP Token as a container to enable End-Users to present Verifiable Presentations to Verifiers using the Wallet. A VP Token contains one or more Verifiable Presentations in the same or different Credential formats.

This specification supports any Credential format used in the Issuer-Holder-Verifier Model, including, but not limited to those defined in [@VC_DATA], [@ISO.18013-5] (mdoc), and [@Hyperledger.Indy] (AnonCreds). Multiple Credential formats can be presented in the same transaction. The examples given in the main part of this specification use W3C Verifiable Credentials, examples in other Credential formats are given in (#alternative_credential_formats). 

Implementations can use any pre-existing OAuth 2.0 Grant Type and Response Type in conjunction with this specifications to support different deployment architectures.

OpenID for Verifiable Presentations supports scenarios where the Authorization Request is sent both when the Verifier is interacting with the End-User using the same or different device on which requested Credential(s) are stored.

This specification supports the response being sent using a redirect but also using an HTTP POST request. This enables the response to be sent across devices, or when the response size exceeds the redirect URL character size limitation.

Implementations can also be built on top of OpenID Connect Core, since OpenID Connect Core is based on OAuth 2.0. To benefit from the subject-signed ID Token feature, this specification can also be combined with the Self-Issued OP v2 specification [@SIOPv2].

Any of the OAuth 2.0 related specifications, such as [@RFC9126], and [@RFC9101] and Best Current Practice (BCP) documents, such as [@RFC8252] and [@I-D.ietf-oauth-security-topics], can be implemented on top of this specification.

# Scope

OpenID for Verifiable Presentations extends existing OAuth 2.0 mechanisms as following:

* A new `presentation_definition` Authorization Request parameter that uses the [@!DIF.PresentationExchange] syntax is defined to request presentation of Verifiable Credentials in arbitrary formats. See (#vp_token_request) for more details. 
* A new `vp_token` response parameter is defined to return Verifiable Presentations to the Verifier in either Authorization or Token Response depending on the response type. See (#response) for more details. 
* New Response Types `vp_token` and `id_token vp_token` are defined to request Verifiable Credentials to be returned in the Authorization Response (standalone or along with an OpenID Connect ID Token [@!OpenID.Core]). See (#response) for more details.
* A new OAuth 2.0 Response Mode `direct_post` is defined to support sending the response across devices, or when the size of the response exceeds the redirect URL character size limitation. See (#response_mode_post) for more detials.
* The [@!DIF.PresentationExchange] `format` parameter is used throughout the protocol in order to enable customization according to the specific needs of a particular Credential format. Examples in (#alternative_credential_formats) are given for credential formats as specified in [@VC_DATA], [@ISO.18013-5], and [@Hyperledger.Indy].
* A new `client_id_scheme` Authorization Request parameter is defined to enable deployments of this specification to use different mechanisms to obtain and validate metadata of the Verifier beyond the scope of [@!RFC6749].

Presentation of Credentials using OpenID for Verifiable Presentations can be combined with the user authentication using [@SIOPv2], and the issuance of OAuth 2.0 Access Tokens.

# Authorization Request {#vp_token_request}

The Authorization Request follows the definition given in [@!RFC6749].

The Verifier may send Authorization Request as Request Object by value or by reference as defined in Section 6.1 of [@!OpenID.Core] or [@RFC9101].

This specification defines the following new parameters:

`presentation_definition`:
: CONDITIONAL. A string containing a Presentation Definition JSON object as defined in Section 5 of [@!DIF.PresentationExchange]. See (#request_presentation_definition) for more details.

`presentation_definition_uri`:
: CONDITIONAL. A string containing an HTTPS URL pointing to a resource where a Presentation Definition JSON object as defined in Section 5 of [@!DIF.PresentationExchange] can be retrieved. See (#request_presentation_definition_uri) for more details.

`client_metadata`:
: OPTIONAL. This parameter enables Verifier's metadata to be passed in a single, self-contained parameter. The value is a JSON object containing metadata values. The `client_metadata` parameter value is represented in an OAuth 2.0 request as a UTF-8 encoded JSON object. MUST NOT be present if `client_metadata_uri` parameter is present.

`client_metadata_uri`: 
: OPTIONAL. This parameter enables Verifier's metadata to be passed by reference, rather than by value. The value is a URL referencing a resource containing a Verifier's metadata object. The scheme used in the `client_metadata_uri` value MUST be https. The `client_metadata_uri` value MUST be reachable by the Wallet. MUST NOT be present if `client_metadata` parameter is present.

`client_id_scheme`: 
: OPTIONAL. A string identifying the scheme of the value in the `client_id` Authorization Request parameter (Client Identifier scheme). The Verifier uses this parameter to indicate how the Wallet is supposed to interpret the Client Identifier and associated data in the process of Client identification, authentication, and authorization. A certain Client Identifier scheme MAY require the Verifier to sign the request as means of authentication and/or pass additional request parameters and require the Wallet to process those additional request parameters. The `client_id_scheme` parameter enables deployments of this specification to use different mechanisms to obtain and validate Client metadata beyond the scope of [@!RFC6749]. If the parameter is not present, the Wallet MUST behave as specified in [@!RFC6749]. See (#client_metadata_management) for the values defined by this specification. 
The `client_id_scheme` parameter namespaces the respective Client Identifier. This means if a request uses the `client_id_scheme` parameter, the Wallet MUST interpret the Client Identifier of the Verifier in the context of the Client Identifier scheme. If the same Client Identifier is used with different Client Identifier schemes, those occurences MUST be treated as different Verifiers. Note that the Verifier needs determine which client id schemes the Wallet supports prior to sending the Authorisation Request in order to choose a supported scheme.

Presentation Definition is a JSON Object that articulates what Verifiable Presentation(s) the Verifier is requesting to be presented as defined in Section 5 of [@!DIF.PresentationExchange].

Claims to be included in `client_metadata` and `client_metadata_uri` parameters are defined in Section 4.3 and Section 2.1 of the OpenID Connect Dynamic Client Registration 1.0 [@!OpenID.Registration] specification as well as [@!RFC7591]. 

A public key to be used by the Wallet as an input to the key agreement to encrypt Authorization Response (see (#jarm)) MAY be passed by the Verifier using `jwks` or `jwks_uri` claim within the `client_metadata` or `client_metadata_uri` request parameter. 

The following additional considerations are given for pre-existing Authorization Request parameters:

`nonce`:
: REQUIRED. Defined in  [@!OpenID.Core]. It is used to securely bind the Verifiable Presentation(s) provided by the Wallet to the particular transaction.

`scope`:
: OPTIONAL. Defined in [@!RFC6749]. The Wallet MAY allow Verifiers to request presentation of Verifiable Credentials by utilizing a pre-defined scope value. See (#request_scope) for more details.

`response_mode`:
: OPTIONAL. Defined in [@!OAuth.Responses]. This parameter is used (through the new response mode `direct_post`) to ask the Wallet to send the response to the Verifier via an HTTPS connection (see (#response_mode_post) for more details). It is also used to request signing and encrypting (see (#jarm) for more details). If the parameter is not present, the default value is `fragment`. 

The three ways to request Credential presentation are mutually exclusive. A request MUST NOT contain more than one of `presentation_definition`, `presentation_definition_uri`, or a `scope` value representing a Presentation Definition. The Wallet MUST refuse any request violating this requirement.

This is an example Authorization Request: 

```
  GET /authorize?
    response_type=vp_token
    &client_id=https%3A%2F%2Fclient.example.org%2Fcb
    &redirect_uri=https%3A%2F%2Fclient.example.org%2Fcb
    &presentation_definition=...
    &nonce=n-0S6_WzA2Mj HTTP/1.1
```

## `presentation_definition` Parameter {#request_presentation_definition}

This parameter contains a Presentation Definition JSON object conforming to the syntax defined in Section 5 of [@!DIF.PresentationExchange].

The following shows an example `presentation_definition` parameter:

<{{examples/request/vp_token_type_only.json}}

This simple example requests the presentation of a Credential of a certain type.

The following example shows how the Verifier can request selective disclosure or certain claims from a Credential of a particular type.

<{{examples/request/vp_token_type_and_claims.json}}

Clients can also ask for alternative Verifiable Credentials being presented, which is shown in the next example:

<{{examples/request/vp_token_alternative_credentials.json}}

The VC and VP formats supported by the Wallet should be published in its metadata using the metadata parameter `vp_formats_supported` (see (#as_metadata_parameters)). 

The formats supported by a Verifier may be set up using the metadata parameter `vp_formats` (see (#client_metadata_parameters)). The Wallet MUST ignore any `format` property inside a `presentation_definition` object if that `format` was not included in the `vp_formats` property of the metadata.

Note that when a Verifier is requesting presentation of a VP containing a VC, the Verifier MUST indicate in the `vp_formats` parameter the supported formats of both VC and VP.

## `presentation_definition_uri` Parameter {#request_presentation_definition_uri}

`presentation_definition_uri` is used to retrieve the Presentation Definition from the resource at the specified URL, rather than being passed by value. The Wallet will send a GET request without additional parameters. The resource MUST be exposed without further need to authenticate or authorize. 

The protocol for the `presentation_definition_uri` MUST be HTTPS.

For example the parameter value `https://server.example.com/presentationdefs?ref=idcard_presentation_request` will result in the following request 

```
  GET /presentationdefs?ref=idcard_presentation_request HTTP/1.1
  Host: server.example.com
```

and response:

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

Such a scope value MUST be an alias for a well-defined Presentation Definition as it will be 
referred to in the `presentation_submission` response parameter defined in (#response-parameters). 

The concrete scope values and the mapping between a certain scope value and the respective 
Presentation Definition is out of scope of this specification. 

Possible options include normative text in a separate specification defining scope values along with a description of their
semantics or machine readable definitions in the Wallet's server metadata, mapping a scope value to an equivalent 
`presentation_definition` object. 

Such definition of a scope value MUST allow the Verifier to determine the identifiers of the Presentation Definition and Input Descriptor(s) in the `presentation_submission` response parameter (`definition_id` and `descriptor_map.id` respectively) as well as the Credential formats and types in the `vp_token` response parameter defined in (#response-parameters).  

It is RECOMMENDED to use collision-resistant scopes values.

Below is a non-normative example of an Authorization Request using the scope value `com.example.IDCardCredential_presentation`, 
which is an alias for the first Presentation Definition example given in (#request_presentation_definition):

```
  GET /authorize?
    response_type=vp_token
    &client_id=https%3A%2F%2Fclient.example.org%2Fcb
    &redirect_uri=https%3A%2F%2Fclient.example.org%2Fcb
    &scope=com.example.healthCardCredential_presentation
    &nonce=n-0S6_WzA2Mj HTTP/1.1
```

## Response Type `vp_token` {#response_type_vp_token}

This specification defines the response type `vp_token`.

`vp_token`:
:  When supplied as the `response_type` parameter in an Authorization Request, a successful response MUST include the `vp_token` parameter. The Wallet SHOULD NOT return an OAuth 2.0 Authorization Code, Access Token, or Access Token Type in a successful response to the grant request. The default Response Mode for this Response Type is `fragment`, i.e. the Authorization Response parameters are encoded in the fragment added to the `redirect_uri` when redirecting back to the Client. The response type `vp_token` can be used with other response modes as defined in [@!OAuth.Responses]. Both successful and error responses SHOULD be returned using the supplied Response Mode, or if none is supplied, using the default Response Mode.

See (#response) on how the `response_type` value determines the response used to return a VP Token.

## Passing Authorization Request Across Devices

There are use-cases when the Authorization Request is being displayed on a device different from a device on which the requested Credential is stored. In those cases, an Authorization Request can be passed across devices by being rendered as a QR Code. 

The usage of the response mode `direct_post` (see (#response_mode_post)) in conjunction with `request_uri` is RECOMMENDED, since Authorization Request size might be large and might not fit in a QR code.

## `aud` of a Request Object

When the Verifier is sending a Request Object as defined in Section 6.1 of [@!OpenID.Core] or [@!RFC9101], the `aud` Claim value depends on whether the recipient of the request can be identified by the Verifier or not:

- the `aud` Claim MUST equal to the `issuer` Claim value, when Dynamic Discovery is performed.
- the `aud` Claim MUST be "https://self-issued.me/v2", when Static Discovery metadata is used.

Note: "https://self-issued.me/v2" is a symbolic string and can be used as an `aud` Claim value even when this specification is used standalone, without SIOPv2. 

## Client Metadata Management {#client_metadata_management}

The `client_id_scheme` enables deployments of this specification to use different mechanisms to obtain and validate metadata of the Verifier beyond the scope of [@!RFC6749].

This specification defines the following values for the `client_id_scheme` parameter, followed by the examples where applicable: 

* `pre-registered`: This value represents the [@!RFC6749] default behavior, i.e., the Client Identifier needs to be known to the Wallet in advance of the Authorization Request. The Verifier's metadata is obtained using [@!RFC7591] or through out-of-band mechanisms.

* `redirect_uri`: This value indicates that the Verifier's Redirect URI is also the value of the Client Identifier. In this case, the Authorization Request MUST NOT be signed, the Verifier MAY omit the `redirect_uri` Authorization Request parameter, and all Client metadata parameters MUST be passed using the `client_metadata` or `client_metadata_uri` parameter defined in (#vp_token_request). 

Below is a non-normative example of a request when `client_id` equals `redirect_uri`.

```
  HTTP/1.1 302 Found
  Location: https://client.example.org/universal-link?
    response_type=vp_token
    &client_id=https%3A%2F%2Fclient.example.org%2Fcb
    &client_id_scheme=redirect_uri
    &redirect_uri=https%3A%2F%2Fclient.example.org%2Fcb
    &presentation_definition=...
    &nonce=n-0S6_WzA2Mj
    &client_metadata=%7B%22vp_formats%22:%7B%22jwt_vp%22:%
    7B%22alg%22:%5B%22EdDSA%22,%22ES256K%22%5D%7D,%22ldp
    _vp%22:%7B%22proof_type%22:%5B%22Ed25519Signature201
    8%22%5D%7D%7D%7D
```

* `entity_id`: This value indicates that the Client Identifier is an Entity Identifier defined in OpenID Connect Federation [@!OpenID.Federation]. Processing rules given in [@!OpenID.Federation] MUST be followed. Automatic Registration as defined in [@!OpenID.Federation] MUST be used. The Authorization Request MAY also contain a `trust_chain` parameter. The Wallet MUST obtain Client metadata only from the Entity Statement(s). The `client_metadata` or `client_metadata_uri` parameter MUST NOT be present in the Authorization Request when this Client Identifier scheme is used.

* `did`: This value indicates that the Client Identifier is a DID defined in [@!DID-Core]. The request MUST be signed with a private key associated with the DID. A public key to verify the signature MUST be obtained from the `verificationMethod` property of a DID Document. Since DID Document may include multiple public keys, a particular public key used to sign the request in question MUST be identified by the `kid` in the JOSE Header. To obtain the DID Document, the Wallet MUST use DID Resolution defined by the DID method used by the Verifier. All Verifier metadata other than the public key MUST be obtained from the `client_metadata` or the `client_metadata_uri` parameter as defined in (#vp_token_request). 

Below is a non-normative example of a signed request when `client_id` is a DID:

Header

<{{examples/request/request_header_client_id_did.json}}

Body

<{{examples/request/request_object_client_id_did.json}}

Note that to use `client_id_scheme` values `entity_id` and `did`, Verifiers MUST be confidential clients. This might require changes to the technical design of native apps as such apps are typically public clients.

Other specifications can define further values for the `client_id_scheme` parameter. It is RECOMMENDED to use collision-resistant names for such values.

# Response {#response}

A VP Token is only returned if the corresponding Authorization Request contained a `presentation_definition` parameter, a `presentation_definition_uri` parameter, or a `scope` parameter representing a Presentation Definition (#vp_token_request).

VP Token can be returned in the Authorization Response or the Token Response depending on the Response Type used. See (#response_type_vp_token) for more details.

If the Response Type value is `vp_token`, the VP Token is returned in the Authorization Response. When the Response Type value is `vp_token id_token` and the `scope` parameter contains `openid`, the VP Token is returned in the Authorization Response alongside a Self-Issued ID Token as defined in [@!SIOPv2].

If the Response Type value is `code` (Authorization Code Grant Type), the VP Token is provided in the Token Response.

The expected behavior is summarized in the following table:

| `response_type` parameter value | Response containing the VP Token |
|:--- |:--- |
|`vp_token`|Authorization Response|
|`vp_token id_token`|Authorization Response|
|`code`|Token Response|

Table 1: OpenID for Verifiable Presentations `response_type` values

The behavior with respect to the VP Token is unspecified for any other individual Response Type value, or a combination of Response Type values.

## Response Parameters {#response-parameters}

When VP Token is returned, the respective response MUST include the following parameters:

`vp_token`:
: REQUIRED. JSON String or JSON object that MUST contain a single Verifiable Presentation or an array of JSON Strings and JSON objects each of them containing a Verifiable Presentations. Each Verifiable Presentation MUST be represented as a JSON string (that is a Base64url encoded value) or a JSON object depending on a format as defined in Annex E of [@!OpenID.VCI].  When a single Verifiable Presentation is returned, the array syntax MUST NOT be used.  If Appendix E of [@!OpenID.VCI] defines a rule for encoding the respective Credential format in the Credential Response, this rules MUST also be followed when encoding credentials of this format in the `vp_token` response parameter. Otherwise, this specification does not require any additional encoding when a Credential format is already represented as a JSON object or a JSON string.

`presentation_submission`:
: REQUIRED. The `presentation_submission` element as defined in [@!DIF.PresentationExchange]. It contains mappings between the requested Credentials and where to find them within the returned VP Token. This is expressed via elements in the `descriptor_map` array, known as Input Descriptor Map Objects. These objects contain a field called `path`, which, for this specification, MUST have the value `$` (top level root path) when only one Verifiable Presentation is contained in the VP Token, and MUST have the value `$[n]` (indexed path from root) when there are multiple Verifiable Presentations, where `n` is the index to select. The `path_nested` object inside an Input Descriptor Map Object is used to describe how to find a returned Credential within a Verifiable Presentation, and the value of the `path` field in it will ultimately depend on the credential format. Non-normative examples can be found further in this section. 

Other parameters, such as `state` or `code` (from [@!RFC6749]), or `id_token` (from [@!OpenID.Core]), and `iss` (from [@RFC9207]) MAY be included in the response as defined in the respective specifications.

The `presentation_submission` element MUST be included as a separate response parameter alongside the vp_token. Clients MUST ignore any `presentation_submission` element included inside a VP.

Including the `presentation_submission` parameter as a separate response parameter allows the Wallet to provide the Verifier with additional information about the format and structure in advance of the processing of the VP Token, and can be used even with the Credential formats that do not allow for the direct inclusion of `presentation_submission` parameters inside a Credential itself.

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

A `descriptor_map` element MUST contain a `path_nested` parameter referring to the actual Credential carried in the respective Verifiable Presentation. 

This is an example of a VP Token containing multiple Verifiable Presentations,   

<{{examples/response/vp_token_multiple_vps.json}}

with a matching `presentation_submission` parameter.

<{{examples/response/presentation_submission_multiple_vps.json}}

## Response Mode "direct_post" {#response_mode_post}

The response mode `direct_post` allows the Wallet to send the response data to an endpoint controlled by the Verifier via a HTTPS POST request. 

It has been defined to address the following use cases: 

* Verifier and Wallet are located on different devices, thus the Wallet cannot send the Authorization Response to the Wallet using a redirect.
* The Authorization Response size exeeds the URL length limits of user agents.
* The wallet is unable to, due to its application architecture, host an endpoint where the verifier can retrieve the response from.

The Response Mode is defined in accordance with [@!OAuth.Responses] as follows:

`direct_post`:
: In this mode, Authorization Response parameters are encoded in the body using the `application/x-www-form-urlencoded` content type and sent using the HTTP `POST` method instead of redirecting back to the Client.

The new Authorization Request parameter are defined to be used in conjunction with Response Mode `direct_post` as follows: 

`response_uri`:
: The URI to which the Wallet MUST send the Authorization Response using an HTTPS POST request as defined by the Response Mode `direct_post`. When this parameter is present, `redirect_uri` Request parameter MUST NOT be present.

If `redirect_uri` request parameter is present when the Response Mode is `direct_post`, the Wallet MUST return an `invalid_request` Authorization Response error.

The Response URI receives all parameters as defined by the respective Response Type.

Additionally, the following parameters are defined to be returned in the response from the Verifier to the Wallet upon receiving Authorization Response at the Response URI:

`nonce`:
: The value as received by the Wallet in the `nonce` Authorization Request parameter.  

The following is a non-normative example Request Object with Response Mode `direct_post`:

```json
{
   "client_id": "https://client.example.org/post",
   "response_uri": "https://client.example.org/post",
   "response_type": "vp_token",
   "response_mode": "direct_post",
   "presentation_definition": {...},
   "nonce": "n-0S6_WzA2Mj"
}
```

that could be used in a Request URI like this (either directly or as QR Code). 

```
https://wallet.example.com?
    client_id=https%3A%2F%2Fclient.example.org%2Fcb
    &request_uri=https%3A%2F%2Fclient.example.org%2F567545564
```

The following is a non-normative example of the response object that is sent via an HTTPS POST request to the Response URI:

```
  POST /post HTTP/1.1
    Host: client.example.org
    Content-Type: application/x-www-form-urlencoded

    presentation_submission=...&
    vp_token=...&
    nonce=n-0S6_WzA2Mj

```

If the request was processed sucessfully, the Verifier MUST respond with HTTP status code 200. The response MAY contain the following parameters:

`redirect_uri`:
:`redirect_uri`. The Wallet MUST send the User Agent to this URI. This allows the Verifier to continue the interaction with the End-User after the Wallet sends Authorization Response as an HTTPS POST request. It also allows the Verifier to ensure the transaction was conducted in a Wallet residing on the same device where the transaction started, or ensure the End-User interaction continues on the device where the Wallet resides when the transaction started on the different device. So that only the entitled front end can pick up the data from the Verifier's backend, Verifier's Response URI MUST add a secret to the Redirect URI, e.g. a code, that cannot be guessed by an attacker and validate this secrect when the response data is processed. For details how the Verifier MAY use this URI to ensure the End-to-End device binding of the transaction see (#security_consideration_direct_post_same_device). 

The following is a non-normative example of the response from the Verifier to the Wallet upon receiving Authorization Response at the Response URI:

```
  HTTP/1.1 200 OK
  Content-Type: application/json;charset=UTF-8
  Cache-Control: no-store

  {
    "redirect_uri":"https://client.example.org/cb#code=091535f699ea575c7937fa5f0f454aee",
  }
```

If the response does not contain a parameter, the Wallet is not required by this specification to perform any further steps.

Note: Response Mode `direct_post` without the `redirect_uri` could be less secure than the redirect-based Response Modes. For details, see (#session-binding).

Note that in the Response Mode `direct_post` or `direct_post.jwt`, the Wallet can change the UI based on the Verifier's response to the HTTP POST request.

## Signed and Encrypted Responses {#jarm}

This section defines how Authorization Response containing a VP Token can be signed and/or encrypted at the application level when the Response Type value is `vp_token` or `vp_token id_token`.

To sign, or sign and encrypt the Authorization Response, implementations MAY use JWT Secured Authorization Response Mode for OAuth 2.0 (JARM) [@!JARM]. 

To encrypt an unsigned Authorization Response, this specification extends [@!JARM] to allow the JWT containing the response parameters to be only encrypted as a JWE. 

If the JWT is only a JWE, the following processing rules MUST be followed:

- `iss`, `exp` and `aud` MUST be omitted in the JWT Claims Set of the JWE, and the processing rules as per [@!JARM] Section 2.4 related to these claims do not apply.
- The processing rules as per [@!JARM] Section 2.4 related to JWS processing MUST be ignored.

The following is a non-normative example of a JWT Claims Set used in an Authorization Response that is encrypted and not signed:

<{{examples/response/jarm_jwt_enc_only_vc_json_body.json}}

The JWT response document MUST include `vp_token` and `presentation_submission` parameters as defined in (#response-parameters).

The key material used for encryption and signing SHOULD be determined using existing metadata mechanisms. 

To obtain Verifier's public key for the input to the key agreement to encrypt the Authorization Response, the Wallet MUST use `jwks` or `jwks_uri` claim within the `client_metadata` request parameter, or within the metadata defined in the Entity Configuration when [@!OpenID.Federation] is used.

To sign the Authorization Response, the Wallet MUST use a private key that corresponds to a public key made available in its metadata.

### Response Mode "direct_post.jwt" {#direct_post_jwt}

This specification also defines a new Response Mode `direct_post.jwt`, which allows for JARM to be used with response mode `direct_post` defined in (#response_mode_post).

The Response Mode `direct_post.jwt` causes the Wallet to send the Authorization Response using the HTTP `POST` method instead of redirecting back to the Verifier as defined in (#response_mode_post). The Wallet adds the `response` parameter containing the JWT as defined in section 4.1. of [@!JARM] and (#jarm) in the body of HTTP POST request using the `application/x-www-form-urlencoded` content type.

The following is a non-normative example of a response using the `presentation_submission` and `vp_token` values from (#jwt_vc). (line breaks for display purposes only):

<{{examples/response/jarm_jwt_vc_json_post.txt}}

This is the JWT used in the example above before base64url encoding and signing:

<{{examples/response/jarm_jwt_vc_json_body.json}}

## Error Response

The error response follows the rules as defined in [@!RFC6749], with the following additional clarifications:

`invalid_scope`: 

- Requested scope value is invalid, unknown, or malformed.

`invalid_request`:

- The request contains more than one out of the following three options to communicate a requested credential: a `presentation_definition` parameter, a `presentation_definition_uri` parameter, or a scope value representing a Presentation Definition.
- Requested Presentation Definition does not conform to the DIF PEv2 specification [@!DIF.PresentationExchange].
- The Wallet does not support the `client_id_scheme` value passed in the Authorization Request.
- The Client Identifier passed in the request did not belong to the Client Identifier scheme indicated in the Authorization Request, or requirements of a certain scheme was violated, for example an unsigned request was sent with Client Identifier scheme `entity_id`.  

`invalid_client`:

- `client_metadata` or `client_metadata_uri` parameter defined in (#vp_token_request) is present, but the Wallet recognizes Client Identifier and knows metadata associated with it.
- Verifier's pre-registered metadata has been found based on the Client Identifier, but `client_metadata` parameter is also present.

Usage of `client_metadata` or `client_metadata_uri` parameters with `client_id` that the Wallet might be seeing for the first time is mutually exclusive with the registration mechanism where Self-Issued OP assigns `client_id` to the Verifier after receiving Verifier's metadata.

This document also defines the following additional error codes and error descriptions:

`vp_formats_not_supported`:

- The Wallet does not support any of the formats requested by the Verifier, such as those included in the `vp_formats` registration parameter.

`invalid_presentation_definition_uri`:

- The Presentation Definition URL cannot be reached.

`invalid_presentation_definition_reference`:

- The Presentation Definition URL can be reached, but the specified `presentation_definition` cannot be found at the URL.

# Wallet Invocation {#wallet-invocation}

The Verifier has the choice of the following mechanisms to invoke a Wallet:

- Custom URL scheme as an `authorization_endpoint` (for example, `openid4vp://` as defined in (#openid4vp-profile))
- Domain-bound Universal Links/App link as an `authorization_endpoint`
- no specific `authorization_endpoint`, user scanning a QR code with Authorization Request using a manually opened Wallet, instead of an arbitrary camera application on a user-device (neither custom URL scheme nor Universal/App link is used)

# Wallet Metadata (Authorization Server Metadata) {#as_metadata_parameters}

This specification defines how the Verifier can determine Credential formats, proof types and algorithms supported by the Wallet to be used in a protocol exchange.

## Additional Wallet Metadata Parameters

This specification defines new metadata parameters according to [@!RFC8414].

* `presentation_definition_uri_supported`: OPTIONAL. Boolean value specifying whether the Wallet supports the transfer of `presentation_definition` by reference, with true indicating support. If omitted, the default value is true.
* `vp_formats_supported`: REQUIRED. An object containing a list of key value pairs, where the key is a string identifying a Credential format supported by the Wallet. Valid Credential format identifier values are defined in Annex E of [@!OpenID.VCI]. Other values may be used when defined in the profiles of this specification. The value is an object containing a parameter defined below:
    * `alg_values_supported`: An object where the value is an array of case sensitive strings that identify the cryptographic suites that are supported. Cipher suites for Verifiable Credentials in `jwt_vc_json`, `json_vc_json-ld`, `jwt_vp_json`, `json_vp_json-ld` formats should use algorithm names defined in [IANA JOSE Algorithms Registry](https://www.iana.org/assignments/jose/jose.xhtml#web-signature-encryption-algorithms). Cipher suites for Verifiable Credentials in `ldp_vc` and `ldp_vp` format should use signature suites names defined in [Linked Data Cryptographic Suite Registry](https://w3c-ccg.github.io/ld-cryptosuite-registry/). Cipher suites for Verifiable Credentials in `mso_mdoc` format should use signature suites names defined in ISO/IEC 18013-5:2021. Parties using other Credential formats will need to agree upon the meanings of the values used, which may be context-specific.

Below is a non-normative example of a `vp_formats_supported` parameter:

```
vp_formats_supported": {
‌ "jwt_vc_json": {
  ‌ "alg_values_supported": [
    ‌ "ES256K",
    ‌ "ES384"
  ‌ ]
‌ },
‌ "jwt_vp_json": {
  ‌ "alg_values_supported": [
    ‌ "ES256K",
     "EdDSA"
  ‌ ]
‌ }
}
```

`client_id_schemes_supported`:
: OPTIONAL. Array of JSON Strings containing the values of the Client Identifier schemes that the Wallet supports. The values defined by this specification are `pre-registered`, `redirect_uri`, `entity_id`, `did`. If omitted, the default value is `pre-registered`. Other values may be used when defined in the profiles of this specification.

## Obtaining Wallet's Metadata

Verifier utilizing this specification has multiple options to obtain Wallet's metadata:

* Verifier obtains Wallet's metadata prior to a transaction, e.g. using [@!RFC8414] or out-of-band mechanisms. See (#as_metadata_parameters) for the details.
* Verifier has pre-obtained static set of Wallet's metadata. See (#openid4vp-profile) for the example.

# Verifier Metadata (Client Metadata) {#client_metadata}

Client metadata defined in Section 2 of [@!RFC7591] is used to convey Verifier's metadata. 

This specification defines how the Wallet can determine Credential formats, proof types and algorithms supported by the Verifier to be used in a protocol exchange.

## Additional Verifier Metadata Parameters {#client_metadata_parameters}

This specification defines the following new metadata parameters according to [@!RFC7591], to be used by the Verifier:

`vp_formats`:
: REQUIRED. An object defining the formats and proof types of Verifiable Presentations and Verifiable Credentials that a Verifier supports. Valid format identifier values are defined in Annex E of [@!OpenID.VCI] and include `jwt_vc_json`, `jwt_vc_json-ld`, `ldp_vc`, `jwt_vp_json`, `jwt_vp_json-ld`, `ldp_vp`, and `mso_mdoc`. Deployments can extend the formats supported, provided Issuers, Holders and Verifiers all understand the new format.

`client_id_scheme`:
: OPTIONAL. JSON String identifying the client's id scheme. The value range defined by this specification is `pre-registered`, `redirect_uri`, `entity_id`, `did`. If omitted, the default value is `pre-registered`. 

# Implementation Considerations

## Static Configuration Values of the Wallets

This document lists profiles that define static configuration values of the Wallets and defines one set of static configuration values that can be used by the Verifier when it is unable to perform dynamic discovery and is not using any of the profiles.

### Profiles that Define Static Configuration Values

Below is a list of profiles that define static configuration values of Wallets:

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
    "jwt_vp_json": {
      "alg_values_supported": ["ES256"]
    },
    "jwt_vc_json": {
      "alg_values_supported": ["ES256"]
    }
  },
  "request_object_signing_alg_values_supported": [
    "ES256"
  ]
}
```

## Support for Federations/Trust Schemes

Often Clients will want to request Verifiable Credentials from a Credential Issuer who is a participant of a federation, or adheres to a known trust scheme, rather than from a specific Credential Issuer, for example, a "BSc Chemistry Degree" Credential from a US University rather than from a specifically named university.

In order to facilitate this, federations will need to determine how a Credential Issuer can indicate in a Verifiable Credential that they are a member of one or more federations/trust schemes. Once this is done, the Verifier will be able to create a `presentation_definition` that includes this filtering criteria. This will enable the Wallet to select all the Verifiable Credentials that match this criteria and then by some means (for example, by asking the user) determine which matching Verifiable Credential to return to the Client. Upon receiving this Verifiable Credential, the Verifier will be able to call its federation API to determine if the Credential Issuer is indeed a member of the federation/trust scheme that it says it is.

Indicating the federations/trust schemes used by a Credential Issuer MAY be achieved by defining a `termsOfUse` property [@!VC_DATA].

Note: [@!VC_DATA] describes terms of use as "can be utilized by a Credential Issuer ... to communicate the terms under which a Verifiable Credential ... was issued."

The following terms of use may be defined:

```json
{
   "termsOfUse":[
      {
         "type":"<uri that identifies this type of terms of use>",
         "federations":[
            "<list of federations/trust schemes the Credential Issuer asserts it is a member of>"
         ]
      }
   ]
}
```

Federations that conform to those specified in [@OpenID.Federation] are identified by the `type` `urn:ietf:params:oauth:federation`. Individual federations are identified by the Entity Identifier of the trust anchor. If the federation decides to use trust marks as signs of whether an entity belongs to a federation or not then the federation is identified by the `type` `urn:ietf:params:oauth:federation_trust_mark` and individual federations are identified by the Entity Identifier of the trust mark issuer.

Trust schemes that conform to the TRAIN [@TRAIN] trust scheme are identified by the `type` `https://train.trust-scheme.de/info`. Individual federations are identified by their DNS names.

An example `claims` parameter containing a `presentation_definition` that filters VCs based on their federation memberships is given below.

<{{examples/request/vp_token_federation.json}}

This example will choose a VC that has been issued by a university that is a member of the `ukuniversities.ac.uk` federation and that uses the TRAIN terms of use specification for asserting federation memberships.

## Nested Verifiable Presentations

Current version of this document does not support presentation of a VP nested inside another VP, even though [@!DIF.PresentationExchange] specification theoretically supports this by stating that the nesting of `path_nested` objects "may be any number of levels deep".

One level of nesting `path_nested` objects is sufficient to describe a VC included inside a VP.

# Security Considerations {#security_considerations}

## Sending VP Token using Response Mode "direct_post" 

### With Redirect URI {#security_consideration_direct_post_same_device}

The Redirect URI allows the Verifier to check whether the transaction was concluded in a Wallet residing on the same device where the flow was started. The Verifier MUST therefore include a transaction specific secret into the Redirect URI. 

The concrete design is at the discretion of the Verifier since it does not affect the interface between the Verifier and the Wallet. 

This specification proposes a design that is inspired by the way the Authorization Code flow [@!RFC6749] works in conjunction with PKCE [@!RFC7636]. 

This is the design proposal: 

1. The Verifier creates a transaction specific secret `secret` and hashes it with a suitable hashing algorithm. 
2. The Verifier sends the hashed secret as `nonce` parameter value with the authorization request. 
3. The Wallet will send the `nonce` value with the request to the Response URI. 
4. The Verifier (Backend) stores the response data (linked to the `nonce` value) and creates a fresh response code that it also links with the respective response data. 
5. The Verifier (Backend) returns the Redirect URI, which contains the Response Code as `code` parameter.
6. The Verifier (Frontend) receives the Request and extracts the `code` parameter.
7. The Verifier (Frontend) sends the `code` and the transaction specific secret `secret` to its backend to process the authorization response.
8. The Verifier (Backend) checks whether `code` and the hash of `secret` is associated with any of the response data packages it has stored. 
9. If this check succeeds, the transaction continues with the processing of the respective response data. Otherwise, the transaction is aborted. 

### Without Redirect URI {#session-binding}

When HTTP "POST" method is used to send VP Token without the further protection provided by the redirect URI, there is no session for the Verifier to validate whether the Response is sent by the same Wallet that has received the Authorization Request. It is RECOMMENDED for the Verifiers to implement mechanisms to strengthen such binding. For more details on possible attacks and mitigations see [@I-D.ietf-oauth-cross-device-security].

## Preventing Replay Attacks {#preventing-replay}

To prevent replay attacks, Verifiable Presentation container objects MUST be linked to `client_id` and `nonce` from the Authentication Request. The `client_id` is used to detect presentation of Verifiable Credentials to a different party other than the intended. The `nonce` value binds the Presentation to a certain authentication transaction and allows the Verifier to detect injection of a Presentation in the flow, which is especially important in the flows where the Presentation is passed through the front-channel. 

Note: These values MAY be represented in different ways in a Verifiable Presentation (directly as claims or indirectly be incorporation in proof calculation) according to the selected proof format denoted by the format claim in the Verifiable Presentation container.

Note: This specification assumes that a Verifiable Credential is always presented with a cryptographic proof of possession which can be a Verifiable Presentation. This cryptographic proof of possession is bound to audience and transaction as described in this section.

Here is a non-normative example of a Verifiable Presentation with a format identifier `jwt_vp_json` (only relevant part):

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
      "https://www.w3.org/2018/credentials/v1",
      "https://www.w3.org/2018/credentials/examples/v1"
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

A Verifier MUST validate the integrity, authenticity, and Holder Binding of any Verifiable Presentation provided by an OP according to the rules of the respective Presentation format. 

This requirement holds true even if those Verifiable Presentations are embedded within a signed OpenID Connect assertion, such as an ID Token or a UserInfo response. This is required because Verifiable Presentations might be signed by the same Holder but with different key material and/or the OpenID Connect assertions may be signed by a third party (e.g., a traditional OP). In both cases, just checking the signature of the respective OpenID Connect assertion does not, for example, check the Holder Binding.

Note: Some of the available mechanisms are outlined in Section 4.3.2 of [@!DIF.PresentationExchange].

It is NOT RECOMMENDED for the Subject to delegate the presentation of the Credential to a third party.

## Fetching Presentation Definitions by Reference

In many instances the referenced server will be operated by a known federation or other trusted operator, and the URL's domain name will already be widely known. OPs (including SIOPs) using this URI can mitigate request forgeries by having a pre-configured set of trusted domain names and only fetching Presentation Definition from these sources. In addition, the Presentation Definitions could be signed by a trusted authority, such as the ICO or federation operator.

## User Authentication using Verifiable Credentials

Clients intending to authenticate the end-user utilizing a claim in a Verifiable Credential MUST ensure this claim is stable for the end-user as well locally unique and never reassigned within the Credential Issuer to another end-user. Such a claim MUST also only be used in combination with the Credential Issuer identifier to ensure global uniqueness and to prevent attacks where an attacker obtains the same claim from a different Credential Issuer and tries to impersonate the legitimate user. 

## JSONPath and Arbitrary Scripting 

Implementers MUST make sure that JSONPath used as part of `presentation_definition` and `presentation_submission` parameters cannot be used to execute arbitrary scripts on a server. This can be achieved, for example, by implementing the entire syntax of the query without relying on the parsers of programming language engine. For details, see Section 4 of [@I-D.ietf-jsonpath-base].

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
    <author fullname="Kristina Yasuda">
      <organization>Microsoft</organization>
    </author>
    <author fullname="Michael B. Jones">
      <organization>Microsoft</organization>
    </author>
    <author initials="T." surname="Lodderstedt" fullname="Torsten Lodderstedt">
      <organization>yes.com</organization>
    </author>
   <date day="1" month="January" year="2023"/>
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
          <date day="3" month="February" year="2023"/>
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

OpenID for Verifiable Presentations is Credential format agnostic, i.e. it is designed to allow applications to request and receive Verifiable Presentations and Verifiable Credentials in any format, not limited to the formats defined in [@!VC_DATA]. This section aims to illustrate this with examples utilizing different Credential formats. Customization of OpenID for Verifiable Presentation for Credential formats other than those defined in [@!VC_DATA] uses extension points of Presentation Exchange [@!DIF.PresentationExchange]. 

## W3C Verifiable Credentials

### VC signed as a JWT, not using JSON-LD {#jwt_vc}

The following is an example of a presentation of a Credential conformant to [@VC_DATA] that is signed using JWS, and does not use JSON-LD. It will be used throughout this section.

The Credential format identifiers are `jwt_vc_json` for a W3C Verifiable Credential and `jwt_vp_json` for W3C Verifiable Presentation.

#### Example Credential

The following is a JWT-based W3C Verifiable Credential that will be used through this section.

<{{examples/credentials/jwt_vc.json}}

#### Presentation Request

This is an example presentation request. 

<{{examples/request/request.txt}}

The requirements regarding the Credential to be presented are conveyed in the `presentation_definition` parameter. Its content is given in the following example.

<{{examples/request/pd_jwt_vc.json}}

It contains a single `input_descriptor` element, which sets the desired format to JWT VC and defines a constraint over the `vc.type` parameter to select Verifiable Credentials of type `IDCredential`. 

#### Presentation Response

An example presentation response would look like this:

<{{examples/response/response.txt}}

The content of the `presentation_submission` is given in the following: 

<{{examples/response/ps_jwt_vc.json}}

It refers to the VP in the `vp_token` parameter provided in the same response, which looks as follows.

<{{examples/response/jwt_vp.json}}

Note: the VP's `nonce` claim contains the value of the `nonce` of the presentation request and the `aud` claims contains the Client ID of the Verifier. This allows the Verifier to detect replay of a Presentation as recommended in (#preventing-replay). 

### LDP VCs

The following is an example of a presentation of a Credential conformant to [@VC_DATA] that is secured using Data Integrity, using JSON-LD. It will be used throughout this section.

The Credential format identifiers are `ldp_vc` for a W3C Verifiable Credential and `ldp_vp` for W3C Verifiable Presentation.

<{{examples/credentials/ldp_vc.json}}

#### Presentation Request

This is an example presentation request. 

<{{examples/request/request.txt}}

The requirements regarding the Credential to be presented are conveyed in the `presentation_definition` parameter. Its content is given in the following example.

<{{examples/request/pd_ldp_vc.json}}

It contains a single `input_descriptor` element, which sets the desired format to LDP VC and defines a constraint over the `type` parameter to select Verifiable Credentials of type `IDredential`. 

#### Presentation Response

An example presentation response would look like this:

<{{examples/response/response.txt}}

The content of the `presentation_submission` is given in the following: 

<{{examples/response/ps_ldp_vc.json}}

It refers to the VP in the `vp_token` parameter provided in the same response, which looks as follows.

<{{examples/response/ldp_vp.json}}

Note: the VP's `challenge` claim contains the value of the `nonce` of the presentation request and the `domain` claims contains the Client ID of the Verifier. This allows the Verifier to detect replay of a presentation as recommended in (#preventing-replay). 

## AnonCreds

AnonCreds is a Credential format defined as part of the Hyperledger Indy project [@Hyperledger.Indy].

To be able to request AnonCreds, there needs to be a set of identifiers for Verifiable Credentials, Verifiable Presentations ("proofs" in Indy terminology) and crypto schemes.

Credential format identifier is `ac_vc` for a Credential, and `ac_vp` for a Presentation.

Identifier for a CL-signature crypto scheme used in the examples in this section is `CLSignature2019`.

### Example Credential

The following is an example AnonCred Credential that will be used through this section. 

<{{examples/credentials/ac_vc.json}}

The most important parts for the purpose of this example are `scheme_id` parameter and `values` parameter that contains the actual End-User claims. 

### Presentation Request 

#### Request Example

The example presentation request looks as follows:

<{{examples/request/request.txt}}

The following is the content of the `presentation_definition` parameter.

<{{examples/request/pd_ac_vc.json}}

The `format` object in the `input_descrioptor` element uses the format identifier `ac_vc` as defined above and sets the `proof_type` to `CLSignature2019` to denote this descriptor requires a Credential in AnonCreds format signed with a CL signature (Camenisch-Lysyanskaya signature). The rest of the expressions operate on the AnonCreds JSON structure.

The `constraints` object requires the selected Credential to conform with the schema definition `did:indy:idu:test:3QowxFtwciWceMFr7WbwnM:2:BasicScheme:0\\.1`, which is denoted as a constraint over the AnonCred's `schema_id` parameter. 

#### Request Example with Selective Release of Claims

The next example leverages the AnonCreds' capabilities for selective disclosure by requesting a subset of the claims in the Credential to be disclosed to the Verifier.

The presentation request looks the same as above. The difference is in the `presentation_definition` parameter as shown in the following:

<{{examples/request/pd_ac_vc_sd.json}}

This example is identic to the previous one with the following exceptions: It sets the element `limit_disclosure` of the constraint to `require` and adds two more constraints for the individual claims `given_name` and `family_name`. Since such claims are stored underneath a `values` container in an AnonCred, `values` is part of the path to identify the respective claims. 

### Presentation Response

The presentation response looks the same as for the other examples.

<{{examples/response/response.txt}}

It contains the `presentation_submission` and `vp_token` parameters.  

The `presentation_submission` content looks like this:

<{{examples/response/ps_ac_vc_sd.json}}

The `descriptor_map` refers to the `input_descriptor` element with an identifier `id_credential` and tells the Verifier that there is a proof of AnonCred Credential (`format` is `ac_vp`) directly in the vp_token (path is the root designated by `$`). Furthermore it indicates using `path_nested` parameter that the user claims can be found embedded in the proof underneath `requested_proof.revealed_attr_groups.id_card_credential`.

The following is a VP Token example.

<{{examples/response/ac_vp_sd.json}}

## ISO mobile Driving Licence (mDL)

This section illustrates how a mobile driving licence (mDL) Credential expressed using a data model and data sets defined in [@ISO.18013-5] encoded as CBOR can be presented from the End-User's device directly to the Verifier using this specification.

The Credential format identifier is `mso_mdoc`.

### Presentation Request 

The presentation request looks the same as for the other examples since the difference is in the content of the `presentation_definition` parameter. 

<{{examples/request/request.txt}}

The content of the `presentation_definition` parameter is as follows:

<{{examples/request/pd_mdl_iso_cbor.json}}

To start with, the `format` parameter in the `input_descriptor` element is set to `mso_mdoc`, i.e. it requests presentation of an mDL in CBOR format. 

To request user claims in ISO/IEC 18013-5:2021 mDL, a `doctype` and `namespace` of the claim needs to be specified. Moreover, the Verifiers needs to indicate whether it intends to retain obtained user claims or not, using `intent_to_retain` property.

Note: `intent_to_retain` is a property introduced in this example to meet requirements of [@ISO.18013-5].

Setting `limit_disclosure` property defined in [@!DIF.PresentationExchange] to `required` enables selective release by instructing the Wallet to submit only the data parameters specified in the fields array. Selective release of claims is a requirement built into an ISO/IEC 18013-5:2021 mDL data model.

### Presentation Response

The presentation response looks the same as for the other examples.

<{{examples/response/response.txt}}

The following shows the `presentation_submission` content:

<{{examples/response/ps_mdl_iso_cbor.json}}

The `descriptor_map` refers to the `input_descriptor` element with an identifier `mDL` and tells the Verifier that there is an ISO/IEC 18013-5:2021 mDL (`format` is `mso_mdoc`) in CBOR encoding directly in the `vp_token` (path is the root designated by `$`). 

When ISO/IEC 18013-5:2021 mDL is expressed in CBOR the `path_nested` parameter cannot be used to point to the location of the requested claims. The user claims will always be included in the `issuerSigned` item. `path_nested` parameter can be used, however, when a JSON-encoded ISO/IEC 18013-5:2021 mDL is returned.

The following is a non-normative example of an ISO/IEC 18013-5:2021 mDL encoded as CBOR in diagnostic notation (line wraps within values are for display purposes only) as conveyed in the `vp_token` parameter.

<{{examples/response/mdl_iso_cbor.json}}

In the `deviceSigned` item, `deviceAuth` item includes a signature by the deviceKey that belongs to the End-User. It is used to prove legitimate possession of the credential, since the Issuer has signed over the deviceKey during the issuance of the credential. Note that deviceKey does not have to be HW-bound.

In the `issueSigned` item, `issuerAuth` item includes Issuer's signature over the hashes of the user claims, and `namespaces` items include user claims within each namespace that the End-User agreed to reveal to the Verifier in that transaction.

Note that user claims in the `deviceSigned` item correspond to self-attested claims inside a Self-Issued ID Token (none in the example below), and user claims in the `issuerSigned` item correspond to the user claims included in a VP Token signed by a trusted third party.

Note that the reason why hashes of the user claims are included in the `issuerAuth` item lies in the selective release mechanism. Selective release of the user claims in an ISO/IEC 18013-5:2021 mDL is performed by the Issuer signing over the hashes of all the user claims during the issuance, and only the actual values of the claims that the End-User has agreed to reveal to the Verifier being included during the presentation. 

The example in this section is also applicable to the electronic identification Verifiable Credentials expressed using data models defined in ISO/IEC TR 23220-2.

## Combining this specification with SIOPv2

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
* The request includes the `scope` parameter with value `openid` making this an OpenID Connect request. Additionally, the request also contains the parameter `id_token_type` with value `subject_signed` requesting a Self-Issuer ID Token, i.e. the request is a SIOP request. 

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

Note: the `nonce` and `aud` are set to the `nonce` of the request and the Client ID of the Verifier, respectively, in the same way as for the Verifier, Verifiable Presentations to prevent replay. 

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

Copyright (c) 2023 The OpenID Foundation.

The OpenID Foundation (OIDF) grants to any Contributor, developer, implementer, or other interested party a non-exclusive, royalty free, worldwide copyright license to reproduce, prepare derivative works from, distribute, perform and display, this Implementers Draft or Final Specification solely for the purposes of (i) developing specifications, and (ii) implementing Implementers Drafts and Final Specifications based on such documents, provided that attribution be made to the OIDF as the source of the material, but that such attribution does not indicate an endorsement by the OIDF.

The technology described in this specification was made available from contributions from various sources, including members of the OpenID Foundation and others. Although the OpenID Foundation has taken steps to help ensure that the technology is available for distribution, it takes no position regarding the validity or scope of any intellectual property or other rights that might be claimed to pertain to the implementation or use of the technology described in this specification or the extent to which any license under such rights might or might not be available; neither does it represent that it has made any independent effort to identify any such rights. The OpenID Foundation and the contributors to this specification make no (and hereby expressly disclaim any) warranties (express, implied, or otherwise), including implied warranties of merchantability, non-infringement, fitness for a particular purpose, or title, related to this specification, and the entire risk as to implementing this specification is assumed by the implementer. The OpenID Intellectual Property Rights policy requires contributors to offer a patent promise not to assert certain patent claims against other contributors and against implementers. The OpenID Foundation invites any interested party to bring to its attention any copyrights, patents, patent applications, or other proprietary rights that may cover technology that may be required to practice this specification.

# Document History

   [[ To be removed from the final specification ]]

   -16

   * Added `client_id_scheme` parameter
   * Defined that single VP Tokens must not use the array syntax for single Verifiable Presentations

   -15

   * Added definition of VP Token 
   * Editorial improvements for better readability (restructered request and response section, consistent terminology and casing)

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
