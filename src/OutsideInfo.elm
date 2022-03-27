port module OutsideInfo exposing (..)

import Contact exposing (Contact, contactDecoder, contactEncoder)
import GeoLocationPermission exposing (GeoLocationPermission, permissionDecoder)
import Json.Decode exposing (decodeValue, errorToString)
import Json.Encode as E
import Position exposing (Position, PositionStatus, positionStatusDecoder)


sendInfoOutside : InfoForOutside -> Cmd msg
sendInfoOutside info =
    case info of
        CreateContact contact ->
            infoForOutside { tag = "CreateContact", data = contactEncoder contact }

        ModifyContact contact ->
            infoForOutside { tag = "ModifyContact", data = contactEncoder contact }

        DeleteContact contact ->
            infoForOutside { tag = "DeleteContact", data = contactEncoder contact }

        GetAllContacts ->
            infoForOutside { tag = "GetAllContacts", data = E.null }

        OpenURN urn ->
            infoForOutside { tag = "OpenURN", data = E.object [ ( "urn", E.string urn ) ] }


getInfoFromOutside : (InfoForElm -> msg) -> (String -> msg) -> Sub msg
getInfoFromOutside tagger onError =
    infoForElm
        (\outsideInfo ->
            case outsideInfo.tag of
                "ContactsChanged" ->
                    case decodeValue (Json.Decode.list contactDecoder) outsideInfo.data of
                        Ok entries ->
                            tagger <| ContactsChanged entries

                        Err e ->
                            onError (errorToString e)

                "PositionUpdated" ->
                    case decodeValue positionStatusDecoder outsideInfo.data of
                        Ok position ->
                            tagger <| PositionUpdated position

                        Err e ->
                            onError (errorToString e)

                "GeoLocationPermissionChanged" ->
                    case decodeValue permissionDecoder outsideInfo.data of
                        Ok permission ->
                            tagger <| GeoLocationPermissionChanged permission

                        Err e ->
                            onError (errorToString e)

                _ ->
                    onError <| "Unexpected info from outside: tag: " ++ outsideInfo.tag ++ "; data: " ++ E.encode 0 outsideInfo.data
        )


type InfoForOutside
    = CreateContact Contact
    | ModifyContact Contact
    | DeleteContact Contact
    | GetAllContacts
    | OpenURN String


type InfoForElm
    = ContactsChanged (List Contact)
    | PositionUpdated PositionStatus
    | GeoLocationPermissionChanged GeoLocationPermission


type alias GenericOutsideData =
    { tag : String, data : E.Value }


port infoForOutside : GenericOutsideData -> Cmd msg


port infoForElm : (GenericOutsideData -> msg) -> Sub msg
