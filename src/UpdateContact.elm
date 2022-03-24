module UpdateContact exposing (..)

import Contact exposing (Contact)
import Html exposing (Html, text)
import Html.Attributes exposing (style)
import Material.Button as Button
import Material.HelperText as HelperText
import Material.LayoutGrid as LayoutGrid
import Material.TextField as TextField
import Material.TopAppBar as TopAppBar
import OutsideInfo
import Overview exposing (Msg(..))
import Route
import Session


type alias Model =
    { session : Session.Data
    , name : String
    , number : String
    , contactToEdit : Contact
    }


type Msg
    = UpdateContactClicked
    | NameChanged String
    | NumberChanged String
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateContactClicked ->
            ( model, Cmd.batch [ updateContact (contactFromModel model), returnToOverview model ] )

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
        , editContactView model
        ]


editContactView : Model -> Html Msg
editContactView model =
    LayoutGrid.layoutGrid [ TopAppBar.fixedAdjust ] [ LayoutGrid.inner [] (contactViewInner model) ]


contactViewInner : Model -> List (Html Msg)
contactViewInner model =
    [ LayoutGrid.cell
        [ LayoutGrid.span12
        , LayoutGrid.span4Phone
        , LayoutGrid.span8Tablet
        ]
        [ Html.div []
            [ nameField model.name
            ]
        ]
    , LayoutGrid.cell
        [ LayoutGrid.span12
        , LayoutGrid.span4Phone
        , LayoutGrid.span8Tablet
        ]
        [ Html.div []
            [ numberField model.number
            ]
        ]
    , LayoutGrid.cell
        [ LayoutGrid.span8
        , LayoutGrid.span4Phone
        , LayoutGrid.span4Tablet
        ]
        [ Html.div []
            [ changeContactButton model ]
        ]
    ]


nameField : String -> Html Msg
nameField value =
    Html.div []
        [ TextField.outlined
            (TextField.config
                |> TextField.setLabel (Just "Name")
                |> TextField.setOnInput NameChanged
                |> TextField.setRequired True
                |> TextField.setValue (Just value)
                |> TextField.setAttributes [ style "width" "100%" ]
            )
        , HelperText.helperLine [] [ HelperText.helperText (HelperText.config |> HelperText.setPersistent True) "Name of the contact. This is cannot be empty.(*)." ]
        ]


numberField : String -> Html Msg
numberField value =
    Html.div []
        [ TextField.outlined
            (TextField.config
                |> TextField.setLabel (Just "Phone Number")
                |> TextField.setOnInput NumberChanged
                |> TextField.setRequired True
                |> TextField.setValue (Just value)
                |> TextField.setAttributes [ style "width" "100%" ]
            )
        , HelperText.helperLine [] [ HelperText.helperText (HelperText.config |> HelperText.setPersistent True) "Phone number of the contact. This is cannot be empty.(*)." ]
        ]


changeContactButton : Model -> Html Msg
changeContactButton model =
    Button.raised
        (Button.config |> Button.setOnClick UpdateContactClicked |> Button.setDisabled (model.name == ""))
        "Update Contact"


topAppBar : Html Msg
topAppBar =
    TopAppBar.regular
        (TopAppBar.config |> TopAppBar.setFixed True)
        [ TopAppBar.section [ TopAppBar.alignStart, TopAppBar.title ]
            [ text "Update Contact"
            ]
        ]


init : Session.Data -> Contact -> ( Model, Cmd Msg )
init session contact =
    ( defaultModel session contact
    , Cmd.none
    )


defaultModel : Session.Data -> Contact -> Model
defaultModel session contact =
    { session = session
    , name = contact.name
    , number = contact.number
    , contactToEdit = contact
    }


updateContact : Contact -> Cmd Msg
updateContact contact =
    OutsideInfo.sendInfoOutside <| OutsideInfo.ModifyContact contact


contactFromModel : Model -> Contact
contactFromModel model =
    let
        contact =
            model.contactToEdit
    in
    { contact | name = model.name, number = model.number }
