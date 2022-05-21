%%%
title = "OpenID for Verifiable Presentations"
abbrev = "openid-4-vp"
ipr = "none"
workgroup = "connect"
keyword = ["security", "openid", "ssi"]

[seriesInfo]
name = "Internet-Draft"
value = "openid-4-verifiable-presentations-1_0-11"
status = "standard"

[[author]]
initials="O."
surname="Terbu"
fullname="Oliver Terbu"
organization="walt.id"
    [author.address]
    email = "o.terbu@gmail.com"

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

This specification defines a mechanism on top of OAuth to allow presentation of claims in the form of verifiable credentials as part of the protocol flow. 

{mainmatter}

# Introduction

This specification defines a mechanism on top of OAuth [@!RFC6749] for presentation of claims via verifiable credentials, supporting W3C formats as well as other credential formats. This allows existing OpenID Connect RPs to extend their reach towards claims sources asserting claims in this format. It also allows new applications built using verifiable credentials to utilize OAuth or OpenID Connect as integration and interoperability layer towards credential holders.

OpenID Connect would be an obvious choice for this use case since it already allows Relying Parties to request identity assertions. However, early implementation experience suggests there are use cases where the presentation of verifiable presentations is sufficient and mandating [@OpenID.Core] features, such as issuance of ID tokens, would unnecessary increase implementation complexity. Thus the working group decided to use OAuth as a base protocol. Deployments can nevertheless add this specification to an OpenID Connect implementation, especially Self-Issued OpenID Providers (see [@SIOPv2]), since OpenID Connect is built on top of OAuth. 

# Terminology

Verifiable Credential (VC)

A verifiable credential is a tamper-evident credential that has authorship that can be cryptographically verified. Verifiable credentials can be used to build verifiable presentations, which can also be cryptographically verified. The claims in a credential can be about different subjects. (see [@VC_DATA])
Note that this specification uses a term "credential" as defined in Section 2 of [@VC_DATA], which is a different definition than in [@!OpenID.Core].

Presentation

Data derived from one or more verifiable credentials, issued by one or more issuers, that is shared with a specific verifier. (see [@VC_DATA])

Verifiable Presentation (VP)

A verifiable presentation is a tamper-evident presentation encoded in such a way that authorship of the data can be trusted after a process of cryptographic verification. Certain types of verifiable presentations might contain data that is synthesized from, but do not contain, the original verifiable credentials (for example, zero-knowledge proofs). (see [@VC_DATA])

# Use Cases

## Verifier accesses Wallet via OpenID Connect

A Verifier uses OpenID Connect to obtain verifiable presentations. This is a simple and mature way to obtain identity data. From a technical perspective, this also makes integration with OAuth-protected APIs easier as OpenID Connect is based on OAuth.  

## Existing OpenID Connect RP integrates SSI wallets

An application currently utilizing OpenID Connect for accessing various federated identity providers can use the same protocol to also integrate with emerging SSI-based wallets. This is a convenient transition path leveraging existing expertise to protect investments made.

## Existing OpenID Connect OP as custodian of End-User Credentials

An existing OpenID Connect may extend its service by maintaining credentials issued by other claims sources on behalf of its customers. Customers can mix claims of the OP and from their credentials to fulfil authentication requests. 

## Federated OpenID Connect OP adds device-local mode

An existing OpenID Connect OP with a native user experience (PWA or native app) issues verifiable credentials and stores them on the user's device linked to a private key residing on this device under the user's control. For every authentication request, the native user experience first checks whether this request can be fulfilled using the locally stored credentials. If so, it generates a presentation signed with the user's keys in order to prevent replay of the credential. 

This approach dramatically reduces latency and reduces load on the OP's servers. Moreover, the user identification, authentication, and authorization can be done even in situations with unstable or no internet connectivity. 

# Overview 

This specification defines a mechanism on top of OAuth to request and provide verifiable presentations. Since OpenID Connect is based on OAuth, implementations can also be build on top of OpenID Connect, e.g. Self-Issued OP v2 [@SIOPv2].

