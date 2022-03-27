module GeoLocationPermission exposing (..)

import Json.Decode as D
import Json.Encode as E


type GeoLocationPermission
    = Granted
    | Prompt
    | Denied
    | Unknown


permissionEncoder : GeoLocationPermission -> E.Value
permissionEncoder a =
    case a of
        Granted ->
            E.object [ ( "permission", E.string "granted" ) ]

        Prompt ->
            E.object [ ( "permission", E.string "prompt" ) ]

        Denied ->
            E.object [ ( "permission", E.string "denied" ) ]

        Unknown ->
            E.object [ ( "permission", E.string "denied" ) ]


permissionDecoder : D.Decoder GeoLocationPermission
permissionDecoder =
    D.field "permission" D.string
        |> D.andThen decoderHelper


decoderHelper : String -> D.Decoder GeoLocationPermission
decoderHelper permission =
    case permission of
        "granted" ->
            D.succeed Granted

        "denied" ->
            D.succeed Denied

        "prompt" ->
            D.succeed Prompt

        _ ->
            D.succeed Unknown
