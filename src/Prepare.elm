port module Prepare exposing (..)

import Browser
import Browser.Events
import Common exposing (..)
import Html exposing (Html, div, text)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json
import Keyboard.Event exposing (KeyboardEvent, decodeKeyboardEvent)
import Task
import Time


port playAudio : Int -> Cmd msg



-- MAIN


main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- MODEL


intervalTime : Int -> Float
intervalTime tempo =
    1000 * 60 / toFloat tempo


startPrepare : Cmd Msg
startPrepare =
    Task.perform StartPrepare Time.now


type alias Model =
    { gameSettings : GameSettings
    , startTime : Maybe Time.Posix
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { gameSettings = sampleGameSettings
      , startTime = Nothing
      }
    , startPrepare
    )



-- UPDATE


type Msg
    = StartPrepare Time.Posix
    | StartPrepareCmd
    | Tick Time.Posix
    | ToPlayPage
    | DoNothing


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        StartPrepare now ->
            ( { model | startTime = Just now }, Cmd.none )

        StartPrepareCmd ->
            ( model, startPrepare )

        Tick now ->
            case model.startTime of
                Nothing ->
                    ( model, Cmd.none )

                Just startTime ->
                    let
                        playIdx =
                            round
                                (toFloat (Time.posixToMillis now - Time.posixToMillis startTime)
                                    / intervalTime model.gameSettings.tempo
                                )
                                - 1

                        scaleLength =
                            List.length model.gameSettings.scale.constitution
                    in
                    if playIdx < 0 then
                        ( model, Cmd.none )

                    else if playIdx < scaleLength then
                        ( model, playAudio playIdx )

                    else if playIdx == scaleLength then
                        ( model, playAudio 0 )

                    else
                        ( { model | startTime = Nothing }, Cmd.none )

        ToPlayPage ->
            ( model, Cmd.none )

        DoNothing ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


keyboardEventToMsg : KeyboardEvent -> Msg
keyboardEventToMsg event =
    case event.key of
        Just " " ->
            ToPlayPage

        Just "r" ->
            StartPrepareCmd

        _ ->
            DoNothing


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ if model.startTime /= Nothing then
            Time.every (intervalTime model.gameSettings.tempo) Tick

          else
            Sub.none
        , Browser.Events.onKeyDown (Json.map keyboardEventToMsg decodeKeyboardEvent)
        , Browser.Events.onClick (Json.succeed ToPlayPage)
        ]



-- VIEW


view : Model -> Html Msg
view model =
    div [] [ text "Click somewhere or press SPACE to start" ]
