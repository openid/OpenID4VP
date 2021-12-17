%%%
title = "OpenID Connect for Verifiable Presentations"
abbrev = "openid-4-vp"
ipr = "none"
workgroup = "connect"
keyword = ["security", "openid", "ssi"]

[seriesInfo]
name = "Internet-Draft"
value = "openid-connect-4-verifiable-presentations-1_0-06"
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

This specification extends OpenID Connect with support for presentation of claims via W3C Verifiable Credentials. This allows existing OpenID Connect RPs to extend their reach towards claims sources asserting claims in this format. It also allows new applications built using Verifiable Credentials to utilize OpenID Connect as integration and interoperability layer towards credential holders.

This specification enables requesting and delivery of verifiable presentations in conjunction with Self-Issued OpenID Providers (see [@SIOPv2]) as well as traditional OpenID  Providers (see [@!OpenID]).

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

# Terminology

Credential

A set of one or more claims made by an issuer. (see [@VC_DATA])

Verifiable Credential (VC)

A verifiable credential is a tamper-evident credential that has authorship that can be cryptographically verified. Verifiable credentials can be used to build verifiable presentations, which can also be cryptographically verified. The claims in a credential can be about different subjects. (see [@VC_DATA])

Presentation

Data derived from one or more verifiable credentials, issued by one or more issuers, that is shared with a specific verifier. (see [@VC_DATA])

Verified Presentation (VP)

A verifiable presentation is a tamper-evident presentation encoded in such a way that authorship of the data can be trusted after a process of cryptographic verification. Certain types of verifiable presentations might contain data that is synthesized from, but do not contain, the original verifiable credentials (for example, zero-knowledge proofs). (see [@VC_DATA])

W3C Verifiable Credential Objects

Both verifiable credentials and verifiable presentations

# Overview 

This specification defines mechanisms to allow RPs to request and OPs to provide Verifiable Presentations via OpenID Connect. 

Verifiable Presentations are used to present claims along with cryptographic proofs of the link between presenter and subject of the verifiable credentials it contains. A verifiable presentation can contain a subset of claims asserted in a certain credential (selective disclosure) and it can assemble claims from different credentials. 

There are two credential formats for VCs and VPs: JSON and JSON-LD. There are also two proof formats for VCs and VPs: JWT and Linked Data Proofs. Each of those formats has different properties and capabilities and each of them comes with different proof types. Proof formats are agnostic to the credential format chosen. However, the JSON credential format is commonly used with JSON Web Signatures (see [@VC_DATA], section 6.3.1). JSON-LD is commonly used with different kinds of Linked Data Proofs and JSON Web Signatures (see [@VC_DATA], section 6.3.2). Applications can use all beforementioned assertion and proof formats with this specification.

