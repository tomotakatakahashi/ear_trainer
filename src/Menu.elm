port module Menu exposing (..)

import Browser
import Common exposing (..)
import Html exposing (Html, button, div, label, option, select, text)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json
import Json.Encode
import Random



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


type alias Model =
    { degreeRange : Int
    , tempo : Int
    , length : Int
    , key : Key
    , scale : Scale
    , pitchRange : PitchRange
    }


defaultModel =
    { degreeRange = 4
    , tempo = 60
    , length = 40
    , key = Key 0 "C"
    , scale = majorScale
    , pitchRange = Mid
    }


type PitchRange
    = Low
    | Mid
    | High


pitchRangeToString : PitchRange -> String
pitchRangeToString pitchRange =
    case pitchRange of
        Low ->
            "Low"

        Mid ->
            "Mid"

        High ->
            "High"


stringToPitchRange : String -> Maybe PitchRange
stringToPitchRange str =
    case str of
        "Low" ->
            Just Low

        "Mid" ->
            Just Mid

        "High" ->
            Just High

        _ ->
            Nothing



{-
   modelEncoder : Model -> Json.Encode.Value
   modelEncoder model =
       Json.Encode.object
           [ ( "degreeRange", Json.Encode.int model.degreeRange)
           , ("tempo", Json.Encode.int model.tempo)
           , ("length", Json.Encode.int model.length)
           , ("key", keyEncoder model.key)
           , ("scaleConstitution", scaleConstitutionEncoder model.scale.constitution)
           , ("pitchRange", Json.Encode.string (pitchRangeToString model.pitchRange))]
-}


init : () -> ( Model, Cmd Msg )
init _ =
    ( defaultModel
    , Cmd.none
    )



-- UPDATE


type Msg
    = ChangeDegreeRange Int
    | ChangeTempo Int
    | ChangeLength Int
    | ChangeKey Key
    | ChangeScale Scale
    | ChangeScaleAndDegreeRange Scale Int
    | ChangePitchRange PitchRange
    | ShuffleKey
    | GeneratePlaySeq Int Int
    | ToLoadPage GameSettings
    | ToErrorPage String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChangeDegreeRange newDegreeRange ->
            ( { model | degreeRange = newDegreeRange }, Cmd.none )

        ChangeTempo newTempo ->
            ( { model | tempo = newTempo }, Cmd.none )

        ChangeLength newLength ->
            ( { model | length = newLength }, Cmd.none )

        ChangeKey newKey ->
            ( { model | key = newKey }, Cmd.none )

        ChangeScale newScale ->
            ( { model | scale = newScale }, Cmd.none )

        ChangeScaleAndDegreeRange newScale newDegreeRange ->
            ( { model | scale = newScale, degreeRange = newDegreeRange }, Cmd.none )

        ChangePitchRange newPitchRange ->
            ( { model | pitchRange = newPitchRange }, Cmd.none )

        ShuffleKey ->
            ( model, Random.generate ChangeKey (Random.uniform (Key 0 "C") (List.drop 1 keys)) )

        GeneratePlaySeq degreeRange length ->
            ( model, Random.generate (generateGameSettings model) (nonConsecutiveIntListGenerator length 0 degreeRange) )

        ToLoadPage gameSettings ->
            ( model, Cmd.none )

        ToErrorPage errorMessage ->
            ( model, Cmd.none )





handleStartButton : Model -> Msg
handleStartButton model =
    let
        degreeRange =
            model.degreeRange

        length =
            model.length

        scale =
            model.scale
    in
    if (2 <= degreeRange) && (degreeRange <= List.length scale.constitution) && (1 < length) && (length <= 500) then
        GeneratePlaySeq degreeRange length

    else
        ToErrorPage "Invalid Parameter(s)"


