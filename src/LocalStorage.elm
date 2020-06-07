port module LocalStorage exposing (..)

import Array exposing (Array)
import Browser
import Common exposing (..)
import Html exposing (Html, div, text)
import Html.Events exposing (onClick)
import Json.Decode as D
import Json.Encode as E
import Menu as M



-- MAIN


main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


port queryLocalStorage : () -> Cmd msg


port receiveLocalStorage : (String -> msg) -> Sub msg


port saveLocalStorage : String -> Cmd msg



-- MODEL


type alias DefaultMenuOptions =
    M.Model


type alias PlayHistory =
    Array PlayData


type alias PlayData =
    { gameSettings : GameSettings, playResult : PlayResult }


type alias PlayResult =
    { userSeq : Array (Maybe Int), startDate : Int }


type alias LocalStorageData =
    { defaultMenuOptions : DefaultMenuOptions, playHistory : PlayHistory }


type alias Model =
    LocalStorageData


init : () -> ( Model, Cmd Msg )
init _ =
    ( { defaultMenuOptions = M.defaultModel, playHistory = Array.empty }
    , queryLocalStorage ()
    )


type Msg
    = LoadData Model
    | SaveData Model


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LoadData newModel ->
            ( newModel, Cmd.none )

        SaveData newModel ->
            ( newModel, saveLocalStorage (E.encode 0 (encodeLocalStorageData model)) )


encodeDefaultMenuOptions : DefaultMenuOptions -> E.Value
encodeDefaultMenuOptions defaultMenuOptions =
    E.object
        [ ( "degreeRange", E.int defaultMenuOptions.degreeRange )
        , ( "tempo", E.int defaultMenuOptions.tempo )
        , ( "length", E.int defaultMenuOptions.length )
        , ( "key", E.object [ ( "noteOffset", E.int defaultMenuOptions.key.noteOffset ), ( "name", E.string defaultMenuOptions.key.name ) ] )
        , ( "scale", E.object [ ( "name", E.string defaultMenuOptions.scale.name ), ( "constitution", E.list (\{ interval, name } -> E.object [ ( "interval", E.int interval ), ( "name", E.string name ) ]) defaultMenuOptions.scale.constitution ) ] )
        , ( "pitchRange", E.string (M.pitchRangeToString defaultMenuOptions.pitchRange) )
        ]


encodePlayHistory : PlayHistory -> E.Value
encodePlayHistory playHistory =
    let
        encodePlayData : PlayData -> E.Value
        encodePlayData playData =
            E.object
                [ ( "gameSettings", encodeGameSettings playData.gameSettings )
                , ( "playResult", encodePlayResult playData.playResult )
                ]

        encodeGameSettings : GameSettings -> E.Value
        encodeGameSettings gameSettings =
            E.object
                [ ( "rootNote", E.int gameSettings.rootNote )
                , ( "degreeRange", E.int gameSettings.degreeRange )
                , ( "tempo", E.int gameSettings.tempo )
                , ( "scale", E.object [ ( "name", E.string gameSettings.scale.name ), ( "constitution", E.list (\{ interval, name } -> E.object [ ( "interval", E.int interval ), ( "name", E.string name ) ]) gameSettings.scale.constitution ) ] )
                , ( "playSeq", E.list E.int gameSettings.playSeq )
                ]

        encodePlayResult : PlayResult -> E.Value
        encodePlayResult playResult =
            E.object
                [ ( "userSeq"
                  , E.array
                        (\maybeInt ->
                            case maybeInt of
                                Just int ->
                                    E.int int

                                Nothing ->
                                    E.null
                        )
                        playResult.userSeq
                  )
                , ( "startDate", E.int playResult.startDate )
                ]
    in
    E.array encodePlayData playHistory


encodeLocalStorageData : Model -> E.Value
encodeLocalStorageData model =
    let
        encodedDefaultMenuOptions =
            encodeDefaultMenuOptions model.defaultMenuOptions

        encodedPlayHistory =
            encodePlayHistory model.playHistory
    in
    E.object
        [ ( "defaultMenuOptions", encodedDefaultMenuOptions )
        , ( "playHistory", encodedPlayHistory )
        ]



-- SUBSCRIPTIONS


