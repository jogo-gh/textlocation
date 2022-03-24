module Overview exposing (..)

import Contact exposing (Contact)
import DateFormat
import Html exposing (Html, hr, p, text)
import Html.Attributes exposing (alt, src, style)
import Http
import Material.Button as Button
import Material.Card as Card
import Material.Dialog as Dialog
import Material.Fab as Fab
import Material.IconButton as IconButton
import Material.LayoutGrid as LayoutGrid
import Material.List.Item as ListItem
import Material.Menu as Menu
import Material.TopAppBar as TopAppBar
import Material.Typography as Typography
import OutsideInfo exposing (InfoForElm(..), getInfoFromOutside)
import Route
import Session
import Task
import Time
import Time.Extra


type TimeStatus
    = NoTime
    | Time Time.Posix


type alias Model =
    { session : Session.Data
    , contactToDelete : Maybe Contact
    , menuIsOpen : Bool
    , showAboutDialog : Bool
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
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OutsideData data ->
            case data of
                ContactsChanged contacts ->
                    handleContactsFromOutside model contacts

                PositionUpdated positionUpdate ->
                    ( { model | session = Session.setPositionStatus model.session positionUpdate }, Cmd.none )

        CreateNewContact ->
            ( model, Route.pushUrl model.session.key Route.NewContact )

        ContactDeleteCanceled _ ->
            ( { model | contactToDelete = Nothing }, Cmd.none )

        DeleteContact chore ->
            ( { model | contactToDelete = Nothing }, deleteContact chore )

        DeleteContactClicked chore ->
            ( { model | contactToDelete = Just chore }, Cmd.none )

        SendMessageToContact _ ->
            ( model, Cmd.none )

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

        NoOp ->
            ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch [ getInfoFromOutside OutsideData (\_ -> NoOp) ]


view : Model -> Html Msg
view model =
    case model.session.contactStatus of
        Session.Loaded contacts ->
            Html.div []
                [ topAppBar model
                , contactsView model contacts
                , Html.div [ style "margin-top" "60px" ] []
                , fab
                , showAboutDialog model
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


handleContactsFromOutside : Model -> List Contact -> ( Model, Cmd Msg )
handleContactsFromOutside model contactsResult =
    ( { model | session = Session.setContactStatus model.session <| Session.Loaded contactsResult }, Cmd.none )


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
        { title = "Informationen"
        , content =
            [ text "Mach's Einfach: Eine einfach zu bedienende Webapp für wiederkehrende Aufgaben."
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
    }


getAllContacts : Cmd Msg
getAllContacts =
    OutsideInfo.sendInfoOutside OutsideInfo.GetAllContacts


httpGetJSON : { url : String, expect : Http.Expect msg } -> Cmd msg
httpGetJSON params =
    let
        headers =
            [ Http.header "Accept" "application/json" ]
    in
    Http.request
        { method = "GET"
        , headers = headers
        , url = params.url
        , body = Http.emptyBody
        , expect = params.expect
        , timeout = Nothing
        , tracker = Nothing
        }


deleteContact : Contact -> Cmd Msg
deleteContact contact =
    OutsideInfo.sendInfoOutside <| OutsideInfo.DeleteContact contact