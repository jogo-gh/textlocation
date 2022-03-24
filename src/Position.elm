module Position exposing (Position, PositionStatus(..), positionStatusDecoder, positionStatusEncoder)

import Json.Decode as D
import Json.Encode as E


type alias Position =
    { latitude : Float
    , longitude : Float
    , accuracy : Float
    }


type PositionStatus
    = ValidPosition Position
    | PermissionDenied
    | PositionUnavailable
    | Timeout
    | None


positionStatusEncoder : PositionStatus -> E.Value
positionStatusEncoder a =
    case a of
        PermissionDenied ->
            E.object [ ( "error", E.string "permission_denied" ) ]

        PositionUnavailable ->
            E.object [ ( "error", E.string "position_unavailable" ) ]

        Timeout ->
            E.object [ ( "error", E.string "timeout" ) ]

        None ->
            E.object [ ( "error", E.string "unknown" ) ]

        ValidPosition pos ->
            E.object
                [ ( "latitude", E.float pos.latitude )
                , ( "longitude", E.float pos.longitude )
                , ( "accuracy", E.float pos.accuracy )
                ]


positionStatusDecoder : D.Decoder PositionStatus
positionStatusDecoder =
    D.field "error" D.string
        |> D.andThen decoderHelper


decoderHelper : String -> D.Decoder PositionStatus
decoderHelper errorString =
    case errorString of
        "permission_denied" ->
            D.succeed PermissionDenied

        "position_unavailable" ->
            D.succeed PositionUnavailable

        "timeout" ->
            D.succeed Timeout

        _ ->
            positionDecoder


positionDecoder : D.Decoder PositionStatus
positionDecoder =
    D.map3 position
        (D.field "latitude" D.float)
        (D.field "longitude" D.float)
        (D.field "accuracy" D.float)


position : Float -> Float -> Float -> PositionStatus
position lat lon acc =
    ValidPosition { latitude = lat, longitude = lon, accuracy = acc }
