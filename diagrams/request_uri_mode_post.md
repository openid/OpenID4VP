```plantuml
@startuml

autonumber

participant "Wallet" as w

participant "User Agent" as u

participant "Verifier" as r

u --> r : use
activate r

r --> u: authorization request\n(client_id, request_uri, request_uri_method=POST, [client_id_scheme])
deactivate r
u --> w: authorization request\n(client_id, request_uri, request_uri_method=POST, [client_id_scheme])
activate w
w --> r: POST **request_uri** (\n[OPTIONAL]wallet_metadata, \n[OPTIONAL]wallet_nonce)
r -> r: create and sign (and optionally encrypt) request object 
r --> w: **signed (optionally encrypted) request object** (client_id, client_id_scheme, wallet_nonce, nonce, \nresponse_uri, presentation_definition, state)
w -> w: authenticate and\n authorize Verifier

note over u, w: User authentication and Credential selection/confirmation

w -> w: create verifiable\npresentation (credential)
w --> r: POST response \n(vp_token(credential presentation(s) associated with nonce), presentation_submission, state)
r -> r: check state, store vp_token\n & create redirect_url
r --> w: redirect_url
w --> u: redirect (response_code)
u --> r: redirect (response_code)
activate r
r --> r: presentation response
r -> r: validate presentation \n(incl. nonce binding)
r -> r: use presented credential 
@enduml
```