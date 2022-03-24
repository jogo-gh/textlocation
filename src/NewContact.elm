module NewContact exposing (..)

import Contact
import Html exposing (Html, text)
import Html.Attributes exposing (style)
import Http
import Material.Button as Button
import Material.HelperText as HelperText
import Material.LayoutGrid as LayoutGrid
import Material.TextField as TextField
import Material.TopAppBar as TopAppBar
import OutsideInfo exposing (sendInfoOutside)
import Overview exposing (Msg(..))
import Random exposing (step)
import Route
import Session
import Uuid exposing (Uuid)


type alias Model =
    { session : Session.Data
    , name : String
    , number : String
    , currentUUID : Uuid
    }


type Msg
    = CreateContactClicked
    | ContactCreated (Result Http.Error ())
    | NameChanged String
    | NumberChanged String
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        CreateContactClicked ->
            ( model, Cmd.batch [ createNewContact model, returnToOverview model ] )

        ContactCreated _ ->
            ( model, returnToOverview model )

        NoOp ->
            ( model, Cmd.none )

        NameChanged newName ->
            ( { model | name = newName }, Cmd.none )

        NumberChanged newNumber ->
            ( { model | number = newNumber }, Cmd.none )


returnToOverview : Model -> Cmd Msg
returnToOverview model =
    Route.pushUrl model.session.key Route.Overview


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


view : Model -> Html Msg
view model =
    Html.div []
        [ topAppBar
        , newContactView model
        ]


newContactView : Model -> Html Msg
newContactView model =
    LayoutGrid.layoutGrid [ TopAppBar.fixedAdjust ] [ LayoutGrid.inner [] (contactViewInner model) ]


contactViewInner : Model -> List (Html Msg)
contactViewInner model =
    [ LayoutGrid.cell
        [ LayoutGrid.span12
        , LayoutGrid.span4Phone
        , LayoutGrid.span8Tablet
        ]
        [ Html.div []
            [ nameField
            ]
        ]
    , LayoutGrid.cell
        [ LayoutGrid.span12
        , LayoutGrid.span4Phone
        , LayoutGrid.span8Tablet
        ]
        [ Html.div []
            [ numberField ]
        ]
    , LayoutGrid.cell
        [ LayoutGrid.span8
        , LayoutGrid.span4Phone
        , LayoutGrid.span4Tablet
        ]
        [ Html.div []
            [ createContactButton model ]
        ]
    ]


nameField : Html Msg
nameField =
    Html.div []
        [ TextField.outlined
            (TextField.config
                |> TextField.setLabel (Just "Name")
                |> TextField.setOnInput NameChanged
                |> TextField.setRequired True
                |> TextField.setAttributes [ style "width" "100%" ]
            )
        , HelperText.helperLine [] [ HelperText.helperText (HelperText.config |> HelperText.setPersistent True) "Name of the contact. This field is required(*)." ]
        ]


numberField : Html Msg
numberField =
    Html.div []
        [ TextField.outlined
            (TextField.config
                |> TextField.setLabel (Just "Phone Number")
                |> TextField.setOnInput NumberChanged
                |> TextField.setRequired True
                |> TextField.setAttributes [ style "width" "100%" ]
            )
        , HelperText.helperLine [] [ HelperText.helperText (HelperText.config |> HelperText.setPersistent True) "Phone number of the contact. This field is required(*)." ]
        ]


createContactButton : Model -> Html Msg
createContactButton model =
    Html.div []
        [ Button.raised
            (Button.config |> Button.setOnClick CreateContactClicked |> Button.setDisabled (model.name == ""))
            "Create Contact"
        ]


topAppBar : Html Msg
topAppBar =
    TopAppBar.regular
        (TopAppBar.config |> TopAppBar.setFixed True)
        [ TopAppBar.section [ TopAppBar.alignStart, TopAppBar.title ]
            [ text "Create A New Contact"
            ]
        ]


init : Session.Data -> ( Model, Cmd Msg )
init session =
    let
        ( newUuid, newSeed ) =
            step Uuid.uuidGenerator session.currentSeed
    in
    ( defaultModel (Session.setSeed newSeed session) newUuid
    , Cmd.none
    )


defaultModel : Session.Data -> Uuid -> Model
defaultModel session uuid =
    { session = session
    , name = ""
    , number = ""
    , currentUUID = uuid
    }


createNewContact : Model -> Cmd Msg
createNewContact model =
    let
        contact =
            Contact.Contact (Uuid.toString model.currentUUID) model.name model.number
    in
    sendInfoOutside (OutsideInfo.CreateContact contact)
