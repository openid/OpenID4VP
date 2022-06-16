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

This specification defines a mechanism on top of OAuth 2.0 to allow presentation of claims in the form of verifiable credentials as part of the protocol flow. 

{mainmatter}

# Introduction

This specification defines a mechanism on top of OAuth 2.0 [@!RFC6749] for presentation of claims via verifiable credentials, supporting W3C formats as well as other credential formats. This allows existing OpenID Connect RPs to extend their reach towards claims sources asserting claims in this format. It also allows new applications built using verifiable credentials to utilize OAuth 2.0 or OpenID Connect as integration and interoperability layer towards credential holders.

OAuth 2.0 [@!RFC6749] is used as a base protocol to enable use cases where the presentation of verifiable presentations alone is sufficient. This keeps this specification simple, whilst also enabling more complex use cases. Deployments that require [@!OpenID.Core] features, such as issuance of ID tokens can nevertheless use this specification to extend their OpenID Connect implementations with the ability to transport verifiable credentials, since OpenID Connect is built on top of OAuth 2.0. Especially Self-Issued OpenID Providers (see [@!SIOPv2]) would benefit from combining this specification.

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

A Verifier uses OpenID Connect to obtain verifiable presentations. This is a simple and mature way to obtain identity data. From a technical perspective, this also makes integration with OAuth-protected APIs easier as OpenID Connect is based on OAuth 2.0.  

## Existing OpenID Connect RP integrates SSI wallets

An application currently utilizing OpenID Connect for accessing various federated identity providers can use the same protocol to also integrate with emerging SSI-based wallets. This is a convenient transition path leveraging existing expertise to protect investments made.

## Existing OpenID Connect OP as custodian of End-User Credentials

An existing OpenID Connect may extend its service by maintaining credentials issued by other claims sources on behalf of its customers. Customers can mix claims of the OP and from their credentials to fulfil authentication requests. 

## Federated OpenID Connect OP adds device-local mode

An existing OpenID Connect OP with a native user experience (PWA or native app) issues verifiable credentials and stores them on the user's device linked to a private key residing on this device under the user's control. For every authentication request, the native user experience first checks whether this request can be fulfilled using the locally stored credentials. If so, it generates a presentation signed with the user's keys in order to prevent replay of the credential. 

This approach dramatically reduces latency and reduces load on the OP's servers. Moreover, the user identification, authentication, and authorization can be done even in situations with unstable or no internet connectivity. 

# Overview 

This specification defines a mechanism on top of OAuth 2.0 to request and provide verifiable presentations. Since OpenID Connect is based on OAuth 2.0, implementations can also be build on top of OpenID Connect, e.g. Self-Issued OP v2 [@SIOPv2].

