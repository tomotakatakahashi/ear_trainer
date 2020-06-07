port module LoadAudio exposing (..)

import Browser
import Common exposing (..)
import Html exposing (Html, div, text)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Time



-- MAIN


main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- MODEL


type alias Model =
    GameSettings

port loadAudio : List String -> Cmd msg


port queryLoadState : () -> Cmd msg


port receiveLoadState : (List String -> msg) -> Sub msg


mp3Path : Int -> String
mp3Path note =
    "mp3/" ++ String.fromInt note ++ ".mp3"


scaleNotes : GameSettings -> List Int
scaleNotes gameSettings =
    let
        rootNote =
            gameSettings.rootNote

        intervals =
            List.map (\x -> x.interval) gameSettings.scale.constitution
    in
    List.map (\interval -> rootNote + interval) intervals


scaleNotePaths : GameSettings -> List String
scaleNotePaths gameSettings =
    List.map mp3Path (scaleNotes gameSettings)


init : () -> ( Model, Cmd Msg )
init _ =
    ( sampleGameSettings
    , loadAudio (scaleNotePaths sampleGameSettings)
    )



-- UPDATE


type Msg
    = Tick Time.Posix
    | DoNothing
    | ToPreparePage


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Tick _ ->
            ( model, queryLoadState () )

        ToPreparePage ->
            ( model, Cmd.none )

        DoNothing ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


handleLoadState : List String -> Msg
handleLoadState loadState =
    if List.all (\x -> x == "loaded") loadState then
        ToPreparePage

    else
        DoNothing


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch [ receiveLoadState handleLoadState, Time.every 50 Tick ]



-- VIEW


view : Model -> Html Msg
view model =
    div [] [ text "Loading" ]