nonConsecutiveIntListGenerator : Int -> Int -> Int -> Random.Generator (List Int)
nonConsecutiveIntListGenerator length begin end =
    let
        predecessorGenerator =
            Random.list 1 (Random.int 0 (end - 1))

        successorGenerator =
            Random.list (length - 1) (Random.int 0 (end - 2))

        nonConsecutiveIntList : List Int -> List Int -> List Int
        nonConsecutiveIntList predecessor successor =
            case ( predecessor, successor ) of
                ( pHead :: pTail, sHead :: sTail ) ->
                    if pHead == sHead then
                        nonConsecutiveIntList ((pHead + 1) :: predecessor) sTail

                    else
                        nonConsecutiveIntList (sHead :: predecessor) sTail

                ( _, [] ) ->
                    predecessor

                _ ->
                    []
    in
    Random.map2 nonConsecutiveIntList predecessorGenerator successorGenerator


generateGameSettings : Model -> List Int -> Msg
generateGameSettings model playSeq =
    let
        rootNoteBase =
            case model.pitchRange of
                Low ->
                    24

                Mid ->
                    48

                High ->
                    72
    in
    ToLoadPage
        { rootNote = rootNoteBase + model.key.noteOffset
        , degreeRange = model.degreeRange
        , tempo = model.tempo
        , scale = model.scale
        , playSeq = playSeq
        }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ viewSelect "degreeRange" "Range:" (degreeRangeOptions model) [] (handleNewDegreeRange model)
        , viewSelect "tempo" "Tempo:" (tempoOptions model) [] handleNewTempo
        , viewSelect "length" "Length:" (lengthOptions model) [] handleNewLength
        , viewSelect "key" "Key:" (keyOptions model) [ shuffleKeyButton ] handleNewKey
        , viewSelect "scale" "Scale:" (scaleOptions model) [] (handleNewScale model)
        , viewSelect "pitchRange" "Pitch:" (pitchRangeOptions model) [] handleNewPitchRange
        , startButton model
        ]


startButton : Model -> Html Msg
startButton model =
    div [ class "field is-horizontal" ]
        [ div [ class "field-label" ] []
        , div [ class "field-body" ]
            [ div [ class "field" ]
                [ div [ class "control" ]
                    [ button [ class "button is-primary", onClick (handleStartButton model) ] [ text "Start" ]
                    ]
                ]
            ]
        ]


type alias SelectOption =
    { value : String
    , text : String
    }


selectOptionToOptionHtml : String -> SelectOption -> Html Msg
selectOptionToOptionHtml selectedValue so =
    option
        [ value so.value
        , selected
            (if so.value == selectedValue then
                True

             else
                False
            )
        ]
        [ text so.text ]


degreeRangeOptions : Model -> List (Html Msg)
degreeRangeOptions model =
    let
        selectedDegreeRange =
            String.fromInt model.degreeRange

        scaleConstitution =
            model.scale.constitution

        options =
            List.indexedMap (\idx { name, interval } -> SelectOption (String.fromInt (idx + 2)) name) (List.drop 1 scaleConstitution)
    in
    List.map (selectOptionToOptionHtml selectedDegreeRange) options


handleNewDegreeRange : Model -> String -> Msg
handleNewDegreeRange model newDegreeRange =
    let
        scaleLength =
            List.length model.scale.constitution

        maybeNewDegreeRangeInt =
            String.toInt newDegreeRange
    in
    case maybeNewDegreeRangeInt of
        Nothing ->
            ToErrorPage "Invalid Range"

        Just newDegreeRangeInt ->
            if newDegreeRangeInt <= 1 || newDegreeRangeInt > scaleLength then
                ToErrorPage "Invalid Range"

            else
                ChangeDegreeRange newDegreeRangeInt


tempoOptions : Model -> List (Html Msg)
tempoOptions model =
    let
        selectedTempo =
            String.fromInt model.tempo
    in
    List.map (selectOptionToOptionHtml selectedTempo)
        [ SelectOption "40" "40"
        , SelectOption "60" "60"
        , SelectOption "90" "90"
        ]


handleNewTempo : String -> Msg
handleNewTempo newTempo =
    let
        maybeNewTempoInt =
            String.toInt newTempo
    in
    case maybeNewTempoInt of
        Nothing ->
            ToErrorPage "Invalid Tempo"

        Just newTempoInt ->
            if newTempoInt < 10 || newTempoInt > 240 then
                ToErrorPage "Invalid Tempo"

            else
                ChangeTempo newTempoInt


