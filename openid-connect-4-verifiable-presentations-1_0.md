%%%
title = "OpenID Connect for Verifiable Presentations"
abbrev = "openid-4-vp"
ipr = "none"
workgroup = "connect"
keyword = ["security", "openid", "ssi"]

[seriesInfo]
name = "Internet-Draft"
value = "openid-connect-4-verifiable-presentations-1_0-10"
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

This specification defines an extension of OpenID Connect to allow presentation of claims in the form of W3C Verifiable Credentials as part of the protocol flow in addition to claims provided in the `id_token` and/or via UserInfo responses.

{mainmatter}

# Introduction

This specification extends OpenID Connect with support for presentation of claims via W3C Verifiable Credentials. This allows existing OpenID Connect RPs to extend their reach towards claims sources asserting claims in this format. It also allows new applications built using verifiable credentials to utilize OpenID Connect as integration and interoperability layer towards credential holders.

This specification enables requesting and delivery of verifiable presentations in conjunction with Self-Issued OpenID Providers (see [@SIOPv2]) as well as traditional OpenID  Providers (see [@!OpenID.Core]).

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

An existing OpenID Connect OP with a native user experience (PWA or native app) issues Verifiable Credentials and stores them on the user's device linked to a private key residing on this device under the user's control. For every authentication request, the native user experience first checks whether this request can be fulfilled using the locally stored credentials. If so, it generates a presentation signed with the user's keys in order to prevent replay of the credential. 

This approach dramatically reduces latency and reduces load on the OP's servers. Moreover, the user identification, authentication, and authorization can be done even in situations with unstable or no internet connectivity. 

# Overview 

This specification defines mechanisms to allow RPs to request and OPs to provide verifiable presentations via OpenID Connect. The specification focuses on enabling request and presentation of W3C Verifiable Credentials but the authors also aim at enabling its use with other credential formats. 

Verifiable presentations are used to present claims along with cryptographic proofs of the link between presenter and subject of the verifiable credentials it contains. A verifiable presentation can contain a subset of claims asserted in a certain credential (selective disclosure) and it can assemble claims from different credentials. 

There are two credential formats for VCs and VPs: JSON and JSON-LD. There are also two proof formats for VCs and VPs: JWT and Linked Data Proofs. Each of those formats has different properties and capabilities and each of them comes with different proof types. Proof formats are agnostic to the credential format chosen. However, the JSON credential format is commonly used with JSON Web Signatures (see [@VC_DATA], section 6.3.1). JSON-LD is commonly used with different kinds of Linked Data Proofs and JSON Web Signatures (see [@VC_DATA], section 6.3.2). Applications can use all beforementioned assertion and proof formats with this specification.

