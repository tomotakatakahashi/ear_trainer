module Common exposing (..)

import Browser
import Html exposing (div, text)


main =
    Browser.element
        { init = \() -> ( (), Cmd.none )
        , subscriptions = \_ -> Sub.none
        , update = \msg model -> ( model, Cmd.none )
        , view = \model -> div [] [ text "Common module" ]
        }



-- Scales


type alias ScaleNote =
    { interval : Int, name : String }


type alias Scale =
    { name : String
    , constitution : List ScaleNote
    }


majorScale : Scale
majorScale =
    { name = "Major Scale"
    , constitution =
        List.map (\( interval, name ) -> ScaleNote interval name)
            [ ( 0, "Do" ), ( 2, "Re" ), ( 4, "Mi" ), ( 5, "Fa" ), ( 7, "Sol" ), ( 9, "La" ), ( 11, "Ti" ) ]
    }


naturalMinorScale : Scale
naturalMinorScale =
    { name = "Natural Minor Scale"
    , constitution =
        List.map (\( interval, name ) -> ScaleNote interval name)
            [ ( 0, "Do" ), ( 2, "Re" ), ( 3, "Me" ), ( 5, "Fa" ), ( 7, "Sol" ), ( 8, "Le" ), ( 10, "Te" ) ]
    }


minorPentatonicScale : Scale
minorPentatonicScale =
    { name = "Minor Pentatonic Scale"
    , constitution =
        List.map (\( interval, name ) -> ScaleNote interval name)
            [ ( 0, "Do" ), ( 3, "Me" ), ( 5, "Fa" ), ( 7, "Sol" ), ( 10, "Te" ) ]
    }


scales : List Scale
scales =
    [ majorScale, naturalMinorScale, minorPentatonicScale ]


scaleNameToScale : String -> Maybe Scale
scaleNameToScale name =
    let
        nameMatchScales =
            List.filter (\scale -> scale.name == name) scales

        targetScale =
            List.head nameMatchScales
    in
    targetScale



-- Settings


type alias GameSettings =
    { rootNote : Int
    , degreeRange : Int
    , tempo : Int
    , scale : Scale
    , playSeq : List Int
    }


sampleGameSettings : GameSettings
sampleGameSettings =
    { rootNote = 48
    , degreeRange = 5
    , tempo = 50
    , scale = majorScale
    , playSeq = [ 0, 3, 2, 1, 4, 0, 1, 4, 2, 3 ]
    }


type alias Key =
    { noteOffset : Int, name : String }


keys : List Key
keys =
    List.map (\( noteOffset, name ) -> Key noteOffset name)
        [ ( 0, "C" ), ( 1, "Db" ), ( 2, "D" ), ( 3, "Eb" ), ( 4, "E" ), ( 5, "F" ), ( 6, "Gb" ), ( 7, "G" ), ( 8, "Ab" ), ( 9, "A" ), ( 10, "Bb" ), ( 11, "B" ) ]



-- Utils


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