This specification introduces a new token type, "VP Token", used as a generic container for verifiable presentation objects, that is returned in authentication and token responses, in addition to ID Tokens (see (#vp_token)).

Note that when both ID Token and VP Token are returned, each has a different function. The ID Token serves as an Authentication receipt that carries information regarding the Authentication Event of the End-user. The VP Token provides proof of possession of a third-party attested claims and carries claims about the user.

Verifiers request verifiable presentations using the `claims` parameter as defined in (@!OpenID) and syntax as defined in DIF Presentation Exchange [@!DIF.PresentationExchange].

# vp_token {#vp_token}

The response parameter `vp_token` is defined as follows:

* `vp_token`: a parameter that either directly contains a verifiable presentation or a JSON array with multiple verifiable presentations. 

## Request

A VP Token is requested by adding a new top-level element `vp_token` to the `claims` parameter. This element contains a `presentation_definition` element as defined in Section 4 of [@!DIF.PresentationExchange].

Please note this draft defines a profile of [@!DIF.PresentationExchange] as follows: 

* The `format` element in the `presentation_definition` that represents supported presentation formats, proof types, and algorithms is not supported. Those are determined using new RP and OP metadata (see (#metadata)). 

The request syntax is illustrated in the following example:

<{{examples/request/vp_token_type_only.json}}

This simple example requests the presentation of a credential of a certain type. 

The following example shows how the RP can request selective disclosure or certain claims from a credential of a particular type.

<{{examples/request/vp_token_type_and_claims.json}}

RPs can also ask for alternative credentials being presented, which is shown in the next example:

<{{examples/request/vp_token_alternative_credentials.json}}

## Response

RPs MUST send a `nonce` parameter complying with the security considerations given in [@!OpenID], Section 15.5.2., with every Authentication Request as a basis for replay detection. See (#preventing-replay).

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

RPs indicate the supported formats using the new parameter `vp_formats`.

* `vp_formats`: REQUIRED. An object defining the formats, proof types and algorithms of verifiable presentation and verifiable credential that an RP supports. Valid values include `jwt_vp`, `ldp_vp`, `jwt_vc` and `ldp_vc`.

The `format` property inside a `presentation_definition` object as defined in [@!DIF.PresentationExchange] MAY be used to specify concrete format in which the RP is requesting verifiable presentations to be presented. The OP MUST ignore `format` property inside a `presentation_definition` object if that `format` was not included in the `vp_formats` property of the client metadata.

Note that version 2.0.0 of [@!DIF.PresentationExchange] allows the RP to specify format of each requested credential using the `formats` property inside the `input_descriptor` object, in addition to communicating the supported presentation formats using the `vp_formats` parameter in the RP metadata.

Here is an example for an RP registering with a Standard OP via dynamic client registration:

<{{examples/client_metadata/client_code_format.json}}

Here is an example for an RP registering with a SIOP (see [@SIOPv2]) with the `registration` request parameter:

<{{examples/client_metadata/client_siop_format.json}}

## RP Metadata Error Response

This extension defines the following error codes that MUST be returned when the OP does not support client metadata parameters:

* `vp_formats_not_supported`: The OP does not support any of the VP formats supported by the RP such as those included in the `vp_formats` registration parameter.

Error response must be made in the same manner as defined in [@!OpenID].

## OP Metadata

This specification defines new server metadata parameters according to [@!OpenID-Discovery].

The OP publishes the formats it supports using the `vp_formats` metadata parameter as defined above in its "openid-configuration". 

# Security Considerations {#security_considerations}

## Preventing Replay Attacks {#preventing-replay}

To prevent replay attacks, verifiable presentation container objects MUST be linked to `client_id` and optionally provided `nonce` from the Authentication Request. The `client_id` is used 
to detect presentation of credentials to a different party other than the intended. The `nonce` value binds the presentation to a certain authentication transaction and allows
the verifier to detect injection of a presentation in the OpenID Connect flow, which is especially important in flows where the presentation is passed through the front-channel. 

Note: These values MAY be represented in different ways in a verifiable presentation (directly as claims or indirectly be incorporation in proof calculation) according to the selected proof format denoted by the format claim in the verifiable presentation container.

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

<reference anchor="OpenID" target="http://openid.net/specs/openid-connect-core-1_0.html">
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

# IANA Considerations

TBD

# Acknowledgements {#Acknowledgements}

We would like to thank Daniel Fett, Fabian Hauck, Alen Horvat, Edmund Jay, Ronald Koenig, and Michael B. Jones for their valuable feedback and contributions that helped to evolve this specification.

# Notices

Copyright (c) 2021 The OpenID Foundation.

The OpenID Foundation (OIDF) grants to any Contributor, developer, implementer, or other interested party a non-exclusive, royalty free, worldwide copyright license to reproduce, prepare derivative works from, distribute, perform and display, this Implementers Draft or Final Specification solely for the purposes of (i) developing specifications, and (ii) implementing Implementers Drafts and Final Specifications based on such documents, provided that attribution be made to the OIDF as the source of the material, but that such attribution does not indicate an endorsement by the OIDF.

The technology described in this specification was made available from contributions from various sources, including members of the OpenID Foundation and others. Although the OpenID Foundation has taken steps to help ensure that the technology is available for distribution, it takes no position regarding the validity or scope of any intellectual property or other rights that might be claimed to pertain to the implementation or use of the technology described in this specification or the extent to which any license under such rights might or might not be available; neither does it represent that it has made any independent effort to identify any such rights. The OpenID Foundation and the contributors to this specification make no (and hereby expressly disclaim any) warranties (express, implied, or otherwise), including implied warranties of merchantability, non-infringement, fitness for a particular purpose, or title, related to this specification, and the entire risk as to implementing this specification is assumed by the implementer. The OpenID Intellectual Property Rights policy requires contributors to offer a patent promise not to assert certain patent claims against other contributors and against implementers. The OpenID Foundation invites any interested party to bring to its attention any copyrights, patents, patent applications, or other proprietary rights that may cover technology that may be required to practice this specification.

# Document History

   [[ To be removed from the final specification ]]

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