This specification introduces a new token type, "VP Token", used as a generic container for verifiable presentation objects, that is returned in authentication and token responses, in addition to ID Tokens (see (#vp_token)).

Note that when both ID Token and VP Token are returned, each has a different function. The ID Token serves as an Authentication receipt that carries information regarding the Authentication Event of the End-user. The VP Token provides proof of possession of a third-party attested claims and carries claims about the user.

Verifiers request verifiable presentations using the `claims` parameter as defined in (@!OpenID), using the syntax defined in DIF Presentation Exchange [@!DIF.PresentationExchange].

# vp_token {#vp_token}

This specification defines the following parameter `vp_token` that is used to request and return VP Token as specified in (#vp_token_request) and (#vp_token_request).

* `vp_token`: a parameter that either directly contains a verifiable presentation or a JSON array with multiple verifiable presentations. 

## Request {#vp_token_request}

A VP Token is requested by adding a new top-level element `vp_token` to the `claims` parameter. By default, this element contains a `presentation_definition` element, but can also refer to a presentation definition via an URI as defined below.

NOTE: RPs MUST send a `nonce` parameter complying with the security considerations given in [@!OpenID.Core], Section 15.5.2., with every Authentication Request as a basis for replay detection. See (#preventing-replay).

### Presentation definition

This element contains a `presentation_definition` as defined in Section 4 of [@!DIF.PresentationExchange].

Please note this draft defines a profile of [@!DIF.PresentationExchange] as follows: 

* The `format` element in the `presentation_definition` that represents supported presentation formats, proof types, and algorithms is not supported. Those are determined using new RP and OP metadata (see (#metadata)). 

The request syntax is illustrated in the following example:

<{{examples/request/vp_token_type_only.json}}

This simple example requests the presentation of a credential of a certain type. 

The following example shows how the RP can request selective disclosure or certain claims from a credential of a particular type.

<{{examples/request/vp_token_type_and_claims.json}}

RPs can also ask for alternative credentials being presented, which is shown in the next example:

<{{examples/request/vp_token_alternative_credentials.json}}

### Passing a presentation definition by value

This is achieved by adding the `presentation_definition` element to the `vp_token` parameter. Support for `presentation_definition` is REQUIRED. It MUST be present if `presentation_definition_uri` is not present.

For example

	"vp_token": {
    "presentation_definition": {.... } 
  } 


### Passing a presentation definition by reference

This is achieved by adding the `presentation_definition_uri` element to the `vp_token` parameter. Support for `presentation_definition_uri` is CONDITIONAL. It MUST be present if `presentation_definition` is not present.

`presentation_definition_uri` is used to the retrieve the `presentation_definition` from the resource at the specified URL, rather than being passed by value. 

For example

	"vp_token": {
    "presentation_definition_uri": "https://host/path?ref=<string reference to presentation definition>"
  }


## Response {#vp_token_response}

A `vp_token` MUST be provided in the same response as the `id_token` of the respective OpenID Connect transaction. Depending on the response/grant type, this can be either the authentication response or the token response. 

The `vp_token` either contains a single verifiable presentation or an array of verifiable presentations. 

Each of those verifiable presentations MAY contain a `presentation_submission` element as defined in [@!DIF.PresentationExchange]. This `presentation_submission` element links the input descriptor identifiers as specified in the corresponding request to the respective verifiable presentations within the `vp_token` along with format information. The root of the path expressions in the descriptor map is the respective verifiable presentation, pointing to the respective Verifiable Credentials.

This is shown in the following example:

<{{examples/response/vp_token_ldp_vp_with_ps.json}}

The OP MAY also add a `_vp_token` element to the corresponding ID Token, which is defined as follows:

`_vp_token`: JWT claim containing an element of type `presentation_submission` as defined in [@!DIF.PresentationExchange]. This `presentation_submission` element links the input descriptor identifiers as specified in the corresponding request to the respective verifiable presentations within the `vp_token` along with format information. The root of the path expressions in the descriptor map is the respective `vp_token`. 

This element might, for example, be used if the particular format of the provided presentations does not allow for the direct inclusion of `presentation_submission` elements or if the OP wants to provide the RP with additional information about the format and structure in advance of the processing of the `vp_token`.

In case the OP returns a single verifiable presentation in the `vp_token`, the descriptor map would then contain a simple path expression "$".

This is an example of a `vp_token` containing a single verifiable presentation

<{{examples/response/vp_token_raw_ldp_vp.json}}

with a matching `_vp_token` in the corresponding `id_token`.

<{{examples/response/id_token_ref_vp_token.json}}

A `descriptor_map` element MAY also contain a `path_nested` element referring to the actual credential carried in the respective verifiable presentation. 

This is an example of a `vp_token` containing multiple verifiable presentations,   

<{{examples/response/vp_token_multiple_vps.json}}

with a matching `_vp_token` in the corresponding `id_token`.

<{{examples/response/id_token_ref_vp_token_multple_vps.json}}

Note: Authentication event information is conveyed via the ID Token while it is up to the RP to determine what (additional) claims are allocated to `id_token` and `vp_token`, respectively, via the `claims` parameter.


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

Federations that conform to those specified in [@!OpenID.Federation] are identified by the `type` `urn:ietf:params:oauth:federation`. Individual federations are identified by the entity id of the trust anchor. If the federation decides to use trust marks as signs of whether an entity belongs to a federation or not then the federation is identified by the `type` `urn:ietf:params:oauth:federation_trust_mark` and individual federations are identified by the entity id of the trust mark issuer.

Trust schemes that conform to the TRAIN [@!TRAIN] trust scheme are identified by the `type` `https://train.trust-scheme.de/info`. Individual federations are identified by their DNS names.

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

#  Examples 

This Section illustrates examples when W3C verifiable credentials objects are requested using the `claims` parameter and returned in a VP Token.

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

# Alternative Credential Formats

OpenID Connect for Verifiable Presentations is credential format agnostic, i.e. it is designed to allow applications to request and receive verifiable presentations and credentials in other formats then those defined in [@!VC_DATA]. This shall be illustrated with examples utilizing other credential formats. Customization of OpenID Connect 4 Verifiable Presentation for other credential formats uses extensions points of Presentation Exchange [@!DIF.PresentationExchange]. 

## Anoncreds

Anoncreds are part of the Hyperledger Indy project [@Hyperledger.Indy].

To be able to request AnonCreds, there needs to a set of identifiers for credentials, presentations ("proofs" in Indy terminology) and crypto schemes. For the purpose of this example, the following identifiers are used: 

* `ac_vc`: designates a credential in Anoncreds format. 
* `ac_vp`: designates a presentation in Anoncreds format.
* `CLSignature2019`: identifies the CL-signature scheme used in conjunction with Anoncreds.

### Example Credential

The following is an example Anoncred that will be used through this section. 

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

The most impportant parts for the purpose of this example are `scheme_id` and the `values` element, which contains the actual End-user claims. 

### Presentation Request 

The following is an example request for a verifiable presentation in Anoncred format.

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

The explanation in the following will focus on the elements in the `input_descriptor` object in the `claims` parameter.

The `format` object uses the format identifier `ac_vc` as defined above and sets the `proof_type` to `CLSignature2019` to denote this descriptor requires a credential in Anoncreds format signed with a CL signature. The rest of the expressions operate on the Anoncreds JSON structure . 

The `constraints` object requires the selected credential to conform with a certain schema, which is denoted as a constraint over the Anoncred's`schema_id` element. 

The next example leverages the Anoncred's capabilities for selective disclosure by requesting a subset of the claims in the credential to be disclosed to the verifier.

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
                    "id": "id card credential with constraints",
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

In addition to the previous example, it uses the PE elememt `limit_disclosure` to `require` and adds two more constraints for the individual claims `given_name` and `family_name`. Since such claims are stored underneath a `values` container in an Anoncred, `values` is part of the path to identify the respective claim. 

### Presentation Response

The response contains an ID Token and a VP tokens. 

The following show how the `presentation submission` in the ID token helps the verifier to obtain the Anoncred proof in the VP token.

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

The `descriptor_map` refers to the input descriptor `ref2` and tells the verifier that there is a Anoncred proof (`format` is `ac_vp`) directly in the vp_token (path is the root designated by `$`). Furthermore as a nested path, it also indicates that the user claims can be found embedded in the proof underneath `requested_proof.revealed_attr_groups.ref2`.

And here is the corresponding VP token.

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
  
   -10

   * Added Anoncreds example

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
