module Play exposing (..)

import Array exposing (Array)
import Browser
import Browser.Events
import Common exposing (..)
import Html exposing (Html, button, div, text)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json
import Keyboard.Event exposing (KeyboardEvent, decodeKeyboardEvent)
import Prepare exposing (playAudio)
import Task
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


intervalTime : Int -> Float
intervalTime tempo =
    1000 * 60 / toFloat tempo


startPlay : Cmd Msg
startPlay =
    Task.perform StartPlay Time.now


type alias Model =
    { gameSettings : GameSettings
    , startTime : Maybe Time.Posix
    , userSeq : Array (Maybe Int)
    , nowPlaying : Maybe Int
    , nowUser : Maybe Int
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { gameSettings = sampleGameSettings
      , startTime = Nothing
      , userSeq = Array.repeat (List.length sampleGameSettings.playSeq) Nothing
      , nowPlaying = Nothing
      , nowUser = Nothing
      }
    , startPlay
    )



-- UPDATE


type alias Note =
    Int


type Msg
    = StartPlay Time.Posix
    | PlayNote Note
    | ToScorePage
    | UserInput Note
    | RecordUserInput Note Time.Posix
    | DoNothing


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        StartPlay now ->
            ( { model | startTime = Just now }, Cmd.none )

        PlayNote note ->
            ( { model | nowPlaying = Just note, nowUser = Nothing }, playAudio note )

        ToScorePage ->
            ( model, Cmd.none )

        UserInput note ->
            if note < model.gameSettings.degreeRange then
                ( model, Task.perform (RecordUserInput note) Time.now )

            else
                ( model, Cmd.none )

        RecordUserInput note now ->
            case model.startTime of
                Nothing ->
                    ( model, Cmd.none )

                Just startTime ->
                    let
                        previousPlayIdx =
                            floor (toFloat (Time.posixToMillis now - Time.posixToMillis startTime) / intervalTime model.gameSettings.tempo) - 1
                    in
                    ( { model | userSeq = Array.set previousPlayIdx (Just note) model.userSeq, nowUser = Just note }, Cmd.none )

        DoNothing ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


keys : List String
keys =
    [ "a", "s", "d", "f", "j", "k", "l" ]


findRange : a -> Array a -> Int -> Int -> Maybe Int
findRange target array begin end =
    case Array.get begin array of
        Nothing ->
            Nothing

        Just x ->
            if x == target then
                Just begin

            else
                findRange target array (begin + 1) end


find : a -> Array a -> Maybe Int
find target array =
    findRange target array 0 (Array.length array)


keyToMsg : KeyboardEvent -> Msg
keyToMsg event =
    case event.key of
        Nothing ->
            DoNothing

        Just str ->
            case find str (Array.fromList keys) of
                Nothing ->
                    DoNothing

                Just i ->
                    UserInput i


timeToMsg : Model -> Time.Posix -> Msg
timeToMsg model now =
    case model.startTime of
        Nothing ->
            DoNothing

        Just startTime ->
            let
                playIdx =
                    round
                        (toFloat (Time.posixToMillis now - Time.posixToMillis startTime)
                            / intervalTime model.gameSettings.tempo
                        )
                        - 1

                playLength =
                    List.length model.gameSettings.playSeq
            in
            if playIdx >= playLength then
                ToScorePage

            else
                case Array.get playIdx (Array.fromList model.gameSettings.playSeq) of
                    Nothing ->
                        DoNothing

                    Just idx ->
                        PlayNote idx


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Time.every (intervalTime model.gameSettings.tempo) (timeToMsg model)
        , Browser.Events.onKeyDown (Json.map keyToMsg decodeKeyboardEvent)
        ]



-- VIEW


noteNameKeyPairs : Scale -> List ( String, String )
noteNameKeyPairs scale =
    List.map2 Tuple.pair (List.map (\x -> x.name) scale.constitution) (List.map String.toUpper keys)


view : Model -> Html Msg
view model =
    let
        buttonStyle : Int -> String
        buttonStyle idx =
            case model.nowUser of
                Nothing ->
                    "button is-medium is-fullwidth is-primary"

                Just user ->
                    case model.nowPlaying of
                        Nothing ->
                            "button is-medium is-fullwidth is-light"

                        Just playing ->
                            if idx == playing && idx == user then
                                "button is-medium is-fullwidth is-success"

                            else if idx == playing && idx /= user then
                                "button is-medium is-fullwidth is-info"

                            else if idx /= playing && idx == user then
                                "button is-medium is-fullwidth is-danger"

                            else
                                "button is-medium is-fullwidth is-light"
    in
    div [ class "columns" ]
        (List.indexedMap
            (\idx ( name, key ) -> div [ class "column has-text-centered" ] [ div [ onClick (UserInput idx), class (buttonStyle idx) ] [ text (name ++ " (" ++ key ++ ")") ] ])
            (List.take model.gameSettings.degreeRange (noteNameKeyPairs model.gameSettings.scale))
        )
