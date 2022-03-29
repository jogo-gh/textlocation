module Overview exposing (..)

import Contact exposing (Contact)
import GeoLocationPermission exposing (GeoLocationPermission(..))
import Html exposing (Html, hr, p, text)
import Html.Attributes exposing (alt, src, style)
import Material.Button as Button
import Material.Card as Card
import Material.Dialog as Dialog
import Material.Fab as Fab
import Material.IconButton as IconButton
import Material.LayoutGrid as LayoutGrid
import Material.List.Item as ListItem
import Material.Menu as Menu
import Material.Snackbar as Snackbar
import Material.TopAppBar as TopAppBar
import Material.Typography as Typography
import OutsideInfo exposing (InfoForElm(..), getInfoFromOutside)
import Position exposing (PositionStatus(..))
import Route
import Session
import Time
import Url


type TimeStatus
    = NoTime
    | Time Time.Posix


type alias Model =
    { session : Session.Data
    , contactToDelete : Maybe Contact
    , menuIsOpen : Bool
    , showAboutDialog : Bool
    , showNeedsPermissionsDialog : Bool
    , snackbarQueue : Snackbar.Queue Msg
    }


type Msg
    = SendMessageToContact Contact
    | CreateNewContact
    | ContactDeleteCanceled Contact
    | DeleteContact Contact
    | DeleteContactClicked Contact
    | UpdateContactClicked Contact
    | OutsideData InfoForElm
    | MenuOpened
    | MenuClosed
    | ShowAboutDialog
    | CloseAboutDialog
    | CloseNeedsPermissionDialog
    | OutsideDataError String
    | SnackbarClosed Snackbar.MessageId


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OutsideData data ->
            case data of
                ContactsChanged contacts ->
                    handleContactsFromOutside model contacts

                PositionUpdated positionUpdate ->
                    ( { model | session = Session.setPositionStatus positionUpdate model.session }, Cmd.none )

                GeoLocationPermissionChanged permission ->
                    ( { model
                        | session = Session.setGeoLocationPermission permission model.session
                        , showNeedsPermissionsDialog =
                            case ( permission, model.session.positionStatus ) of
                                ( Granted, PermissionDenied ) ->
                                    True

                                ( Granted, _ ) ->
                                    False

                                _ ->
                                    True
                        , snackbarQueue =
                            case ( permission, model.session.positionStatus ) of
                                ( Granted, PermissionDenied ) ->
                                    Snackbar.addMessage (Snackbar.message "Error: No permission to access location.") model.snackbarQueue

                                ( Denied, _ ) ->
                                    Snackbar.addMessage (Snackbar.message "Error: No permission to access location.") model.snackbarQueue

                                _ ->
                                    model.snackbarQueue
                      }
                    , Cmd.none
                    )

        CreateNewContact ->
            ( model, Route.pushUrl model.session.key Route.NewContact )

        ContactDeleteCanceled _ ->
            ( { model | contactToDelete = Nothing }, Cmd.none )

        DeleteContact chore ->
            ( { model | contactToDelete = Nothing }, deleteContact chore )

        DeleteContactClicked chore ->
            ( { model | contactToDelete = Just chore }, Cmd.none )

        SendMessageToContact contact ->
            case ( model.session.geoLocationPermission, model.session.positionStatus ) of
                ( Denied, _ ) ->
                    ( { model | snackbarQueue = Snackbar.addMessage (Snackbar.message "Error: No permission to access location.") model.snackbarQueue }, Cmd.none )

                ( _, PermissionDenied ) ->
                    ( { model | snackbarQueue = Snackbar.addMessage (Snackbar.message "Error: No permission to access location.") model.snackbarQueue }, Cmd.none )

                ( Granted, ValidPosition _ ) ->
                    ( model, OutsideInfo.sendInfoOutside <| OutsideInfo.OpenURN (createPositionSMS contact model.session.positionStatus) )

                _ ->
                    ( { model | snackbarQueue = Snackbar.addMessage (Snackbar.message "Error: No valid position.") model.snackbarQueue }, Cmd.none )

        -- sendMessageToContact model contact
        UpdateContactClicked contact ->
            ( model, Route.pushUrl model.session.key (Route.UpdateContact contact.id) )

        MenuOpened ->
            ( { model | menuIsOpen = True }, Cmd.none )

        MenuClosed ->
            ( { model | menuIsOpen = False }, Cmd.none )

        ShowAboutDialog ->
            ( { model | menuIsOpen = False, showAboutDialog = True }, Cmd.none )

        CloseAboutDialog ->
            ( { model | showAboutDialog = False }, Cmd.none )

        CloseNeedsPermissionDialog ->
            ( { model | showNeedsPermissionsDialog = False }, Cmd.none )

        OutsideDataError _ ->
            ( model, Cmd.none )

        SnackbarClosed messageId ->
            ( { model | snackbarQueue = Snackbar.close messageId model.snackbarQueue }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch [ getInfoFromOutside OutsideData (\error -> OutsideDataError error) ]


view : Model -> Html Msg
view model =
    case model.session.contactStatus of
        Session.Loaded contacts ->
            Html.div
                []
                [ topAppBar model
                , contactsView model contacts
                , Html.div [ style "margin-top" "60px" ] []
                , fab
                , showAboutDialog model
                , showNeedPermissionsDialog model
                , showSnackbar model
                ]

        Session.Loading ->
            Html.div []
                []

        Session.Errored errorString ->
            Html.div []
                [ topAppBar model
                , errorView errorString
                , fab
                ]

        Session.Empty ->
            Html.div []
                []


showSnackbar : Model -> Html Msg
showSnackbar model =
    Snackbar.snackbar (Snackbar.config { onClosed = SnackbarClosed })
        model.snackbarQueue


colorForGeoLocStatus : GeoLocationPermission -> PositionStatus -> List (Html.Attribute msg)
colorForGeoLocStatus geoLocPermission position =
    case ( geoLocPermission, position ) of
        ( GeoLocationPermission.Granted, ValidPosition _ ) ->
            []

        ( _, _ ) ->
            [ style "background-color" "#ff8888" ]


createPositionSMS : Contact -> PositionStatus -> String
createPositionSMS contact positionStatus =
    case positionStatus of
        ValidPosition position ->
            createSMS contact.number (" I am located here " ++ geoURN position)

        _ ->
            createSMS contact.number " No valid position available."


createSMS : String -> String -> String
createSMS number text =
    "sms:" ++ number ++ "?body=" ++ Url.percentEncode text


geoURN : Position.Position -> String
geoURN position =
    "https://www.google.com/maps/search/?api=1&query="
        ++ String.fromFloat position.latitude
        ++ "%2C"
        ++ String.fromFloat position.longitude


handleContactsFromOutside : Model -> List Contact -> ( Model, Cmd Msg )
handleContactsFromOutside model contactsResult =
    ( { model | session = Session.setContactStatus (Session.Loaded contactsResult) model.session }, Cmd.none )


replaceContact : Model -> Contact -> List Contact
replaceContact model contact =
    case model.session.contactStatus of
        Session.Loaded contacts ->
            replaceContactInList contact contacts

        _ ->
            [ contact ]


replaceContactInList : Contact -> List Contact -> List Contact
replaceContactInList contact contacts =
    List.map
        (\inContact ->
            if inContact.id == contact.id then
                contact

            else
                inContact
        )
        contacts


topAppBar : Model -> Html Msg
topAppBar model =
    TopAppBar.regular
        (TopAppBar.config |> TopAppBar.setFixed True)
        [ TopAppBar.row []
            [ TopAppBar.section [ TopAppBar.alignStart, TopAppBar.title ]
                [ text "Text Location"
                ]
            , TopAppBar.section [ TopAppBar.alignEnd ]
                [ Html.div [ Menu.surfaceAnchor ]
                    [ IconButton.iconButton
                        (IconButton.config
                            |> IconButton.setAttributes
                                [ TopAppBar.actionItem ]
                            |> IconButton.setOnClick MenuOpened
                        )
                        (IconButton.icon "more_vert")
                    , menu model
                    ]
                ]
            ]
        ]


menu : Model -> Html Msg
menu model =
    Menu.menu
        (Menu.config
            |> Menu.setOpen model.menuIsOpen
            |> Menu.setOnClose MenuClosed
        )
        (ListItem.listItem (ListItem.config |> ListItem.setOnClick ShowAboutDialog)
            [ text "About" ]
        )
        []


fab : Html Msg
fab =
    Fab.fab
        (Fab.config
            |> Fab.setOnClick CreateNewContact
            |> Fab.setAttributes
                [ style "position" "fixed"
                , style "right" "10px"
                , style "bottom" "10px"
                ]
        )
        (Fab.icon "add")


errorView : String -> Html Msg
errorView errorMsg =
    Html.div [ TopAppBar.fixedAdjust ] [ text "Widget Error: ", text errorMsg ]


contactsView : Model -> List Contact -> Html Msg
contactsView model contacts =
    LayoutGrid.layoutGrid [ TopAppBar.fixedAdjust ] [ LayoutGrid.inner [] (List.map (showContact model) contacts) ]


showDeleteChoreAlert : Contact -> Maybe Contact -> Html Msg
showDeleteChoreAlert contact contactToDelete =
    Dialog.confirmation
        (Dialog.config
            |> Dialog.setOpen
                (case contactToDelete of
                    Just ch ->
                        contact.id == ch.id

                    Nothing ->
                        False
                )
            |> Dialog.setOnClose (ContactDeleteCanceled contact)
        )
        { title = "Delete Contact"
        , content = [ text ("You are about to delete contact \"" ++ contact.name ++ "\". This cannot be undone. Are you sure?") ]
        , actions =
            [ Button.text
                (Button.config
                    |> Button.setOnClick (ContactDeleteCanceled contact)
                    |> Button.setAttributes [ Dialog.defaultAction ]
                )
                "No"
            , Button.text
                (Button.config
                    |> Button.setOnClick (DeleteContact contact)
                )
                "Yes"
            ]
        }


buildVersion : String
buildVersion =
    "__buildVersion__"


showAboutDialog : Model -> Html Msg
showAboutDialog model =
    Dialog.confirmation
        (Dialog.config
            |> Dialog.setOpen model.showAboutDialog
            |> Dialog.setOnClose CloseAboutDialog
        )
        { title = "Information"
        , content =
            [ text "Text My Location: Send my location via SMS to contacts."
            , p [] []
            , text ("Version: " ++ buildVersion)
            ]
        , actions =
            [ Button.text
                (Button.config
                    |> Button.setOnClick CloseAboutDialog
                    |> Button.setAttributes [ Dialog.defaultAction ]
                )
                "OK"
            ]
        }


showNeedPermissionsDialog : Model -> Html Msg
showNeedPermissionsDialog model =
    Dialog.alert
        (Dialog.config
            |> Dialog.setOpen model.showNeedsPermissionsDialog
            |> Dialog.setOnClose CloseAboutDialog
        )
        { content =
            [ text
                ("In order to send your position to one of your contacts, I need the permission to get your position."
                    ++ " I guess this is pretty obvious ;-)"
                )
            ]
        , actions =
            [ Button.text
                (Button.config
                    |> Button.setOnClick CloseNeedsPermissionDialog
                    |> Button.setAttributes [ Dialog.defaultAction ]
                )
                "I understand"
            ]
        }


showContact : Model -> Contact -> Html Msg
showContact model contact =
    LayoutGrid.cell
        [ LayoutGrid.span6
        , LayoutGrid.span4Phone
        , LayoutGrid.span4Tablet
        ]
        [ Card.card
            (Card.config |> Card.setOutlined True)
            { blocks =
                [ Card.block <|
                    Html.div
                        [ style "padding" "1rem"
                        ]
                        [ LayoutGrid.inner []
                            [ LayoutGrid.cell
                                [ LayoutGrid.span4Phone
                                , LayoutGrid.span8Tablet
                                , LayoutGrid.span12Desktop
                                ]
                                [ Html.h2
                                    [ Typography.headline5
                                    , style "margin" "0"
                                    ]
                                    [ text contact.name
                                    ]
                                ]
                            ]
                        ]
                ]
            , actions =
                Just <|
                    Card.actions
                        { buttons = [ Card.button (Button.config |> Button.setOnClick (SendMessageToContact contact)) "Send" ]
                        , icons =
                            [ Card.icon (IconButton.config |> IconButton.setOnClick (UpdateContactClicked contact))
                                (IconButton.icon "edit")
                            , Card.icon (IconButton.config |> IconButton.setOnClick (DeleteContactClicked contact))
                                (IconButton.icon "delete")
                            ]
                        }
            }
        , showDeleteChoreAlert contact model.contactToDelete
        ]


init : Session.Data -> ( Model, Cmd Msg )
init session =
    ( defaultModel session
    , Cmd.batch [ getAllContacts ]
    )


defaultModel : Session.Data -> Model
defaultModel session =
    { session = session
    , contactToDelete = Nothing
    , menuIsOpen = False
    , showAboutDialog = False
    , showNeedsPermissionsDialog = False
    , snackbarQueue = Snackbar.initialQueue
    }


getAllContacts : Cmd Msg
getAllContacts =
    OutsideInfo.sendInfoOutside OutsideInfo.GetAllContacts


deleteContact : Contact -> Cmd Msg
deleteContact contact =
    OutsideInfo.sendInfoOutside <| OutsideInfo.DeleteContact contact


debugPosition : PositionStatus -> String
debugPosition posStat =
    case posStat of
        Position.ValidPosition position ->
            String.fromFloat position.latitude ++ "/" ++ String.fromFloat position.longitude

        PermissionDenied ->
            "PermissionDenied"

        PositionUnavailable ->
            "PositionUnavailable"

        Timeout ->
            "Timeout"

        None ->
            "'None'"
