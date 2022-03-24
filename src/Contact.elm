module Contact exposing (..)

import Json.Decode
import Json.Decode.Pipeline
import Json.Encode


type alias Contact =
    { id : String
    , name : String
    , number : String
    }


contactEncoder : Contact -> Json.Encode.Value
contactEncoder a =
    Json.Encode.object
        [ ( "_id", Json.Encode.string a.id )
        , ( "name", Json.Encode.string a.name )
        , ( "number", Json.Encode.string a.number )
        ]


contactDecoder : Json.Decode.Decoder Contact
contactDecoder =
    Json.Decode.succeed Contact
        |> Json.Decode.Pipeline.required "_id" Json.Decode.string
        |> Json.Decode.Pipeline.required "name" Json.Decode.string
        |> Json.Decode.Pipeline.required "number" Json.Decode.string