The specification supports all kinds of verifiable credentials, such as W3C Verifiable Credentials but also ISO mDL or AnonCreds. The examples given in the main part of the specification use W3C Verifiable Credentials, examples in other credential formats are given in  (#alternative_credential_formats). 

Verifiable Presentations are requested by adding a parameter `presentation_definition` or a scope value `openid_presentation:<credential_type>` to an OAuth authorization request.
This specification introduces a new token type, "VP Token", used as a generic container for verifiable presentation objects, that is returned in authorization and token responses.  

# Request {#vp_token_request}

The parameters comprising a request for verifiable presentations are given in the following: 

* `response_type`: REQUIRED. this parameter is defined in [@!RFC6749]. The possible values are determined by the response type registry established by [@!RFC6749]. This specification introduces the response type "vp_token". This response type asks the Authorization Server to only return a VP Token in the authorization response. 
* `scope`: OPTIONAL. this parameter is defined in [@!RFC6749]. For the purpose of requesting a verifiable presentation, the client adds a scope value of the form `openid_presentation:<credential_type>`, e.g. `openid_presentation:healthcard`. See (#request_scope) for more details. This mechanism is supported for ease of use in cases, where the verifier only wants to specific the credential type. If the use case requires more details, e.g. a list of the claims to be disclosed, one of the other options MUST be used.
* `presentation_definition`: OPTIONAL. A string containing a `presentation_definition` JSON object as defined in Section 4 of [@!DIF.PresentationExchange]. See (#request_presentation_definition) for more details.
* `presentation_definition_uri`: OPTIONAL. A string containing a URL pointing to a resource where a `presentation_definition` JSON object as defined in Section 4 of [@!DIF.PresentationExchange] can be retrieved . See (#request_presentation_definition_uri) for more details.
* `nonce`: REQUIRED. This parameter follows the definition given in [@!OpenID.Core]. It is used to securely bind the verifiable presentation(s) provided by the authorization server to the particular transaction.

Note: An request MAY contain `scope`, `presentation_definition`, and `presentation_definition_uri`. The authorization server MUST merge the requirements passed by this different parameters. If the same credential type is requested by `scope` and one of the other parameters, they are treated separately since they belong to different (explicitely or implicitely determined) input descriptors. 

TBD: this will result in multple presentation_defintion, which requires multiple presentation_submissions. That will be hard to be mapped since either we have multiple presentation submissions response parameters (all referring to the same vp_token) or a single presentation submussion parameter may contain an array of presentation submissions. It might be better to make the parameters mutual exclusive. 

## presentation_definition {#request_presentation_definition}

This parameter contains a JSON object conforming to the syntax defined for `presentation_definition` elements in Section 4 of [@!DIF.PresentationExchange].

Please note this draft defines a profile of [@!DIF.PresentationExchange] as follows: 

* The `format` element in the `presentation_definition` that represents supported presentation formats, proof types, and algorithms is not supported. Those are determined using new RP and OP metadata (see (#metadata)). 

The following shows an example `presentation_definition` parameter:

<{{examples/request/vp_token_type_only.json}}

This simple example requests the presentation of a credential of a certain type. 

The following example shows how the RP can request selective disclosure or certain claims from a credential of a particular type.

<{{examples/request/vp_token_type_and_claims.json}}

RPs can also ask for alternative credentials being presented, which is shown in the next example:

<{{examples/request/vp_token_alternative_credentials.json}}

## presentation_definition\_uri {#request_presentation_definition_uri}

`presentation_definition_uri` is used to the retrieve the `presentation_definition` from the resource at the specified URL, rather than being passed by value. The authorization server will send a GET request without additional parameters. The resource MUST be exposed without further need to authenticate or authorize. 

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

## openid_presentation scope values {#request_scope}

A verifiable presentation can be requested by adding a scope value of the form `openid_presentation:<credential_type>` to the `scope` request parameter. Such a scope value is a default presentation request, i.e. it is resolved by the authorization server to a presentation definition and input descriptor of the following form:

```JSON
{
    "id": "scope_<credential_type>",
    "input_descriptors": [
        {
            "id": "scope_<credential_type>"
            },
            "constraints": {
                "fields": [
                    {
                        "path": [
                            "$.type"
                        ],
                        "filter": {
                            "type": "string",
                            "pattern": "<credential_type>"
                        }
                    }
                ]
            }
        }
    ]
}
```

Here is an example for the scope value `openid_presentation:IDCardCredential`:

<{{examples/request/vp_token_from_scope.json}}

Note: the credential type is used "as is" without any lower or upper casing. 

TBD: credential type selection is format specific. This transformation function thus is format specific -> make it a credential_format/AS defined default published in metadata?

## VP Token Response {#vp_token_response}

The response used to provide the `vp_token` to the client depends on the grant and response type used in the request.

If the `response_type` `vp_token` is used, the `vp_token` is provided in the authorization response. 
If the `response_type` `id_token` is used, the `vp_token` is provided in the OpenID Connect authentication response along with the `id_token`. 
In all other cases, the `vp_token` is provided on the token response. 

The `vp_token` either contains a single verifiable presentation or an array of verifiable presentations. 

Each of those verifiable presentations MAY contain a `presentation_submission` element as defined in [@!DIF.PresentationExchange]. This `presentation_submission` element links the input descriptor identifiers as specified in the corresponding request to the respective verifiable presentations within the `vp_token` along with format information. The root of the path expressions in the descriptor map is the respective verifiable presentation, pointing to the respective verifiable credentials.

This is shown in the following example:

<{{examples/response/vp_token_ldp_vp_with_ps.json}}

The OP MAY also add a `presentation_submission` response parameter along with the `vp_token` response parameter, which contains a JSON object conforming to the `presentation_submission` element as defined in [@!DIF.PresentationExchange]. This `presentation_submission` element links the input descriptor identifiers as specified in the corresponding request to the respective verifiable presentations within the `vp_token` along with format information. The root of the path expressions in the descriptor map is the respective `vp_token`. 

This element might, for example, be used if the particular format of the provided presentations does not allow for the direct inclusion of `presentation_submission` elements or if the AS wants to provide the RP with additional information about the format and structure in advance of the processing of the `vp_token`.

In case the AS returns a single verifiable presentation in the `vp_token`, the descriptor map would then contain a simple path expression "$".

This is an example of a `vp_token` containing a single verifiable presentation

<{{examples/response/vp_token_raw_ldp_vp.json}}

with a matching `presentation_submission`.

<{{examples/response/presentation_submission.json}}

A `descriptor_map` element MAY also contain a `path_nested` element referring to the actual credential carried in the respective verifiable presentation. 

This is an example of a `vp_token` containing multiple verifiable presentations,   

<{{examples/response/vp_token_multiple_vps.json}}

with a matching `presentation_submission` parameter.

<{{examples/response/presentation_submission_multiple_vps.json}}

# Metadata {#metadata}

This specification introduces additional metadata to enable RP and OP to determine the verifiable presentation and verifiable credential formats, proof types and algorithms to be used in a protocol exchange. 

## RP Metadata

This specification defines new client metadata parameters according to [@!OpenID.Registration].

### VP Formats

RPs indicate the supported VP formats using the new parameter `vp_formats`.

* `vp_formats`: REQUIRED. An object defining the formats, proof types and algorithms of verifiable presentations and verifiable credentials that a RP supports. Valid values include `jwt_vp`, `ldp_vp`, `jwt_vc` and `ldp_vc`. Other formats may be supported. 

The `format` property inside a `presentation_definition` object as defined in [@!DIF.PresentationExchange] MAY be used to specify the concrete format in which the RP is requesting verifiable presentations to be presented. The OP MUST ignore the `format` property inside a `presentation_definition` object if that `format` was not included in the `vp_formats` property of the client metadata.

Note that version 2.0.0 of [@!DIF.PresentationExchange] allows the RP to specify the format of each requested credential using the `formats` property inside the `input_descriptor` object, in addition to communicating the supported presentation formats using the `vp_formats` parameter in the RP metadata.

Here is an example for an RP registering with a Standard OP via dynamic client registration:

<{{examples/client_metadata/client_code_format.json}}

Here is an example for an RP registering with a SIOP (see [@SIOPv2]) with the `registration` request parameter:

<{{examples/client_metadata/client_siop_format.json}}

### Presentation Definition Transfer

RPs indicate their support for transferring presentation definitions by value and/or by reference, by using the following parameters:

* `presentation_definition_uri`: OPTIONAL. Boolean value specifying whether the RP supports the transfer of `presentation_definition` by reference, with true indicating support. If omitted, the default value is true. 

## RP Metadata Error Response

Error response MUST be made in the same manner as defined in [@!OpenID.Core].

## RP Metadata Error Response Codes

This extension defines the following error codes that MUST be returned when the OP does not support client metadata parameters:

* `vp_formats_not_supported`: The OP does not support any of the VP formats supported by the RP such as those included in the `vp_formats` registration parameter.

## OP Metadata

This specification defines new server metadata parameters according to [@!OpenID-Discovery].

The OP publishes the formats it supports using the `vp_formats_supported` metadata parameter as defined above in its "openid-configuration". 

# Implementation Considerations

## Support for Federations/Trust Schemes

Often RPs will want to request verifiable credentials from an issuer who is a member of a federation or trust scheme, rather than from a specific issuer, for example, a "BSc Chemistry Degree" credential from a US University rather than from a specifically named university.

In order to facilitate this, federations will need to determine how an issuer can indicate in a verifiable credential that they are a member of one or more federations/trust schemes. Once this is done, the RP will be able to create a `presentation_definition` that includes this filtering criteria. This will enable the wallet to select all the verifiable credentials that match this criteria and then by some means (for example, by asking the user) determine which matching verifiable credential to return to the RP. Upon receiving this verifiable credential, the RP will be able to call its federation API to determine if the issuer is indeed a member of the federation/trust scheme that it says it is.

Indicating the federations/trust schemes that an issuer is a member of may be achieved by defining a `termsOfUse` property [@!VC_DATA].

Note. [@!VC_DATA] describes terms of use as "can be utilized by an issuer ... to communicate the terms under which a verifiable credential ... was issued."

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


# Security Considerations {#security_considerations}

## Preventing Replay Attacks {#preventing-replay}

To prevent replay attacks, verifiable presentation container objects MUST be linked to `client_id` and `nonce` from the Authentication Request. The `client_id` is used to detect presentation of credentials to a different party other than the intended. The `nonce` value binds the presentation to a certain authentication transaction and allows the verifier to detect injection of a presentation in the OpenID Connect flow, which is especially important in flows where the presentation is passed through the front-channel. 

Note: These values MAY be represented in different ways in a verifiable presentation (directly as claims or indirectly be incorporation in proof calculation) according to the selected proof format denoted by the format claim in the verifiable presentation container.

Note: This specification assumes that a verifiable credential is always presented with a cryptographic proof of possession which can be a Verifiable presentation. This cryptographic proof of possession is bound to audience and transaction as described in this section.

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

In the example above, the requested `nonce` value is included as the `nonce` and `client_id` as the `aud` value in the proof of the verifiable presentation.

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

In the example above, the requested `nonce` value is included as the `challenge` and `client_id` as the `domain` value in the proof of the verifiable presentation.

## Validation of Verifiable Presentations

A verifier MUST validate the integrity, authenticity, and holder binding of any verifiable presentation provided by an OP according to the rules of the respective presentation format. 

This requirement holds true even if those verifiable presentations are embedded within a signed OpenID Connect assertion, such as an ID Token or a UserInfo response. This is required because verifiable presentations might be signed by the same holder but with different key material and/or the OpenID Connect assertions may be signed by a third party (e.g., a traditional OP). In both cases, just checking the signature of the respective OpenID Connect assertion does not, for example, check the holder binding.

Note: Some of the available mechanisms are outlined in Section 4.3.2 of [@!DIF.PresentationExchange].

It is NOT RECOMMENDED for the Subject to delegate the presentation of the credential to a third party.

## Fetching Presentation Definitions by Reference

The protocol for the `presentation_definition_uri` MUST be https.

In many instances the referenced server will be operated by a known federation or other trusted operator, and the URL's domain name will already be widely known. OPs (including SIOPs) using this URI can mitigate request forgeries by having a pre-configured set of trusted domain names and only fetching presentation_definitions from these sources. In addition, the presentation definitions could be signed by a trusted authority, such as the ICO or federation operator.

## User Authentication using Verifiable Credentials

Clients intending to authenticate the end-user utilizing a claim in a verifable credential MUST ensure this claim is stable for the end-user as well locally unique and never reassigned within the credential issuer to another end-user. Such a claim MUST also only be used in combination with the issuer identifier to ensure global uniqueness and to prevent attacks where an attacker obtains the same claim from a different issuer and tries to impersonate the legitimate user. 

#  Examples 

This Section illustrates examples when W3C Verifiable Credentials objects are requested using the `claims` parameter and returned in a VP Token.

## Self-Issued OpenID Provider (SIOP)
This Section illustrates the protocol flow for the case of communication through the front-channel with SIOP.

### Authentication request

The following is a non-normative example of how an RP would use the `claims` parameter to request claims in the `vp_token`:

```
  HTTP/1.1 302 Found
  Location: openid://?
    response_type=id_token
    &client_id=https%3A%2F%2Fclient.example.org%2Fcb
    &redirect_uri=https%3A%2F%2Fclient.example.org%2Fcb
    &scope=openid
    &claims=...
    &state=af0ifjsldkj
    &nonce=n-0S6_WzA2Mj
    &registration_uri=https%3A%2F%2F
      client.example.org%2Frf.txt%22%7D
      
```

#### claims parameter

<{{examples/request/vp_token_type_and_claims.json}}

### Authentication Response (including vp_token)

The successful authentication response contains a `vp_token` parameter along with  `id_token` and `state`.
```
  HTTP/1.1 302 Found
  Location: https://client.example.org/cb#
    id_token=eyJ0 ... NiJ9.eyJ1c ... I6IjIifX0.DeWt4Qu ... ZXso
    &vp_token=...
    &state=af0ifjsldkj
      
```

#### id_token

This is the example ID Token:

```json
{
   "iss":"https://self-issued.me/v2",
   "aud":"https://client.example.org/cb",
   "iat":1615910538,
   "exp":1615911138,
   "sub":"NzbLsXh8uDCcd-6MNwXF4W_7noWXFZAfHkxZsRGC9Xs",
   "auth_time":1615910535,
   "nonce":"n-0S6_WzA2Mj",
   "sub_jwk": {
     "kty":"RSA",
     "n": "0vx7agoebGcQSuuPiLJXZptN9nndrQmbXEps2aiAFbWhM78LhWx
     4cbbfAAtVT86zwu1RK7aPFFxuhDR1L6tSoc_BJECPebWKRXjBZCiFV4n3oknjhMs
     tn64tZ_2W-5JsGY4Hc5n9yBXArwl93lqt7_RN5w6Cf0h4QyQ5v-65YGjQR0_FDW2
     QvzqY368QQMicAtaSqzs8KJZgnYb9c7d0zgdAZHzu6qMQvRL5hajrn1n91CbOpbI
     SD08qNLyrdkt-bFTWhAI4vMQFh6WeZu0fM4lFd2NcRwr3XPksINHaQ-G_xBniIqb
     w0Ls1jF44-csFCur-kEgU8awapJzKnqDKgw",
     "e":"AQAB"
    }
    "_vp_token": {
        "presentation_submission": {
            "id": "Selective disclosure example presentation",
            "definition_id": "Selective disclosure example",
            "descriptor_map": [
                {
                    "id": "ID Card with constraints",
                    "format": "ldp_vp",
                    "path": "$",
                    "path_nested": {
                        "format": "ldp_vc",
                        "path": "$.verifiableCredential[0]"
                    }
                }
            ]
        }
    }
}
```

#### vp_token content

This is the example `vp_token` containing a verifiable presentation (and credential) in LD Proof format. 

Note: in accordance with (#security_considerations) the verifiable presentation's `challenge` claim is set to the value of the `nonce` request parameter value and the `domain` claim contains the RP's `client_id`. 

<{{examples/response/vp_token_ldp_vp.json}}

## Authorization Code Flow with vp_token

This Section illustrates the protocol flow for the case of communication using front-channel and backchannel (utilizing the authorization code flow).

### Authentication Request

```
  GET /authorize?
    response_type=code
    &client_id=s6BhdRkqt3 
    &redirect_uri=https%3A%2F%2Fclient.example.org%2Fcb
    &scope=openid
    &claims=...
    &state=af0ifjsldkj
    &nonce=n-0S6_WzA2Mj HTTP/1.1
  Host: server.example.com
```

#### Claims parameter

<{{examples/request/vp_token_type_and_claims.json}}

### Authentication Response
```
HTTP/1.1 302 Found
  Location: https://client.example.org/cb?
    code=SplxlOBeZQQYbYS6WxSbIA
    &state=af0ifjsldkj
```

### Token Request
```
  POST /token HTTP/1.1
  Host: server.example.com
  Content-Type: application/x-www-form-urlencoded
  Authorization: Basic czZCaGRSa3F0MzpnWDFmQmF0M2JW

  grant_type=authorization_code
  &code=SplxlOBeZQQYbYS6WxSbIA
  &redirect_uri=https%3A%2F%2Fclient.example.org%2Fcb
```

### Token Response (including vp_token)

This is the example token response containing a `vp_token` which contains a verifiable presentation (and credential) in LD Proof format. 

Note: in accordance with (#security_considerations) the verifiable presentation's `challenge` claim is set to the value of the `nonce` request parameter value and the `domain` claim contains the RP's `client_id`. 

<{{examples/response/token_response_vp_token_ldp_vp.json}}

#### id_token

<{{examples/response/id_token_ref_vp_token_code.json}}

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

<reference anchor="TRAIN" target="https://oid2022.compute.dtu.dk/index.html">
        <front>
          <title>A novel approach to establish trust in verifiable credential
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

<reference anchor="ISO.18013-5" target="https://www.iso.org/standard/69084.html">
        <front>
          <title>ISO/IEC 18013-5:2021 Personal identification — ISO-compliant driving licence — Part 5: Mobile driving licence (mDL)  application</title>
          <author>
            <organization> ISO/IEC JTC 1/SC 17 Cards and security devices for personal identification</organization>
          </author>
          <date year="2021"/>
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

# Alternative Credential Formats {#alternative_credential_formats}

OpenID for Verifiable Presentations is credential format agnostic, i.e. it is designed to allow applications to request and receive verifiable presentations and credentials in any format, not limited to the formats defined in [@!VC_DATA]. This section aims to illustrate this with examples utilizing other credential formats. Customization of OpenID for Verifiable Presentation for other credential formats uses extensions points of Presentation Exchange [@!DIF.PresentationExchange]. 

## AnonCreds

AnonCreds is a credential format defined as part of the Hyperledger Indy project [@Hyperledger.Indy].

To be able to request AnonCreds, there needs to be a set of identifiers for credentials, presentations ("proofs" in Indy terminology) and crypto schemes. For the purpose of this example, the following identifiers are used: 

* `ac_vc`: designates a credential in AnonCreds format. 
* `ac_vp`: designates a presentation in AnonCreds format.
* `CLSignature2019`: identifies the CL-signature scheme used in conjunction with AnonCreds.

### Example Credential

The following is an example AnonCred credential that will be used through this section. 

```json
{
    "schema_id": "3QowxFtwciWceMFr7WbwnM:2:BasicScheme:0.1",
    "cred_def_id": "CsiDLAiFkQb9N4NDJKUagd:3:CL:4687:awesome_cred",
    "rev_reg_id": null,
    "values": {
        "first_name": {
            "raw": "Alice",
            "encoded": "6874ecdbdb214ee888e37c8c983e2f1c9c0ed16907b519704db42bb6"
        },
        "last_name": {
            "raw": "Wonderland",
            "encoded": "f5e16db78511f23bf2bcf0f450f20180951557cd75efe88b276988fd"
        },
        "email": {
            "raw": "alice@example.com",
            "encoded": "0fbaa7f92a47fe3c5201e97f063983c702432e90dd7bf0c723386543"
        }
    },
    "signature": {
        "p_credential": {
            "m_2": "99219524012997799443220800218760023447537107640621419137185629243278403921312",
            "a": "54855652574677988116650236306088516361537734570414909367032672219103444197205489674846545082012012711261249754371310495367475614729209653850720034913398482184757254920537051297936910125023613323255317515823974231493572903991640659741108603715378490408836507643191051986137793268856316333600932915078337920001692235029278931184173692694366223663131943657834349339828618978436402973046999961539444380116581314372906598415014528562207334745774098097000567515212222894771357044500544552372314335894883000614144994856702181141090905033428221403654636324918343808136750040908443212492359485782471636294013062295153997068252",
            "e": "259344723055062059907025491480697571938277889515152306249728583105665800713306759149981690559193987143012367913206299323899696942213235956742930239825562861075148170278284639129199",
            "v": "9774232256179658261610308745866736090602538333363396375105120427156273261155207775732400073422905045147609169788952804683922921383859274758479842100138659865591976937215264032734277416744113491766616076612368115891637834588143840477778776159325514034900968730327459279564615858068472282705529798808334108833124505594371791348317639533993310391511620579199112357959170076753792711700533312522910797352842323445933004238048599164039686432144165884599052061538014126710866075791210006585893465085621395503182710866197817129408546193805893321161372355187962990595781339533851533077334790530438016817333603675910702146635975282253747819810788129751055728368937483121363992748831475139233180853145906108476753713239644943541916540123456371366974874702598201796929261151925643543132170495933035112012082080893049915977209167597"
        },
        "r_credential": null
    },
    "signature_correctness_proof": {
        "se": "8986500246928105545119249693120482606913996376875337975817228090569777886100120575851444392132175485176800946276729875298747664099989412623249056022784348808658577491758644556594901203598819936532435225959211617545841036816799892165118015169512229910557670483101499028188851318984001732266955939801843049852569586066803442690248386970226324039561954050567607010646624132392374280640663854092050106203821468403658338788408023014151088931308776669398184180228869449717267624484235796469721889284094131533549692106113602342932288350356591343546227828642494647872633442330361211149649432468143339518371824496555067302935",
        "c": "93582993140981799598406702841334282100000866001274710165299804498679784215598"
    },
    "rev_reg": null,
    "witness": null
}
```

The most important parts for the purpose of this example are `scheme_id` element and `values` element that contains the actual End-user claims. 

### Presentation Request 

#### Request Example without Selective Release of Claims

The following is an example request for a presentation of a credential in AnonCreds format.

```json
{
    "id_token": {
        "email": null
    },
    "vp_token": {
        "presentation_definition": {
            "id": "vp token example",
            "input_descriptors": [
                {
                    "id": "id card credential",
                    "format": {
                        "ac_vc": {
                            "proof_type": [
                                "CLSignature2019"
                            ]
                        }
                    },
                    "constraints": {
                        "fields": [
                            {
                                "path": [
                                    "$.schema_id"
                                ],
                                "filter": {
                                    "type": "string",
                                    "pattern": "did:indy:idu:test:3QowxFtwciWceMFr7WbwnM:2:BasicScheme:0\\.1"             
                                }
                            }
                        ]
                    }
                }
            ]
        }
    }
}
```

The following explanation will focus on the elements in the `input_descriptor` object in the `claims` parameter.

The `format` object uses the format identifier `ac_vc` as defined above and sets the `proof_type` to `CLSignature2019` to denote this descriptor requires a credential in AnonCreds format signed with a CL signature (Camenisch-Lysyanskaya siganture). The rest of the expressions operate on the AnonCreds JSON structure.

The `constraints` object requires the selected credential to conform with a certain schema, which is denoted as a constraint over the AnonCred's `schema_id` element. 

#### Request Example with Selective Release of Claims

The next example leverages the AnonCreds' capabilities for selective disclosure by requesting a subset of the claims in the credential to be disclosed to the verifier.

```json
{
    "id_token": {
        "email": null
    },
    "vp_token": {
        "presentation_definition": {
            "id": "vp token example",
            "input_descriptors": [
                {
                    "id": "ref2",
                    "format": {
                        "ac_vc": {
                            "proof_type": [
                                "CLSignature2019"
                            ]
                        }
                    },
                    "constraints": {
                        "limit_disclosure": "required",
                        "fields": [
                            {
                                "path": [
                                    "$.schema_id"
                                ],
                                "filter": {
                                    "type": "string",
                                    "pattern": "did:indy:idu:test:3QowxFtwciWceMFr7WbwnM:2:BasicScheme:0\\.1"
                                }
                            },
                            {
                                "path": [
                                    "$.values.given_name"
                                ]
                            },
                            {
                                "path": [
                                    "$.values.family_name"
                                ]
                            }
                        ]
                    }
                }
            ]
        }
    }
}
```

This example is identic to the previous one with the following exceptions. It sets the PE elememt `limit_disclosure` to `require` and adds two more constraints for the individual claims `given_name` and `family_name`. Since such claims are stored underneath a `values` container in an AnonCred, `values` is part of the path to identify the respective claim. 

### Presentation Response

The response contains an ID Token and a VP tokens. 

The following is an ID Token example. It shows how the `presentation submission` helps the Verifier to locate proof of AnonCred credential in the VP token.

```json
{
  "aud": "https://example.com/callback",
  "sub": "9wgU5CR6PdgGmvBfgz_CqAtBxJ33ckMEwvij-gC6Bcw",
  "auth_time": 1638483344,
  "iss": "https://self-issued.me/v2",
  "sub_jwk": {
    "x": "cQ5fu5VmG…dA_5lTMGcoyQE78RrqQ6",
    "kty": "EC",
    "y": "XHpi27YMA…rnF_-f_ASULPTmUmTS",
    "crv": "P-384"
  },
  "exp": 1638483944,
  "iat": 1638483344,
  "nonce": "67473895393019470130",
  "_vp_token": {
    "presentation_submission": {
      "descriptor_map": [
        {
          "id": "ref2",
          "path": "$",
          "format": "ac_vp",
          "path_nested": {
            "path": "$.requested_proof.revealed_attr_groups.ref2",
            "format": "ac_vc"
          }
        }
      ],
      "definition_id": "NextcloudLogin",
      "id": "NexcloudCredentialPresentationSubmission"
    }
  }
}
```

The `descriptor_map` refers to the input descriptor `ref2` and tells the verifier that there is a proof of AnonCred credential (`format` is `ac_vp`) directly in the vp_token (path is the root designated by `$`). Furthermore it indicates using `nested_path` parameter that the user claims can be found embedded in the proof underneath `requested_proof.revealed_attr_groups.ref2`.

The following is a VP Token example.

```json
{
   "proof": {...},
   "requested_proof": {
       "revealed_attrs": {},
       "revealed_attr_groups": {
           "ref2": {
               "sub_proof_index": 0,
               "values": {
                   "last_name": {
                       "raw": "Wonderland",
                       "encoded": "167908493…94017654562035"
                   },
                   "first_name": {
                       "raw": "Alice",
                       "encoded": "270346400…99344178781507"
                   }
               }
           }
       },
       …
   },
   "identifiers": [
       {
           "schema_id": "3QowxFtwciWceMFr7WbwnM:2:BasicScheme:0.1",
           "cred_def_id": "CsiDLAiFkQb9N4NDJKUagd:3:CL:4687:awesome_cred",
           "rev_reg_id": null,
           "timestamp": null
       }
   ]
}
```

## ISO mobile Driving Licence (mDL)

This section illustrates how a mobile driving licence (mDL) credential expressed using a data model and data sets defined in ISO/IEC 18013-5:2021 specification [@ISO.18013-5] can be presented from the End-User's device directly to the RP using [@SIOPv2] and this specification.

To request an ISO/IEC 18013-5:2021 mDL, following identifiers for credentials are used for the purposes of this example:

* `mdl_iso_cbor`: designates a mobile driving licence (mDL) credential encoded as CBOR, expressed using a data model and data sets defined in ISO/IEC 18013-5:2021 specification [@ISO.18013-5].
* `mdl_iso_json`: designates a mobile driving licence (mDL) credential encoded as JSON, expressed using a data model and data sets defined in ISO/IEC 18013-5:2021 specification [@ISO.18013-5].

### Presentation Request 

#### Request Example

Below is a non-normative example of how `claims` parameter is used in the authorization request to request an mDL credential in ISO/IEC 18013-5:2021 format:

```json
"claims": {
  "vp_token": {
    "presentation_definition": {
      "id": "mDL-sample-req",
      "input_descriptors": [
        {
          "id": "mDL",
          "format": {
            "mdl_iso_cbor": {
              "alg": ["EdDSA", "ES256"]
            },
          "constraints": {
            "limit_disclosure": "required",
            "fields": [
              {
                "path": ["$.mdoc.doctype"],
                "filter": {
                  "type": "string",
                  "const": "org.iso.18013.5.1.mDL"
                }             
              },
              {
                "path": ["$.mdoc.namespace"],
                "filter": {
                  "type": "string",
                  "const": "org.iso.18013.5.1"
                }             
              },
              {
                "path": ["$.mdoc.family_name"],
                "intent_to_retain": "false"
              },
              {
                "path": ["$.mdoc.portrait"],
                "intent_to_retain": "false"
              },
              {
                "path": ["$.mdoc.driving_privileges"],
                "intent_to_retain": "false"
              }
            ]       
           }         
         }
        } 
      ]
    } 
   }
 }
```

To request user claims in ISO/IEC 18013-5:2021 mDL, a `doctype` and `namespace` of the claim needs to be specified.
Moreover, RP needs to indicate whether it intends to retain obtained user claims or not, using `intent_to_retain` property.

Setting `limit_disclosure` property defined in [@!DIF.PresentationExchange] to `required` enables selective release by instructing SIOP to submit only the data elements specified in the fields array.

Selective release of claims is a requirement built into an ISO/IEC 18013-5:2021 mDL data model.

If an RP wants to request user claims from another namespace, another `input_descriptor` object should be used, even if the namespaces belong to the same doctype.

Note that `intent_to_retain` is a property introduced to [@!DIF.PresentationExchange] to meet requirements of [@ISO.18013-5].


### Presentation Response

The response contains an ID Token and a VP Token. In the following example, a single ISO/IEC 18013-5:2021 mDL is returned as a VP Token. Note that a ISO/IEC 18013-5:2021 mDL could be encoded both in CBOR or JSON. 

The following is a non-normative example of a successful authorization request when [@SIOPv2] and this specification is used.

```
POST /callback HTTP/1.1
Host: client.example.org
Content-Type: application/x-www-form-urlencoded

id_token=<<Base64URL encoded ID Token>>
  &vp_token=<<Base64URL encoded ISO/IEC 18013-5:2021 mDL (CBOR in this example since the requested format was `mdl_iso`)>>
```

The following is an ID Token example. It shows how the `presentation_submission` helps the RP to locate in the VP Token an ISO/IEC 18013-5:2021 mDL expressed in CBOR:

```json
{
  "aud": "https://client.example.org/callback",
  "sub": "9wgU5CR6PdgGmvBfgz_CqAtBxJ33ckMEwvij-gC6Bcw",
  "iss": "9wgU5CR6PdgGmvBfgz_CqAtBxJ33ckMEwvij-gC6Bcw",
  "sub_jwk": {
    "x": "cQ5fu5VmG…dA_5lTMGcoyQE78RrqQ6",
    "kty": "EC",
    "y": "XHpi27YMA…rnF_-f_ASULPTmUmTS",
    "crv": "P-384"
  },
  "exp": 1638483944,
  "iat": 1638483344,
  "nonce": "67473895393019470130",
  "_vp_token": {
    "presentation_submission": {
      "descriptor_map": [
        {
          "id": "mDL",
          "path": "$",
          "format": "mdl_iso"
        }
      ],
      "definition_id": "mDL-sample-req",
      "id": "mDL-sample-res"
    }
  }
}
```

The `descriptor_map` refers to the input descriptor `mDL` and tells the verifier that there is an ISO/IEC 18013-5:2021 mDL (`format` is `mdl_iso`) directly in the vp_token (path is the root designated by `$`). 

When ISO/IEC 18013-5:2021 mDL is expressed in CBOR `nested_path` parameter cannot be used to point to the location of the requested claims. The user claims will be included in the `issuerSigned` item. `nested_path` parameter is useful when a JSON-encoded ISO/IEC 18013-5:2021 mDL is returned.

The following is a non-normative example of an ISO/IEC 18013-5:2021 mDL encoded as CBOR in diagnostic notation (line wraps within values are for display purposes only).

```json
{
    "status": 0,
    "version": "1.0",
    "documents": [
        {
            "docType": "org.iso.18013.5.1.mDL",
            "deviceSigned": {
                "deviceAuth": {
                    "deviceMac": [
                        << {1: 5} >>,
                        {},
                        null, h'A574C64F18902BFE18B742F17C581218F88EA279AA96D0F5888123843461A3B6'
                    ]
                },
                "nameSpaces": 24(h'A0')
            },
            "issuerSigned": {
                "issuerAuth": [
                  << {1: -7} >>,
                    {
                        33: h'30820215308201BCA003020102021404AD06A30C1A6DC6E93BE0E2E8F78DCAFA7907C2300A06082A8648CE3D040302305B310B3009060355040613025A45312E302C060355040A0C25465053204D6F62696C69747920616E64205472616E73706F7274206F66205A65746F706961311C301A06035504030C1349414341205A65746573436F6E666964656E73301E170D3231303932393033333034355A170D3232313130333033333034345A3050311A301806035504030C114453205A65746573436F6E666964656E7331253023060355040A0C1C5A65746F70696120436974792044657074206F662054726166666963310B3009060355040613025A453059301306072A8648CE3D020106082A8648CE3D030107034200047C5545E9A0B15F4FF3CE5015121E8AD3257C28D541C1CD0D604FC9D1E352CCC38ADEF5F7902D44B7A6FC1F99F06EEDF7B0018FD9DA716AEC2F1FFAC173356C7DA3693067301F0603551D23041830168014BBA2A53201700D3C97542EF42889556D15B7AC4630150603551D250101FF040B3009060728818C5D050102301D0603551D0E04160414CE5FD758A8E88563E625CF056BFE9F692F4296FD300E0603551D0F0101FF040403020780300A06082A8648CE3D0403020347003044022012B06A3813FFEC5679F3B8CDDB51EAA4B95B0CBB1786B09405E2000E9C46618C02202C1F778AD252285ED05D9B55469F1CB78D773671F30FE7AB815371942328317C'
                    }, 
                    <<
                      24(<<
                          {
                            "docType": "org.iso.18013.5.1.mDL",
                            "version": "1.0",
                            "validityInfo": {
                                "signed": 0("2022-04-15T06:23:56Z"),
                                "validFrom": 0("2022-04-15T06:23:56Z"),
                                "validUntil": 0("2027-01-02T00:00:00Z")
                            },
                            "valueDigests": {
                                "org.iso.18013.5.1": {
                                    1: h'0F1571A97FFB799CC8FCDF2BA4FC29099290AAD37AE37ACE3C3BAE85C6379AD5',
                                    2: h'0CDFE077400432C055A2B69596C90AAA47277C9678BFFC32BBC7F0CF82713B8E',
                                    3: h'E2382149255AE8E955AF9B8984395315F3A38427C267F910A637D3FC81F25BB4',
                                    4: h'BBC77E6CCA981A3AD0C3E544EDF8B68F19F4DACF1AF2AA0E6436401B4539ABA2',
                                    6: h'BB6E6C68D1B4B4EC5A2AE9206F5F976A32061FA878BD5B44476F96D35462F6B2',
                                    8: h'F8A5966E6DAC9970E0334D8F75E24DC63832E73A56AEF21C0D4B91487FC6AB03',
                                    9: h'EAD5E8B5E543BD31F3BE57DE4ED6CCF7BB635221725F80538165DA7DC0BF92BB',
                                    11: h'38CE9A09DC0121E1A9C2EF3EE2456530C2183AA8326FBE13B7D19A17DF77E980',
                                    12: h'DEFDF1AA746718016EF1B94BFE5FB7774B8665F57D48ADAB83ABE0B28C22DB59',
                                    13: h'A8868DF71AA4FB7D0AD3459C2E75E63767FE477B5A8FDF45537E936AFAB59C44',
                                    15: h'95B651F1BA60EF5867E63E8DB1B0328464E5B66775E213B743A1E31F8EFBD9CB',
                                    16: h'364E3C65D46D06FEDEB0E7293A86BA45FDFA99AA1A6DA3C3289B6E073B589922',
                                    17: h'B584E5D5EF4CFC93FDB1E4EE8F3996090EF0B1E8FD2AC594D7D8793093BB328F',
                                    18: h'677468F3E28CAAB521337E0FEF7FFEB067D2A2704F88B5D50D84CAF17209BA25',
                                    19: h'95501E3E769230DC945CFBDC707C45218459F1129EFD5088BDA672CEF5991598',
                                    20: h'677FACBBCA2EB9306BD649227B9AD66DF4A9AF6A5AB7D073F1BAAC23254B6D78',
                                    22: h'BCCFB15CB36125BF1ECBFDE32FF908BD3BAA2DC0BA949B673E96CBA26902059F',
                                    23: h'F9EE4D36F67DBD75E23311AC1C294C563992463A30B47039D25E03B6C6EFFCA3',
                                    25: h'AFC5A127BE44753172844B13491D880C3768691A4C9916E5257CEFA4BAA74654',
                                    26: h'1E1DA854356D3CFB7D983B8105F8A081057D4D01E910F263143BDC9AF1EF363C'
                                }
                            },
                            "deviceKeyInfo": {
                                "deviceKey": {
                                    1: 2,
                                    -1: 1,
                                    -2: h'B820963964E53AF064686DD9218303494A5B23A175C34CC54AD1D9244EFD0BA5',
                                    -3: h'0A6DA0AF437E2943F1836F31C678D89298E93D7E95057FD4D04E8E3EC2BBA935'
                                }
                            },
                            "digestAlgorithm": "SHA-256"
                          }
                      >>)
                    >>,
                    h'1AD0D6A7313EFDC38FCD765852FA2BD43DEBF48BF5A516960A685162B2B8242935861329ECB54F68234FC88A0228EC5DF22CB9689EC5053C80EDC59CC99EE80D'
                ],
                "nameSpaces": {
                    "org.iso.18013.5.1": [
                        24(<<
                            {
                              "digestID": 1,
                              "random": h'E0B70BCEFBD43686F345C9ED429343AA',
                              "elementIdentifier": "expiry_date",
                              "elementValue": 1004("2030-02-22")
                            }
                        >>),
                        24(<<
                            {
                              "digestID": 6,
                              "random": h'AE84834F389EE69888665B90A3E4FCCE',
                              "elementIdentifier": "given_name",
                              "elementValue": "Doe"
                            }
                        >>),
                        24(<<
                            {
                              "digestID": 11,
                              "random": h'960CB15A2EA9B68E5233CE902807AA95',
                              "elementIdentifier": "issuing_country",
                              "elementValue": "UT"
                            }
                        >>),
                        24(<<
                            {
                              "digestID": 13,
                              "random": h'9D3774BD5994CCFED248674B32A4F76A',
                              "elementIdentifier": "document_number",
                              "elementValue": "ES24689"
                            }
                        >>),
                        24(<<
                            {
                              "digestID": 15,
                              "random": h'EB12193DC66C6174530CDC29B274381F',
                              "elementIdentifier": "portrait",
                              "elementValue": h'89504E470D0A1A0A0000000D49484452000001F3000001F20803000000C88DD7DC0000001974455874536F6674776172650041646F626520496D616765526561647971C9653C00000180504C5445336D82D0B293417E9A4848484684A24A8CAE306A7ED1C8D144809D357085407D993F7B96B3B3B0275D718687864765734886A54A8BAC3E7A954A8AAB38738ACFA8CE4686A53C7993FEE6CF4787A74785A44584A33D7A94A18B7655555543819E3A768F498AACE4D6E339748D4B8CADAC67AA71706F74878436718845565D4545454A5F68FEF0E3395965E2C5A545748A2E5A69FDDCBCB0AA9737515A515151F1CAA33B77904C4C4C3E7B96939B986D929EB79C824783A044494BD1BDA35B899BA0A5A2466D7D4C839AFDD2A84F879F424D524C8DAF515B5FFFFFFF467E9AA458A25357594888A840778F42809C4989A94582A04583A1417F9B40748B4482A043819D4483A14888A7407C973C78913A758D3E79934889AA3B7891427F9C42809D4889A9498AAA3A758E417E994988A843809D39748CBA82B9E9E6E98E7C6CF3F3F3E6BD9E50555773685D5E5E5FFDD5AE5C5651504D4BF9F4F9F3EAF3FEFCF9675F57FEF8F14170845C7A7E38748E6A4E69487F9B467B94925591816E80534A530E2CDF5E00001E3B4944415478DAECDDEB6313C77600F031A212B13D1675E340C15EA7BAB588A41819635FD72832288A6AC55CA879A55052726FD35BD960630C01737BDDF65FAF64F9A1C7AE761E6766CE91E77C49F20556FBCB397366667796FD33C2F89BC8F8C793F8DB88F887BF0B8D3FFDE9E79F7FFEE31FFFA533FED015FFF9877F6DC6DFF7C5E5767C751447FF7AAD372E5E3F8D8B47F1E8347E3A8AA7EDD83C89E6BFCF76C7B3A3F8F3A54B977EF9E56167BC3A89C7EDB8D015BF8E76C6F3EE18EB89C9C9C9E9664C4E324F7EDEC8319A7B72B3E4D3CC939F37727CE69EDC34393A734F6E9C1C9BB927374F8ECCDC935B20C765EEC96D90A332F7E456C831997B723BE45798273F6FE42F99273F6FE468CC3DB935722CE69EDC1E3912734F6E911C87B927B7498EA26FF7E456C931987B72BBE408CC3DB96572F7E69EDC36B973734F6E9DDCB5B927B74FEED8DC933B20776BEEC95D903B35F7E44EC85D9A7B7237E40ECD3DB923F217CC939F377267E69EDC19B92B734FEE8EDC91B9277748EEC6DC93BB247762EEC99D92BB30F7E46EC91D987B72C7E4F6CD3DB96B72EBE69EDC39F9BF334F7EDEC82D9B7B7204E476CD3D390672ABE69E1C05B94D734F8E83FCF7CC939F37727BE69E1C0BB935734F8E86DC96B927C7436EC9DC932322B763EEC931915B31F7E4A8C86D987B725CE416CC3D393272F3E69E1C1BB971734F8E8EDCB4B927C7476ED8DC932324FF9A79F2F3466ED4DC93A3243769EEC971921B34F7E448C9CD997B72ACE4C6CC3D395A7253E69E1C2FB921734F8E98DC8CB927C74C6EC4DC93A3263761EEC971931B30F7E4C8C9FF839D1FF2C362259DCE35A3963F895AEB3FD3E974B1788EC8C1CD31926F36B173E57C4CD49AF8C54BE7801CDA1C1DF961A523AD05A29C4B1F1C0E37F9BFB12126FFB1129FDD51F0C5E1258735C7447E98AEE5B5A2E93E9CE4A0E678C8B5C14FDD0F878F1CD21C0BF9771518F0E3D62E5D1C3272407324E43FA6CB79E0A8158AC3440E678E83FCC742DE48D45A457E48C8C1CC51909B126F8FED0743420E658E817CD3A4783BD97F1D067220730CE49572DE7C140EE993C39823203FACE5ED44AE489DFC776C38C8D3797BD154274D0E61EE9EDC5A929FAA5326FF2F3604E45646F21EF543BAE4FAE6EEC90B79175138A44AAE6DEE9C7CB3967713E50A51725D73D7E4C58A2BF256817F40925CD3DC297931EDD0BB1D698AE47AE60EC98B85721E419CA63A21722D7367E4DF556A792451AE9023D7317745FE5DBA9C4714056AE41AE6AEC82BA8C45BF5FD392D72757347E4C55A1E5DD41E902257367743FE5D3A8F31CA4F2891AB9ABB213FACE5F378D1A9907FC9089157F268A3894E865CCDDC09F977853CE2288F9121573277435ECBA38EDA181572157327E47F454EDE9CB25121573077427E58CEA38F34117279734F1E194F68904B9BFBB17CC0904E835CD6DC930FACEE24C825CDDDCCCB73792AF18402B99CB91BF23419F27C8E02B994B95F7D8B8DF931FCE432E66EC8FF5AA6645EE663E8C925CC1D6D9ED6F2A4E2361FC34E2E6EEE883C9D27169C8F2127173677447E488DBC99E8FC9F70938B9ABB7A102A47CEBC99E8FCF7A8C905CD9D3DFB468FBC95E827E838C9C5CC9D3DE15A23685EE627E848C985CC9D3DC79ECEE789267A0B1D2BB988B9BB5717CA24CD6BFC081D2DB980B9BB179468A6793EBF7084FE2556F2787377E444D3FCB8B873FE0D52F2587387AF2156F25483F7A2A3228F3377F9B2718DACF9420F3A2EF2187397E445B2E4C75DDC293A32F26F18DA23050A74CD4F8A3BE70C21F94073A7E49B65C2E6B74FD193F8C80799BB3D2BA64298FCACB837D1D1910F30777C3C508EB2F95971EF4547401E6DEEFA4428D2E4A79D7B2F3A06F24873E78780D136BFCD3BD1AFA0228F32777ED45F9AB6799977C5154CE411E6EE0FF4ACE587A7B89FA023210F37774FBE499CBCBBB8B7D1B190879A23388F5D6538DFDF456CCEAFA0210F33C7F0A10DC9E17C3F5B1AA956AB25B4037A335E60210F3147F10525A9D9F976A97A1C25B4037A33FE8284BCDF1CC777D2C4175EF76796AB67B18DB7B8B7D05190F799E320DF5413C7841E62CE7F8782BCD71CC90730455BB8ED1E7144E8651E868E81BCC71CCB676EC53658DE8D544302CB98CE07A03B25EF3647F331EBB4629263425F0845FFC63D7997399EEF978B3C2F51AA46C5C83ED601BD195F3827EF34C7432E3055DB1FA946C79B8F78CDF917AEC93BCC1191C79B0F24AF5697117472351E85EE98FCCC1C13F9E59A1E796B50DFC7D9C41DA3BB243F3547457E599BBC39A87FC4D9C4B5CBBB4BF22F1846F23873017204F53DDA9C275D921F9B2323BFACDAB1F7A4FA3B944D5C27BA0BF2B63936F2C1E6DB55D1709BEA83CC8FD19D901F99A3231F68BE5B950897A37A8DC7A1BB216F99E3231F64BEFFA62A15EE1AF8328F417744DE344748FE15C0607E56E067D04DD68ED1BF7643FE05C348FE1550653F5996DB4669CEF9D74EC807983B24FF0AACB23B555F1043B74D1E6DEE923CDA7CA6AA182ED4E3CD5BE8D6C923CD9D92479ABF5BAE56D5D5F7314DD64ED0ED934799BB25FF0AAC81EBE9E6DEA1333F42B74B1E61EE98FC72C42390EFAABA51CA6233E77FB14D1E6EEE9AFC72CE449A1F97F812C832CDFEEECCCC4CCC68511332E75F5A260F35774E1E61FEAE0A1323DB9A35FE63E96497A7F44EDFBC13DD067998B97BF208F352152C46D4B3FDDDCC1BC125FD329745B7421E628E803CDC7C7FB90A19CB2585747FB73D22F170359744B743DE6F8E81FC5A4E6F3F4D6270DF96C8F7DD52E8C6FDB6BE791BDD12799F390AF270F391AA9918296DC7BFD1BABB5D8A2C33DBFAE62D745BE4BDE638C8AF853DDFFEB16A32DE8C9466B2BB6149BF9B9D29C53C71F9517D21EEEC24396BE43DE648C843CD4B552BF166A415CD8958A9F54FB1E5FD1100F34E74B3E4DDE658C843CDDF54F1C60C80F919BA61F22E7334E461E61FAB98E31D80F909BA69F24E733CE461E625D4E62508F336BA71F20E7344E461E66FAAF4125DD6BC856E9EFCCC1C13F9B5A2B17557AB23BAB4394F5A203F3547451E62BE8DDCFC0D8C7913DD38F989392EF210F31272F3EA4718739E344E7E6C8E8C3CC47C19BB7909C8FC14DD1879DB1C1B79BFF92E76F2D0E2AE647E8C6E8EFCC81C1DF9B5436AC37978E7AE667E846E90BC658E8FFCDA3572C379E84E8BA27913DD2479D31C23F93562B3F388015DD59CF32F0D927FC150925F24363B8FD8685137EF4407276728C9AF936BE19A016A7E860E4FCE50925F2F03BDBEE2B689D3313F413740CE50925FCF916BE1AAD55D58F336BA09728692BCD77C8482F936B0790BDD08394349DE6B4E813C649B45D39C7F69869CA124EF31FF48C2BCA4F30C64C4A16246C8194AF2EB057A6D7BC8648D1B42D7246728C9AFA7A9ADBC1A320F45D7256728C97BCC494CD5FA27E8656E045D9B9CA124EF311FA1695EE326D0F5C9194AF28B456F7EF6901C34394349DE63BE4CC37C57E9CC01397408728692BCC7BC7ABECD3BD041C8194AF28B17BD79D7863A2839C3497E91DEF4BCDF7C8103A30391339CE48F6A04CDB7CD991FA14391339CE4773ACFFEA0623E03BF24D3890E46CE5092AFB61E24DDA5B50CD76D9E2D2D571761D1C1C81956F28E4D8B1972E6BBEDE7F7CCA32B913384E47797BB77AAC8999F3EE2F1D930BA1A39C347FE68BC677B929AF9D9533D37B951744572868FFC87DE56988A79A9FF41AE1B26D155C9193AF247F73AEED9F23B2A4FC39D6EA6765D2DEC88DE8DAE4CCED0913FBAD97B1F472899F74C32B831747572868EFC51DF420725F3DEC7B83E9B42D72067E8C8EF74DFB437B4CC7BAF75959B41D72167D8C8BB86F376A21332EF6B3717B911742D72868DBC63A67692E854CC97438E211EE126D0F5C81936F2476B7D5B1754CCAB61330C6E025D8F9C6123EF371F21631EF6FA2C3782CE74C81936F2EEA95ABB6652312FD932E79C6990336CE43F55872B3E5B478F2567D8C8BDB9267A3C39C346EECDF5D099AAB943F26133AF70ABE84CD5DC25F94F3787CB9C739BE84CD5DC29F94F6BDE5C199DA99ABB257FEACD95D199AAB963F2A7E34345BEC6EDA1335573D7E44FEF0D95F908B7862E2A9E64D8C89FAE0E95F9A269F3D3C57761F25E73F7E44FEF0C95F92AB7842E4EDE638E80FCE90F7E4946015D82BCDB1C03F9D3CDA19AA057B8157419F22E731CE49BC334595BE656222943DE698E847C73981AF7118E093DD96B8E857CF38E6FE1CCA0277BCDD1906F6EFA16CE087AB2D71C11F9300DE89CA3414FF69A63221FA2017D91A3414FF69AA3221FA201FD06C7829EEC35C745FEF4E9D0CCD02B1C097AB2D71C1BF9D06CADAD718E033DD96B8E8E7C76588AFB04C7819EEC35C7473E3B3B24C53DC951A0277BCD3192CF0E47E7BEC83906F464BF3942F2D9E1D85BFBCC31A027FBCD3192CFCE0E431777937304E8C9507384E4B377FDE41C063D196A8E917C7676CDA739047A32D41C27F9104CD726B87BF46484394A72FA89EE30CD4FD19311E648C9C98FE837B873F4A4883922F2D9678BFE01193DF4A488392AF2673F905E8CAB70E7E822E6B8C89F3DA3DCC6AD728E179DA1257F46B8BAAF718E189DE125FFF325AAD57DB9C231A333C4E4977E58A669FE9973CCE80C31F9A55FEE9044BFC1396A748699FC978714D1119187A333D4E40F1FDEA136A62FA3220F4567B8C91F3EFC9E56F73E52E11C3B3A434EDE8CBBE3640AFCE2678E2F42CCB1933F2453E12B1C67F49953207FF88A42815FE39C063A2341FE8AC23AEC2A2782CE4890BFFADEAFC4C0A13312E4AF5EE17F8462997322E88C06F92BFC27882D722AE88C06F92BFC8FCDDCE054D0190DF257AFD0CFD6929C0A3A2342FE18FB6C6D8D732AE88C08F963ECB3B5094E069D11217FFC187971AF7032E88C0A39F2E2BEC639197446851C79719FE09C8C3AA342FEF8C24D5FDA61D01919F20B8BBEB403BDED4086FCC25D5FDA61829121BF80B9B8274999D321BF8077CD7D91533327428EB8B8DFA0664E85FCC205AC1BAACB9C98391D72B4C57D91983921F20B17903E005BA16E8E98FC02CE23C4D6387173CCE448BBB81BC4CD5193FF3A8A718ABE9CA46D8E9C7C74D57770D0E6D8C94747977D07076B8E9F7C14DF89CF239CB23901F2D1BBBE838334A7403E3A8A6DBA76931336A7413E8AED719909C2E644C84747D7FC440DC89C0C39B2E9DA2A276B4E877CF4F94D3F518330A744FE1C53A22F72AAE6A4C89F634AF40A557362E488129D649AB7CCA9913FFF7ED9A7B99E3939F2E7CFEFF934D73227488E26D12BA4CD49916319D189A6F9B13931F2E7777C9AEB9A5323C7614E35CD8FCCC991E330AF1036A747FE7CCCAFB46B99532447604E7143EDC49C243902F3094EDC9C1AB97BF39B9CB83939F231E70F4E7C266E4E8FDCBD39A76D4E90DC9BEB995324F7E6FA6BAFD4C8BDB9B63939F2B17BDE5CCF9C1EB937D7342748EECDF5CC29927B732D7392E4DE1CD49C04F9D81D6F0E674E83DC9B039A13219FF4E660E654C8BD39983919726F0E654E877CDA9BC39813229FBEEBCD21CC29914F4F7B7300735AE493FED1287D7362E4AECD4786C09C1AB937D73627473EEDCD35CDE9917B734D7382E4DE5CCF9C22F9F4B237D73027493EBDE6CDD5CD69927B731D739AE4DE1CC49C14B93787302745FEFD1DC76741AEDD4DD237A7447E2755AF5F756B7EB55E4FDD256E4E88FCE06DBD8EC1BCBE555BA06C4E883C9DB8D732FFD6BD797DA27C9BAE391DF2835A22F11A8B7926912099EA8C14793A914864EB58CCEB6F13098AA9CE08913F692679A25DDA71984FB4AEA746D09C0C79BADCBAC589141EF3F1A30B2A53ABEF8C0AF9EF7389766CE1314F1D5FD26D8AE6F8C90F6AC7F73751C763BE75724DB45A3946833C7D7277136FDBE675B7E69FDA17717A55E57962E6E8C94FEBFA69DBEE7851E656BDC79C547D6704C80FCA897E73A7C5FDDBE38BC8765C189DFACEF093A7138910F3FA2D77E47BF510733AA9CEB0933FC925C2CD3FB94FF31E732A5375869CBC524E4498BB1BD16FD523CC894CD5196AF207854422D2FC3747D57DEFB748731AF59D61263F9B948799D73FEDB9ADEC61E6145A3986983C5D4E0C3477D3BB7790B73659FA027F7D6768C91FE41289187317E8573BFFFED02B445FDF1956F24A39116F6E1FBD8B3CC21C7BAA339CE411497EB6DEEE08BD9BBC1E7991B7919B23240F6BDEC2CDEDA2F79067A2AF12732BC7109287CCD03AE2752FFA9E93F6AD732F9558AA3384599E1B742B8F9F99A8DB9FB2EDF5920F36C78BCE10B66F92E69616676E7DEAFB8BEF0DBCD01A6A7364F3F2817732315EEF0F0BCBB0B77EAB0F9339B635F6C1E6F742CC8D0FEA7B57C3FED62C5973743B6983CD27C2EEBEE1FA1E52D7E3CD1378CD91EF97C72CCA74D4F73D5B53B4F8E939727364E44FD2EB4B31B73202A0FEE996D524AFD75FC75C68909B5F406C8E635E5E29DC0F8220CEFC7514BA91517DEF6AE45F978AB9D0A5E68FD9C92D203547405E49AF07EDD88FB995A94884FA6F57AD25F9E92B0D83CD8FD891A53B4340FEE0205D08CE6225213F593B4BF55B6697613A6355CC1C9D3B734CFEE02CBF45CD57EB0303AEC00F28EB226D7B62BFFB77A171670EC99BE97D3FE88F38F3EC608966818751BFFA5BCC5F14C899A381676EC80F2A85F520221271ED703D2E3E5D353B908BB5ED8995A85F989B770ACFAC930FE216323F7E4BD1A8FAAD6FE3FF8E94B2F971C2BB826716C95F16D331DC62E6A97ADDACBA8878DC6A7B9CF971C6BB28F5CC0E79B35513E10E04A6E7112BEE70EA62E2C7270E689A3B8167C6C98B95F0564DDD7CA25E37A77EF593E89F9E8DBD50895F7DD4DC2DD8343743FEB258114D6E29F3B775E190ECE1F7C4C56357DB25CD2D0EF2CC0CF95831ADC02DB40C3770F5556B95662F767626D5C22998DBA9F5CC00F958A510A8878079AA2E159F84925D7418175D79ED5E8853C87893E6C0E463E9402B5612504D5C47898F5B9C934B71B1164ECBBCC5BE60CC1C98BCB81E18379FA8CBC720F5BD6F15FEC0B7A6CD9B45DEDC7A3B24B966928B9907759588ACF0F2392EB20A07601EEC983207241F2B68930702F75264254EF8A18ABD4F4A7F98400B17BAE08EA0BE3350F2F5C08E79AAAE1657C59E6705598503313782CEB0910B99AFD6A1D0AFAAFE495981CB5C0950A2336CE44B22E6D93A10BA6A96C76FA442991B4067C8C8C5CC13CAE6DDC74DED29936712B6CCE11B3906D6B1C3900B9AA794CD3F0D7AE910744506CA1C1C9DE199A4092FC3A9ACCA8456F75BEA7FCA84D06502DD939C31732DF24A60D55C7940FF90C9BC398EE5EA2775F3B736CD837943E67AAB6F50BF4E6449467E40DFCA4C4D351A731B7DD1684C4D653EC8936F25AC9A070B46CCF5D6D8EFDB36171ED03F34B537E2A2319531309C039AEF9830D7DB492B04B6CDC74575E2C1DB3137B5053E9CEB2FBE1A19D21904F9011C7920763385B759DE6F88C7FB0F5BB0C339A039E490CE20F6CBEFDB3717DD66C948983736E63E800EE790E63BC0E69A4FC500567661F34406B6B49FB0BF871CCE21CD01AB3BD32787ACEC824B32C203FAD48664342087735073B8DE9D699303ADB9CA9A4F4057F6E398021CCE2136D60C5477A6FDB8633A70622E3243FF30276FBEB105379CC39A83B5714C97FC41E0C83C053E981F4FDADE830DE7C0E63BA0E61ACFB11760CDF785CDEFC10FE6A2D55D743887DA64016EE39826793170659E3552D95B113B25081C9903B5714CF36D15E034175D861379B3A1A1481E5BDD330957E63928731D72E83497314F19A9EC02D57DDC99394CA233BD77D2D61D9AAF9AA9ECF1D53DEBCE1C24D19916792570689E3553D9E35766C42F3111604C74A6F5E629789A0712F773E053EE990DAD98D27CB2DD98790EC65C9D1C3ECDA5CC072DBFCEE9990FDA6C5975690E91E84CE74881825BF309230D5C6CA2679D9A03243AD3202F066ECD03330D5C4C1BB795706A0E90E84CE3E0100369BE247343A3F753B5D37C401B37EED85C3FD1993AB989349733BF67A6816B474A77E1157C33F53860CDE58E072A3837CF9A98A7C5ADC605AECDE721CDE5C81F04CECD23965F41D23CAA8DCB245C9BEF009A4B1E02963661BE2F673E6E629E3638D1EF3937D74E74A67CEEDB7D04E6A1B3B5D4C686C144CFBA37DF81329725AF0408CCC3666BEFE7A0CC373EA81D2962DA5C77BAC6540FF42C60300F9BAD4D8191CFA534676AA6CC7320E6D2E445233F46668B2562B60696E68DD47BDD999A29F300C25CFED8DE020EF3ACA1346FA43E00CCD48C99CFEB9BCB93BFBC8FC3BC7F6F6D4A7B723EE885C5540285F98EB6B9C2E1DC663A3805F3B0D95A66AAA158E0E7E25E505D95BCBC7D43F76941D35CE53CF60216F3C8BDB54C2AFC8DF3E899594AE075A8B748CC737AE64A47F00758CCE3DE55DCCA6404ABBDC8EB895B0924E65A5D1C53FAD0461A8DB9C8AB0D1F84CA3AE4BB89E6CDE721CCA5BEADB26EEAA748930B1D0F38A5F79084F24CCDA0F90E80B9147931C0632EF2D1868CC6D6A9C6229C49739D2E8EA97C41A980C85CE845F406CC703E8EC87C5ED75CF2A359F731998BBC88BE05F3DEF90422F31D4D7349F2830093B9D051715320C3B9FCE52D05088B3B53F81A620195B9D861EE71E82223442A81C93CA7632E4BFE32C0652E74CA4806C05C6E116E65DF20B8567167F2DF3CAD203307396544A46D7F8B855BB38B63F29FB92D203317FADCDA94FE789EC1C3AD57DC9934B9C9D2AE669E02306F00CCD45696AC796B157726FD316B93A53D58DA5F3153DCA7F4975EB331E081ED98D73197FA7E79C1F86F596ACAAF74DAAF74FFA7CA9990B1AB325AFB2B2B818BC869984B913F70F2F396564C1F2195D12AED4ED077D4CDA5C8CD96762571A17D9686F67AFB84E52325CC157726496EA1B4CB8A0BEDB368EFABC5EFAFAC5029EE4C927CEC3E3A71A17D16ED057791FD15DB7DDC0E84793CB9E5D22EF8FE5A6C717FAFFDCC84D8FE8A65F5057DF378F2B1B4CD9FB402B6CF22B0830EB5BFB28FBEB83339F2B1755C455D749F45C03C03B6BF622FD97774CD45C88B18C105F65952BA0FCA486E9DAF602EEE4C8ADCD2702EBF1697D5DD3F8F6BDC516D9D6BCED69814B985D2BEB4AFB4E6BEA56DDE00DE3AB7C29ED33117237F80ACA40B17F786E6C3CEABAAD7657A6CD7301723375DDA95C563F759445E6B807C7FC55A1F3FAF6C2E486E7A116E49FDCEC66CA28B9867204EEFB65DE073AAE6A2E4A617E174CC0717F739BD27DC57352E0CDF6C8DC9901B9FA9254C1577CDE33EDFA2355799AD310972F38B702BA68ABBDE01DE3AA5DDF44C7D5EC55C9CDCFC9E9AA9E29ED17B4B7115ED70AE54DC9904B985C7250C1577B1530229967695D91A1327B7B108973053DCC5CC33044BBB4A7167E2E436F6D456CC1477B183855260AF26E25E8A63E2E49316F6D496CC147731F3298043FAED9BEFE898C7913FB1B169A053DC75CD1B40078A581DCE15666B4C987CD2CA9E9A4E714F697E84690EBEB4DBD8539D57368F259FB4F2F4A399E22E78661CC5D2AE30A03361F2693B8FC8E8D451DDAF3065289676F9019D09935B19CEF506F494CE325C54E38EBDB4CB0FE84C947CDAD213AFFB268ABBBD03DB1D3C2B233DA03351F2694B2F332C1928EE5B82E60D8AA55D7E4067A2E4D3B65E663050DC453FD03247B2B44B2FBF3251724BC3B9DE6C6D42F3DB5B244BBBF480CE04C927ADBDC062A0B80B9FE99EA158DAA5077426483E69EFDD44F8E22E6C9E2259DA65077426483E69EF0516F8E22E6C3E45B2B4CB0EE84C90DCDA706EA2B80B7FBAA141B2B4CB0EE84C8C7CDAE6FBA8E0C55DD87C8E6469971DD09918F9B4CDA306C0D7DCC53FD142B3B44B0EE84C8C7C7A3D2092E8AFD597E1FA1B7722A55D72406762E4764F0E827E5A46F903D8444ABBE480CE84C8A7ED1E2F015CDC3F889B4FC13DFC68F5C4897915F3C1E4D3568F97802EEE12DFC66E803DFC68B5B4CB0DE84C887CDAF26951B0C55DC27C0EECB9F67DAB376C47DE3C8E7CDA2E39707197F99CE67B32CFB5AB0FE84C88FCC0F22F802DEE32E61932CFB5AB0FE84C84DCF6700EFC12938CF91491579674067426427EC5FEE18F90C5BDA1684EA8B44B0DE84C84FCE5BA7573C8375465CC1B344BBBD480CE44C89F58FF05A0C55DC67C8EC241039A033A13207FE9E22C678D1B9E555E86EB6ADCDF524A7399019D0990BF4C07B4127D4BC33CA3773C989B0E4EC73C9CFC6521A095E8E392E7FB86367113A44ABBCC360B13207FE9E227E8747159D565B84E738DFFE9F65DDCAF0525F328F20327E660C55DCEBC0150DA9DDCAF7915F328F22B1527BF01ACB8A7A4CCE7F44B3BF62FF2B078F22BE9805AA2BF555D863B6BDC03521D9CD4AA0C8B27BFB21E904BF48CBA798666699768E2583CF91547BF41E775C55575F329DDD2BEE4E8762D489A0F223F70651EC014F78682F96B7A692EDEC4B1587257C3B9DE742DA36CDED07C106EDFD5DDCA49990F24BF52080826FAAAF421135D8DFB04BD34176FE2582CB9B3164E2BD103C5A5D776E3FE9ADA444D6A4067B1E457DCFD089DE95A4AD93CA355DA1DDEAD7961F338F20387BF42A3B84FA82DC3B59BB82CC53417378F2377D8C269257AA061BE456FA226D3C4B13872972D9C56A2A754CD1B1AA5DD659A0B37712C8EDCB1F99276719F92359FD328ED4B4E6F966013C7E2C85F0401D1447FAD68BE9122D9C1890FE82C8EFCC0B1B9FA02ECB8AAF9FF124D7309F381E42F2A01D5449F505A866BC6FF114D73D1268EC590BF480764137D4BCDFC7FA8A6B96813C762C85FAC0764137D5C65E97563E3BFA9A6B96813F7FF020C008EA9ADF1AC1529080000000049454E44AE426082'
                            }
                        >>)),
                        24(<<
                            {
                              "digestID": 19,
                              "random": h'DB143143538F3C8D41DC024F9CB25C9D',
                              "elementIdentifier": "birth_date",
                              "elementValue": 1004("1980-02-05")
                            }
                        >>),
                        24(<<
                            {
                              "digestID": 20,
                              "random": h'6059FF1CE27B4997B4ADE1DE7B01DC60',
                              "elementIdentifier": "family_name",
                              "elementValue": "John"
                            }
                        >>),
                        24(<<
                            {
                              "digestID": 22,
                              "random": h'1E69C89C81B21A1BA56ACA3E026A2A3F',
                              "elementIdentifier": "issue_date",
                              "elementValue": 1004("2020-02-23")
                            }
                        >>),
                        24(<<
                            {
                              "digestID": 25,
                              "random": h'CAD1F6A38F603451F1FA653F81FF309D',
                              "elementIdentifier": "driving_privileges",
                              "elementValue": [
                                  {
                                      "issue_date": 1004("2018-08-09"),
                                      "expiry_date": 1004("2024-10-20"),
                                      "vehicle_category_code": "A"
                                  },
                                  {
                                      "issue_date": 1004("2017-02-20"),
                                      "expiry_date": 1004("2024-10-20"),
                                      "vehicle_category_code": "B"
                                  }
                              ]
                            }
                        >>),
                        24(<<
                            {
                              "digestID": 26,
                              "random": h'53C15C57B3B076E788795829190220B4',
                              "elementIdentifier": "issuing_authority",
                              "elementValue": "UTOPIA"
                            }
                        >>)
                    ]
                }
            }
        }
    ]
}
```

In the `deviceSigned` item, `deviceAuth` item includes a signature by the deviceKey the belongs to the End-User. It is used to prove legitimate possession of the crdential, since the Issuer has signed over the deviceKey during the issuance of the credential. Note that deviceKey does not have to be HW-bound.

In the `issueSigned` item, `issuerAuth` item includes Issuer's signature over the hashes of the user claims, and `namespaces` items include user claims within each namespace that the End-User agreed to reveal to the verifier in that transaction.

Note that user claims in the `deviceSigned` item correspond to self-attested claims inside a Self-Issued ID Token (none in the example below), and user claims in the `issuerSigned` item correspond to the user claims included in a VP Token signed by a trusted third party.

Note that the reason why hashes of the user claims are included in the `issuerAuth` item lies in the selective release mechanism. Selective release of the user claims in an ISO/IEC 18013-5:2021 mDL is performed by the Issuer signing over the hashes of all the user claims during the issuance, and only the actual values of the claims that the End-User has agreed to reveal to teh Verifier being included during the presentation. 

The example in this section is also applicable to the electronic identification credentials expressed using data models defined in ISO/IEC TR 23220-2.

# IANA Considerations

TBD

# Acknowledgements {#Acknowledgements}

We would like to thank David Chadwick, Daniel Fett, Fabian Hauck, Alen Horvat, Edmund Jay, Ronald Koenig, and Michael B. Jones for their valuable feedback and contributions that helped to evolve this specification.

# Notices

Copyright (c) 2022 The OpenID Foundation.

The OpenID Foundation (OIDF) grants to any Contributor, developer, implementer, or other interested party a non-exclusive, royalty free, worldwide copyright license to reproduce, prepare derivative works from, distribute, perform and display, this Implementers Draft or Final Specification solely for the purposes of (i) developing specifications, and (ii) implementing Implementers Drafts and Final Specifications based on such documents, provided that attribution be made to the OIDF as the source of the material, but that such attribution does not indicate an endorsement by the OIDF.

The technology described in this specification was made available from contributions from various sources, including members of the OpenID Foundation and others. Although the OpenID Foundation has taken steps to help ensure that the technology is available for distribution, it takes no position regarding the validity or scope of any intellectual property or other rights that might be claimed to pertain to the implementation or use of the technology described in this specification or the extent to which any license under such rights might or might not be available; neither does it represent that it has made any independent effort to identify any such rights. The OpenID Foundation and the contributors to this specification make no (and hereby expressly disclaim any) warranties (express, implied, or otherwise), including implied warranties of merchantability, non-infringement, fitness for a particular purpose, or title, related to this specification, and the entire risk as to implementing this specification is assumed by the implementer. The OpenID Intellectual Property Rights policy requires contributors to offer a patent promise not to assert certain patent claims against other contributors and against implementers. The OpenID Foundation invites any interested party to bring to its attention any copyrights, patents, patent applications, or other proprietary rights that may cover technology that may be required to practice this specification.

# Document History

   [[ To be removed from the final specification ]]

   -11

   * changed base protocol to OAuth
  
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
   * removed support for embedding verifiable presentations in ID Token or UserInfo response
   * migrated to Presentation Exchange 2.0

   -05

   * moved presentation submission elements outside of verifiable presentations (ID Token or UserInfo)

   -04

   * added presentation submission support
   * cleaned up examples to use `nonce` & `client_id` instead of `vp_hash` for replay detection
   * fixed further nits in examples
   * added and reworked references to other specifications

   -03

   * aligned with SIOP v2 spec

   -02

   * added `presentation_definition` as sub element of `verifiable_presentation` and `vp_token`

   -01

   * adopted DIF Presentation Exchange request syntax
   * added security considerations regarding replay detection for verifiable credentials

   -00 

   *  initial revision
