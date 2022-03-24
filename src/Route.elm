module Route exposing (Route(..), fromUrl, href, pushUrl, replaceUrl)

import Browser.Navigation as Nav
import Html exposing (Attribute)
import Html.Attributes as Attr
import Url exposing (Url)
import Url.Parser as Parser exposing ((</>), Parser, oneOf, s, string)


subpath : String
subpath =
    "__subpath__"



-- ROUTING


type Route
    = Overview
    | NewContact
    | UpdateContact String


parser : Parser (Route -> a) a
parser =
    s subpath
        </> oneOf
                [ Parser.map Overview Parser.top
                , Parser.map NewContact (s "new")
                , Parser.map UpdateContact (s "update" </> string)
                ]



-- PUBLIC HELPERS


href : Route -> Attribute msg
href targetRoute =
    Attr.href (routeToString targetRoute)


replaceUrl : Nav.Key -> Route -> Cmd msg
replaceUrl key route =
    Nav.replaceUrl key (routeToString route)


pushUrl : Nav.Key -> Route -> Cmd msg
pushUrl key route =
    Nav.pushUrl key (routeToString route)


fromUrl : Url -> Maybe Route
fromUrl =
    Parser.parse parser



-- INTERNAL


routeToString : Route -> String
routeToString page =
    "/" ++ String.join "/" (routeToPieces page)


routeToPieces : Route -> List String
routeToPieces page =
    case page of
        Overview ->
            []

        NewContact ->
            [ "new" ]

        UpdateContact id ->
            [ "update", id ]
