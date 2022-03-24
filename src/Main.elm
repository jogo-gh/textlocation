module Main exposing (..)

import Browser
import Browser.Navigation as Nav
import Html
import NewContact
import Overview
import Random exposing (initialSeed)
import Route exposing (Route(..))
import Session
import UpdateContact
import Url



-- MAIN


main : Program Int Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = LinkClicked
        , onUrlChange = UrlChanged
        }



-- MODEL


type alias Model =
    { page : Page
    }


type Page
    = NotFound Session.Data
    | Overview Overview.Model
    | NewContact NewContact.Model
    | UpdateContact UpdateContact.Model



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.page of
        Overview overview ->
            Sub.map OverviewMsg (Overview.subscriptions overview)

        NewContact newContact ->
            Sub.map NewContactMsg (NewContact.subscriptions newContact)

        UpdateContact updateContact ->
            Sub.map UpdateContactMsg (UpdateContact.subscriptions updateContact)

        _ ->
            Sub.none



-- VIEW


view : Model -> Browser.Document Msg
view model =
    case model.page of
        NotFound _ ->
            { title = "Not Found"
            , body = []
            }

        Overview overview ->
            { title = "Text My Location"
            , body = [ Html.map OverviewMsg (Overview.view overview) ]
            }

        NewContact newContact ->
            { title = "Text My Location"
            , body = [ Html.map NewContactMsg (NewContact.view newContact) ]
            }

        UpdateContact updateContact ->
            { title = "Text My Location"
            , body = [ Html.map UpdateContactMsg (UpdateContact.view updateContact) ]
            }



-- INIT


init : Int -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init seed url key =
    stepUrl url
        { page = NotFound <| Session.empty key (initialSeed seed) }



-- UPDATE


type Msg
    = NoOp
    | LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | OverviewMsg Overview.Msg
    | NewContactMsg NewContact.Msg
    | UpdateContactMsg UpdateContact.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        NoOp ->
            ( model, Cmd.none )

        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model
                    , Nav.pushUrl (getSessionData model |> Session.getKey) (Url.toString url)
                    )

                Browser.External href ->
                    ( model
                    , Nav.load href
                    )

        UrlChanged url ->
            stepUrl url model

        OverviewMsg msg ->
            case model.page of
                Overview overview ->
                    stepOverview model (Overview.update msg overview)

                _ ->
                    ( model, Cmd.none )

        NewContactMsg msg ->
            case model.page of
                NewContact newContact ->
                    stepNewContact model (NewContact.update msg newContact)

                _ ->
                    ( model, Cmd.none )

        UpdateContactMsg msg ->
            case model.page of
                UpdateContact updateContact ->
                    stepUpdateContact model (UpdateContact.update msg updateContact)

                _ ->
                    ( model, Cmd.none )


stepOverview : Model -> ( Overview.Model, Cmd Overview.Msg ) -> ( Model, Cmd Msg )
stepOverview model ( overview, cmds ) =
    ( { model | page = Overview overview }
    , Cmd.map OverviewMsg cmds
    )


stepNewContact : Model -> ( NewContact.Model, Cmd NewContact.Msg ) -> ( Model, Cmd Msg )
stepNewContact model ( newContact, cmds ) =
    ( { model | page = NewContact newContact }
    , Cmd.map NewContactMsg cmds
    )


stepUpdateContact : Model -> ( UpdateContact.Model, Cmd UpdateContact.Msg ) -> ( Model, Cmd Msg )
stepUpdateContact model ( updateContact, cmds ) =
    ( { model | page = UpdateContact updateContact }
    , Cmd.map UpdateContactMsg cmds
    )



-- EXIT


getSessionData : Model -> Session.Data
getSessionData model =
    case model.page of
        NotFound session ->
            session

        Overview m ->
            m.session

        NewContact m ->
            m.session

        UpdateContact m ->
            m.session



-- ROUTER


stepUrl : Url.Url -> Model -> ( Model, Cmd Msg )
stepUrl url model =
    let
        session =
            getSessionData model
    in
    case Route.fromUrl url of
        Just Route.Overview ->
            stepOverview model <| Overview.init session

        Just Route.NewContact ->
            stepNewContact model <| NewContact.init session

        Just (Route.UpdateContact id) ->
            case Session.getContactById session id of
                Just contact ->
                    stepUpdateContact model <| UpdateContact.init session contact

                Nothing ->
                    ( { model | page = NotFound session }, Cmd.none )

        Nothing ->
            ( { model | page = NotFound session }
            , Cmd.none
            )