decodeDefaultMenuOptionsValue : D.Value -> DefaultMenuOptions
decodeDefaultMenuOptionsValue defaultMenuOptionsValue =
    let
        degreeRange : Int
        degreeRange =
            case D.decodeValue (D.field "degreeRange" D.int) defaultMenuOptionsValue of
                Ok d ->
                    d

                Err _ ->
                    M.defaultModel.degreeRange

        tempo =
            case D.decodeValue (D.field "tempo" D.int) defaultMenuOptionsValue of
                Ok t ->
                    t

                Err _ ->
                    M.defaultModel.tempo

        length =
            case D.decodeValue (D.field "length" D.int) defaultMenuOptionsValue of
                Ok l ->
                    l

                Err _ ->
                    M.defaultModel.length

        keyDecoder : D.Decoder Key
        keyDecoder =
            D.map2 Key
                (D.field "noteOffset" D.int)
                (D.field "name" D.string)

        key =
            case D.decodeValue (D.field "key" keyDecoder) defaultMenuOptionsValue of
                Ok k ->
                    if List.member k keys then
                        k

                    else
                        M.defaultModel.key

                Err _ ->
                    M.defaultModel.key

        scaleConstitutionDecoder : D.Decoder (List ScaleNote)
        scaleConstitutionDecoder =
            D.list (D.map2 ScaleNote (D.field "interval" D.int) (D.field "name" D.string))

        scale : Scale
        scale =
            let
                resultScaleConstitution =
                    D.decodeValue (D.field "scaleConstitution" scaleConstitutionDecoder) defaultMenuOptionsValue
            in
            case resultScaleConstitution of
                Ok scaleConstitution ->
                    case List.head (List.filter (\x -> x.constitution == scaleConstitution) scales) of
                        Just sc ->
                            sc

                        Nothing ->
                            M.defaultModel.scale

                Err _ ->
                    M.defaultModel.scale

        pitchRange =
            case D.decodeValue (D.field "pitchRange" D.string) defaultMenuOptionsValue of
                Ok p ->
                    case M.stringToPitchRange p of
                        Just pr ->
                            pr

                        Nothing ->
                            M.defaultModel.pitchRange

                Err _ ->
                    M.defaultModel.pitchRange
    in
    { degreeRange = degreeRange, tempo = tempo, length = length, key = key, scale = scale, pitchRange = pitchRange }


decodePlayHistoryValue : List D.Value -> PlayHistory
decodePlayHistoryValue playHistoryValue =
    let
        userSeqDecoder : D.Decoder (Array (Maybe Int))
        userSeqDecoder =
            D.array (D.maybe D.int)

        playResultDecoder : D.Decoder PlayResult
        playResultDecoder =
            D.map2 PlayResult
                (D.field "userSeq" userSeqDecoder)
                (D.field "startDate" D.int)

        scaleDecoder : D.Decoder Scale
        scaleDecoder =
            D.map2 Scale
                (D.field "name" D.string)
                (D.field "constitution" (D.list (D.map2 ScaleNote (D.field "interval" D.int) (D.field "name" D.string))))

        gameSettingsDecoder : D.Decoder GameSettings
        gameSettingsDecoder =
            D.map5 GameSettings
                (D.field "rootNote" D.int)
                (D.field "degreeRange" D.int)
                (D.field "tempo" D.int)
                (D.field "scale" scaleDecoder)
                (D.field "playSeq" (D.list D.int))

        playDataDecoder =
            D.map2 PlayData (D.field "gameSettings" gameSettingsDecoder) (D.field "playResult" playResultDecoder)

        playHistoryValueDecoded : List (Result D.Error PlayData)
        playHistoryValueDecoded =
            List.map (D.decodeValue playDataDecoder) playHistoryValue

        playHistoryValidElements : List PlayData
        playHistoryValidElements =
            List.filterMap Result.toMaybe playHistoryValueDecoded
    in
    Array.fromList playHistoryValidElements


handleReceivedLocalStorage : String -> Msg
handleReceivedLocalStorage loadedModelStr =
    let
        resultModelValue : Result D.Error D.Value
        resultModelValue =
            D.decodeString D.value loadedModelStr

        resultDefaultMenuOptionsValue : Result D.Error D.Value
        resultDefaultMenuOptionsValue =
            case resultModelValue of
                Ok modelValue ->
                    D.decodeValue (D.field "defaultMenuOptions" D.value) modelValue

                Err x ->
                    Err x

        defaultMenuOptions : DefaultMenuOptions
        defaultMenuOptions =
            case resultDefaultMenuOptionsValue of
                Err _ ->
                    M.defaultModel

                Ok defaultMenuOptionsValue ->
                    decodeDefaultMenuOptionsValue defaultMenuOptionsValue

        resultPlayHistoryValue : Result D.Error (List D.Value)
        resultPlayHistoryValue =
            case resultModelValue of
                Ok modelValue ->
                    D.decodeValue (D.field "playHistory" (D.list D.value)) modelValue

                Err x ->
                    Err x

        playHistory : PlayHistory
        playHistory =
            case resultPlayHistoryValue of
                Err _ ->
                    Array.empty

                Ok playHistoryValue ->
                    decodePlayHistoryValue playHistoryValue
    in
    LoadData { defaultMenuOptions = defaultMenuOptions, playHistory = playHistory }


subscriptions : Model -> Sub Msg
subscriptions model =
    receiveLocalStorage handleReceivedLocalStorage



-- VIEW


view : Model -> Html Msg
view model =
    div [ onClick (SaveData model) ] [ text "Recording" ]