lengthOptions : Model -> List (Html Msg)
lengthOptions model =
    let
        selectedLength =
            String.fromInt model.length
    in
    List.map (selectOptionToOptionHtml selectedLength)
        [ SelectOption "10" "10"
        , SelectOption "40" "40"
        , SelectOption "60" "60"
        , SelectOption "100" "100"
        ]


handleNewLength : String -> Msg
handleNewLength newLength =
    let
        maybeNewLengthInt =
            String.toInt newLength
    in
    case maybeNewLengthInt of
        Nothing ->
            ToErrorPage "Invalid Length"

        Just newLengthInt ->
            if newLengthInt <= 0 || newLengthInt > 1000 then
                ToErrorPage "Invalid Length"

            else
                ChangeLength newLengthInt


handleNewPitchRange : String -> Msg
handleNewPitchRange newPitchRange =
    case newPitchRange of
        "Low" ->
            ChangePitchRange Low

        "Mid" ->
            ChangePitchRange Mid

        "High" ->
            ChangePitchRange High

        _ ->
            ToErrorPage "Invalid Pitch"


pitchRangeOptions : Model -> List (Html Msg)
pitchRangeOptions model =
    let
        selectedPitchRange =
            pitchRangeToString model.pitchRange
    in
    List.map (selectOptionToOptionHtml selectedPitchRange)
        [ SelectOption "Low" "Low"
        , SelectOption "Mid" "Mid"
        , SelectOption "High" "High"
        ]


keyOptions : Model -> List (Html Msg)
keyOptions model =
    let
        selectedKeyOffset =
            String.fromInt model.key.noteOffset
    in
    List.map (selectOptionToOptionHtml selectedKeyOffset)
        (List.map (\{ noteOffset, name } -> SelectOption (String.fromInt noteOffset) name) keys)


noteOffsetToKey : Int -> Maybe Key
noteOffsetToKey noteOffset =
    let
        rightKeyList =
            List.filter (\key -> key.noteOffset == noteOffset) keys
    in
    List.head rightKeyList


handleNewKey : String -> Msg
handleNewKey newKeyOffset =
    let
        maybeNewKeyOffset : Maybe Int
        maybeNewKeyOffset =
            String.toInt newKeyOffset

        maybeNewKey : Maybe (Maybe Key)
        maybeNewKey =
            Maybe.map noteOffsetToKey maybeNewKeyOffset
    in
    case maybeNewKey of
        Just (Just newKey) ->
            ChangeKey newKey

        _ ->
            ToErrorPage "Invalid Key"


scaleOptions : Model -> List (Html Msg)
scaleOptions model =
    let
        selectedScaleName =
            model.scale.name
    in
    List.map (selectOptionToOptionHtml selectedScaleName)
        (List.map (\{ name, constitution } -> SelectOption name name) scales)


handleNewScale : Model -> String -> Msg
handleNewScale model newScaleName =
    let
        maybeNewScale =
            scaleNameToScale newScaleName
    in
    case maybeNewScale of
        Just newScale ->
            if model.degreeRange <= List.length newScale.constitution then
                ChangeScale newScale

            else
                ChangeScaleAndDegreeRange newScale (List.length newScale.constitution)

        Nothing ->
            ToErrorPage "Invalid Scale"


shuffleKeyButton : Html Msg
shuffleKeyButton =
    button [ class "button is-info", onClick ShuffleKey ] [ text "Shuffle" ]


viewSelect : String -> String -> List (Html Msg) -> List (Html Msg) -> (String -> Msg) -> Html Msg
viewSelect selectId selectLabel options addons handleNewValue =
    div
        [ class "field is-horizontal" ]
        [ div [ class "field-label" ] [ label [ for selectId, class "label" ] [ text selectLabel ] ]
        , div [ class "field-body" ]
            [ div [ class "field is-grouped" ]
                ([ div [ class "control" ]
                    [ div [ class "select" ]
                        [ select
                            [ id selectId, Html.Events.on "change" (Json.map handleNewValue Html.Events.targetValue) ]
                            options
                        ]
                    ]
                 ]
                    ++ List.map (\html -> div [ class "control" ] [ html ]) addons
                )
            ]
        ]
