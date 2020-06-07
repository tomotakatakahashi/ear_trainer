module Score exposing (..)

import Array exposing (Array)
import Browser
import Common exposing (..)
import Html exposing (Html, button, div, p, text)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Time


main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


type alias Model =
    { gameSettings : GameSettings
    , startTime : Time.Posix
    , userSeq : Array (Maybe Int)
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { gameSettings = sampleGameSettings
      , startTime = Time.millisToPosix 0
      , userSeq =
            Array.fromList
                [ Just 0
                , Nothing
                , Just 1
                , Just 2
                , Nothing
                , Just 0
                ]
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = ToMenuPage
    | Retry


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


view : Model -> Html Msg
view model =
    div []
        [ div [] [ text "Result" ]
        , div [ class "columns is-vcentered is-mobile" ] (List.map2 (viewNote model.gameSettings.scale) model.gameSettings.playSeq (Array.toList model.userSeq))
        , div [ class "field is-grouped" ]
            [ div [ class "control" ]
                [ button [ class "button is-primary", onClick ToMenuPage ] [ text "Menu" ]
                ]
            , div [ class "control" ]
                [ button [ class "button is-primary", onClick Retry ] [ text "Retry" ]
                ]
            ]
        ]


listGet : Int -> List a -> Maybe a
listGet idx lst =
    if (idx < 0) || List.isEmpty lst then
        Nothing

    else if idx == 0 then
        case List.head lst of
            Just x ->
                Just x

            Nothing ->
                Nothing

    else
        let
            tail =
                List.tail lst
        in
        case tail of
            Just x ->
                listGet (idx - 1) x

            Nothing ->
                Nothing


viewNote : Scale -> Int -> Maybe Int -> Html Msg
viewNote scale play user =
    let
        playNote =
            listGet play scale.constitution

        playNoteName =
            case playNote of
                Just note ->
                    note.name

                Nothing ->
                    "-"

        userNoteName =
            case user of
                Just u ->
                    let
                        userNote =
                            listGet u scale.constitution
                    in
                    case userNote of
                        Just note ->
                            note.name

                        _ ->
                            "-"

                Nothing ->
                    "-"
    in
    div [ class "column" ]
        (case user of
            Just u ->
                if u == play then
                    [ p [ class "has-text-success" ] [ text playNoteName ] ]

                else
                    [ p [ class "has-text-info" ] [ text playNoteName ], p [ class "has-text-danger" ] [ text userNoteName ] ]

            Nothing ->
                [ p [ class "has-text-info" ] [ text playNoteName ], p [ class "has-text-danger" ] [ text userNoteName ] ]
        )
