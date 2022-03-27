module Session exposing (..)

import Browser.Navigation as Nav
import Contact exposing (Contact)
import GeoLocationPermission exposing (GeoLocationPermission)
import Html exposing (sub)
import Position exposing (PositionStatus)
import Random exposing (Seed)


type ContactStatus
    = Loading
    | Loaded (List Contact)
    | Errored String
    | Empty


type alias Data =
    { contactStatus : ContactStatus
    , key : Nav.Key
    , currentSeed : Seed
    , positionStatus : PositionStatus
    , geoLocationPermission : GeoLocationPermission
    }


empty : Nav.Key -> Seed -> Data
empty key seed =
    Data Empty key seed Position.None GeoLocationPermission.Unknown


getContacts : Data -> List Contact
getContacts data =
    case data.contactStatus of
        Loaded contacts ->
            contacts

        _ ->
            []


getContactById : Data -> String -> Maybe Contact
getContactById data id =
    case data.contactStatus of
        Loaded contacts ->
            List.head <| List.filter (\contact -> contact.id == id) contacts

        _ ->
            Nothing


setContactStatus : ContactStatus -> Data -> Data
setContactStatus status data =
    { data | contactStatus = status }


setPositionStatus : PositionStatus -> Data -> Data
setPositionStatus status data =
    { data | positionStatus = status }


setGeoLocationPermission : GeoLocationPermission -> Data -> Data
setGeoLocationPermission permission data =
    { data | geoLocationPermission = permission }


setSeed : Seed -> Data -> Data
setSeed seed data =
    { data | currentSeed = seed }


getKey : Data -> Nav.Key
getKey data =
    data.key