The specification supports all kinds of verifiable credentials, such as W3C Verifiable Credentials but also ISO mDL or AnonCreds. The examples given in the main part of the specification use W3C Verifiable Credentials, examples in other credential formats are given in  (#alternative_credential_formats). 

Verifiable Presentations are requested by adding a parameter `presentation_definition` to an OAuth 2.0 authorization request.
This specification introduces a new token type, "VP Token", used as a generic container for verifiable presentation objects, that is returned in authorization and token responses.  

# Request {#vp_token_request}

The parameters comprising a request for verifiable presentations are given in the following: 

* `response_type`: REQUIRED. this parameter is defined in [@!RFC6749]. The possible values are determined by the response type registry established by [@!RFC6749]. This specification introduces the response type "vp_token". This response type asks the Authorization Server (AS) to return only a VP Token in the authorization response. 
* `presentation_definition`: CONDITIONAL. A string containing a `presentation_definition` JSON object as defined in Section 4 of [@!DIF.PresentationExchange]. See (#request_presentation_definition) for more details. 
* `presentation_definition_uri`: CONDITIONAL. A string containing a URL pointing to a resource where a `presentation_definition` JSON object as defined in Section 4 of [@!DIF.PresentationExchange] can be retrieved . See (#request_presentation_definition_uri) for more details.
* `nonce`: REQUIRED. This parameter follows the definition given in [@!OpenID.Core]. It is used to securely bind the verifiable presentation(s) provided by the AS to the particular transaction.

Note: A request MUST contain a `presentation_definition` or a `presentation_definition_uri` but both are mutually exclusive. 

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

`presentation_definition_uri` is used to the retrieve the `presentation_definition` from the resource at the specified URL, rather than being passed by value. The AS will send a GET request without additional parameters. The resource MUST be exposed without further need to authenticate or authorize. 

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

# Response {#vp_token_response}

The response used to provide the VP Token to the client depends on the grant and response type used in the request.

If only `vp_token` is used as the `response_type`, the VP Token is provided in the authorization response. 
If the `id_token` is used as the `response_type` alongside `vp_token`, the VP Token is provided in the OpenID Connect authentication response along with the ID Token. 
In all other cases, the VP Token is provided in the token response. 

The VP Token either contains a single verifiable presentation or an array of verifiable presentations. 

`presentation_submission` element as defined in [@!DIF.PresentationExchange] links the input descriptor identifiers as specified in the corresponding request to the respective verifiable presentations within the VP Token along with format information. The root of the path expressions in the descriptor map is the respective verifiable presentation, pointing to the respective verifiable credentials.

This `presentation_submission` element MUST be included either in each of the verifiable presentations, or as a separate response parameter alongside vp_token. When processing the response, Client MUST first look for a `presentation_submission` response parameter, and if not found, look for `presentation_submission` elements inside each verifiable presentation.

This is shown in the following example:

<{{examples/response/vp_token_ldp_vp_with_ps.json}}

The OP MAY also add a `presentation_submission` response parameter along with the `vp_token` response parameter, which contains a JSON object conforming to the `presentation_submission` element as defined in [@!DIF.PresentationExchange]. This `presentation_submission` element links the input descriptor identifiers as specified in the corresponding request to the respective verifiable presentations within the VP Token along with format information. The root of the path expressions in the descriptor map is the respective VP Token. 

This element might, for example, be used if the particular format of the provided presentations does not allow for the direct inclusion of `presentation_submission` elements or if the AS wants to provide the RP with additional information about the format and structure in advance of the processing of the VP Token.

In case the AS returns a single verifiable presentation in the VP Token, the descriptor map would then contain a simple path expression "$".

This is an example of a VP Token containing a single verifiable presentation

<{{examples/response/vp_token_raw_ldp_vp.json}}

with a matching `presentation_submission`.

<{{examples/response/presentation_submission.json}}

A `descriptor_map` element MAY also contain a `path_nested` element referring to the actual credential carried in the respective verifiable presentation. 

This is an example of a VP Token containing multiple verifiable presentations,   

<{{examples/response/vp_token_multiple_vps.json}}

with a matching `presentation_submission` parameter.

<{{examples/response/presentation_submission_multiple_vps.json}}

## Encoding of Presented Verifiable Presentations

Presented credentials MUST be returned in the VP Token as defined in Section 6.7.3. of [OpenID for Credential Issuance Specification](https://openid.net/specs/openid-connect-4-verifiable-credential-issuance-1_0.html), based on the credential format and the signature scheme. This specification does not require any additional encoding when credential format is already represented as a JSON object or a JSON string.

Credential formats expressed as binary formats MUST be base64url-encoded and returned as a JSON string.

Table in Section 6.7.3. of [OpenID for Credential Issuance Specification](https://openid.net/specs/openid-connect-4-verifiable-credential-issuance-1_0.html) might be superceded by a registry in the future.

# Metadata {#metadata}

This specification introduces additional metadata to enable RP and OP to determine the verifiable presentation and verifiable credential formats, proof types and algorithms to be used in a protocol exchange. 

## RP Metadata

This specification defines new client metadata parameters according to [@!OpenID.Registration].

### VP Formats

RPs indicate the supported VP formats using the new parameter `vp_formats`.

* `vp_formats`: REQUIRED. An object defining the formats, proof types and algorithms of verifiable presentations and verifiable credentials that a RP supports. Valid values are defined in the table in Section 6.7.3. of [OpenID for Credential Issuance Specification](https://openid.net/specs/openid-connect-4-verifiable-credential-issuance-1_0.html) and include `jwt_vp` and `ldp_vp`. Formats identifiers not in the table may be supported. 

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

# Examples {#alternative_credential_formats}

OpenID for Verifiable Presentations is credential format agnostic, i.e. it is designed to allow applications to request and receive verifiable presentations and credentials in any format, not limited to the formats defined in [@!VC_DATA]. This section aims to illustrate this with examples utilizing different credential formats. Customization of OpenID for Verifiable Presentation for credential formats other than those defined in [@!VC_DATA] uses extensions points of Presentation Exchange [@!DIF.PresentationExchange]. 

## JWT VCs

### Example Credential

The following is an JWT-based Verifiable Credential that will be used through this section.

<{{examples/credentials/jwt_vc.json}}

### Presentation Request

This is an example presentation request. 

<{{examples/request/request.txt}}

The requirements regarding the credential to be presented are conveyed in the `presentation_definition` parameter. It's content is is given in the following example.

<{{examples/request/pd_jwt_vc.json}}

It contains a single `input_descriptor`, which sets the desired format to JWT VC and defines a constraint over the `vc.type` element to select credentials of type `IDCredential`. 

### Presentation Response

An example presentation response look like this:

<{{examples/response/response.txt}}

The content of the `presentation_submission` is given in the following: 

<{{examples/response/ps_jwt_vc.json}}

It refers to the VP in the `vp_token` parameter provided in the same response, which looks as follows.

<{{examples/response/jwt_vp.json}}

Note: the VP's `nonce` claim contains the value of the `nonce` of the presentation request and the `aud` claims contains the client id of the verifier. This allows the verifier to detect replay of a presentation as recommened in (#preventing-replay). 

## LDP VCs

The following is an LDP-based Verifiable Credential that will be used through this section.

<{{examples/credentials/ldp_vc.json}}

### Presentation Request

This is an example presentation request. 

<{{examples/request/request.txt}}

The requirements regarding the credential to be presented are conveyed in the `presentation_definition` parameter. It's content is is given in the following example.

<{{examples/request/pd_ldp_vc.json}}

It contains a single `input_descriptor`, which sets the desired format to LDP VC and defines a constraint over the `type` element to select credentials of type `IDCardCredential`. 

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

To be able to request AnonCreds, there needs to be a set of identifiers for credentials, presentations ("proofs" in Indy terminology) and crypto schemes. For the purpose of this example, the following identifiers are used: 

* `ac_vc`: designates a credential in AnonCreds format. 
* `ac_vp`: designates a presentation in AnonCreds format.
* `CLSignature2019`: identifies the CL-signature scheme used in conjunction with AnonCreds.

### Example Credential

The following is an example AnonCred credential that will be used through this section. 

<{{examples/credentials/ac_vc.json}}

The most important parts for the purpose of this example are `scheme_id` element and `values` element that contains the actual End-user claims. 

### Presentation Request 

#### Request Example

The example presentation request looks as follows:

<{{examples/request/request.txt}}

The following is the content of the `presentation_definition` parameter.

<{{examples/request/pd_ac_vc.json}}

The `format` object of the `input_descriptor` uses the format identifier `ac_vc` as defined above and sets the `proof_type` to `CLSignature2019` to denote this descriptor requires a credential in AnonCreds format signed with a CL signature (Camenisch-Lysyanskaya siganture). The rest of the expressions operate on the AnonCreds JSON structure.

The `constraints` object requires the selected credential to conform with the schema definition `did:indy:idu:test:3QowxFtwciWceMFr7WbwnM:2:BasicScheme:0\\.1`, which is denoted as a constraint over the AnonCred's `schema_id` element. 

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

To request an ISO/IEC 18013-5:2021 mDL, following identifiers for credentials are used for the purposes of this example:

* `mdl_iso_cbor`: designates a mobile driving licence (mDL) credential encoded as CBOR, expressed using a data model and data sets defined in [@ISO.18013-5].
* `mdl_iso_json`: designates a mobile driving licence (mDL) credential encoded as JSON, expressed using a data model and data sets defined in [@ISO.18013-5].

### Presentation Request 

The presentation request looks the same as for the other examples since the difference is in the content of the `presentation_definition` parameter. 

<{{examples/request/request.txt}}

The content of the `presentation_definition` parameter is as follows:

<{{examples/request/pd_mdl_iso_cbor.json}}

To start with, the `format` element of the `input_descriptor` is set to `mdl_iso_cbor`, i.e. it requests presentation of a mDL in CBOR format. 

To request user claims in ISO/IEC 18013-5:2021 mDL, a `doctype` and `namespace` of the claim needs to be specified. Moreover, the verifiers needs to indicate whether it intends to retain obtained user claims or not, using `intent_to_retain` property.

Note: `intent_to_retain` is a property introduced in this example to meet requirements of [@ISO.18013-5].

Setting `limit_disclosure` property defined in [@!DIF.PresentationExchange] to `required` enables selective release by instructing the wallet to submit only the data elements specified in the fields array. Selective release of claims is a requirement built into an ISO/IEC 18013-5:2021 mDL data model.

### Presentation Response

The presentation response looks the same as for the other examples.

<{{examples/response/response.txt}}

The following shows the `presentation_submission` content:

<{{examples/response/ps_mdl_iso_cbor.json}}

The `descriptor_map` refers to the input descriptor `mDL` and tells the verifier that there is an ISO/IEC 18013-5:2021 mDL (`format` is `mdl_iso_cbor`) in CBOR encoding directly in the `vp_token` (path is the root designated by `$`). 

When ISO/IEC 18013-5:2021 mDL is expressed in CBOR the `nested_path` element cannot be used to point to the location of the requested claims. The user claims will always be included in the `issuerSigned` item. `nested_path` parameter can be used, however, when a JSON-encoded ISO/IEC 18013-5:2021 mDL is returned.

The following is a non-normative example of an ISO/IEC 18013-5:2021 mDL encoded as CBOR in diagnostic notation (line wraps within values are for display purposes only) as conveyed in the `vp_token`parameter.

TBD: shouldn't the vp_token parameter be base64url encoded?

<{{examples/response/mdl_iso_cbor.json}}

In the `deviceSigned` item, `deviceAuth` item includes a signature by the deviceKey the belongs to the End-User. It is used to prove legitimate possession of the crdential, since the Issuer has signed over the deviceKey during the issuance of the credential. Note that deviceKey does not have to be HW-bound.

In the `issueSigned` item, `issuerAuth` item includes Issuer's signature over the hashes of the user claims, and `namespaces` items include user claims within each namespace that the End-User agreed to reveal to the verifier in that transaction.

Note that user claims in the `deviceSigned` item correspond to self-attested claims inside a Self-Issued ID Token (none in the example below), and user claims in the `issuerSigned` item correspond to the user claims included in a VP Token signed by a trusted third party.

Note that the reason why hashes of the user claims are included in the `issuerAuth` item lies in the selective release mechanism. Selective release of the user claims in an ISO/IEC 18013-5:2021 mDL is performed by the Issuer signing over the hashes of all the user claims during the issuance, and only the actual values of the claims that the End-User has agreed to reveal to teh Verifier being included during the presentation. 

The example in this section is also applicable to the electronic identification credentials expressed using data models defined in ISO/IEC TR 23220-2.

TBD: are `nonce` and `client_id` included into the mDL to detect replay?

## SIOP & OpenID 4 VPs

This section shows how SIOP and OpenID 4 Verifiable Presentations can be combined to present credentials and pseudonymously authenticate an end-user using subject controlled key material.

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

* `response_type` is set to `id_token`. If the request also includes a `presentation_definition` parameter, the wallet is supposed to return the `presentation_submission` and `vp_token` parameters in the same response as the `id_token` parameter. 
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

Note: the `nonce` and `aud` are set to the `nonce` of the request and the client id of the verifier, respectively, in the same way as for the verifier presentations to prevent replay. 

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

   * added `presentation_definition` as sub element of `verifiable_presentation` and VP Token

   -01

   * adopted DIF Presentation Exchange request syntax
   * added security considerations regarding replay detection for verifiable credentials

   -00 

   *  initial revision
