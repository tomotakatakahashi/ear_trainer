module Main exposing (main)

import Array
import Browser
import Common exposing (..)
import Html exposing (Html, div, text)
import Html.Attributes exposing (..)
import Json.Encode exposing (encode)
import LoadAudio as L
import LocalStorage
import Menu as M
import Play as P
import Prepare as PR
import Score as S
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
    { pageModel : PageModel
    , localStorageData : LocalStorage.Model
    }


type PageModel
    = MModel M.Model
    | LModel L.Model
    | PRModel PR.Model
    | PModel P.Model
    | SModel S.Model
    | Error String


init : () -> ( Model, Cmd Msg )
init _ =
    let
        ( mModel, mCmd ) =
            M.init ()

        ( localStorageData, localStorageCmd ) =
            LocalStorage.init ()
    in
    ( { pageModel = MModel mModel, localStorageData = localStorageData }, Cmd.batch [ Cmd.map MMsg mCmd, LocalStorage.queryLocalStorage () ] )



-- UPDATE


type Msg
    = MMsg M.Msg
    | LMsg L.Msg
    | PRMsg PR.Msg
    | PMsg P.Msg
    | SMsg S.Msg
    | LSMsg LocalStorage.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        pageModel =
            model.pageModel

        localStorageData =
            model.localStorageData
    in
    case ( msg, pageModel ) of
        ( LSMsg (LocalStorage.LoadData newLocalStorageData), MModel mModel ) ->
            ( { pageModel = MModel newLocalStorageData.defaultMenuOptions, localStorageData = newLocalStorageData }, Cmd.none )

        ( MMsg mMsg, MModel mModel ) ->
            case mMsg of
                M.ToLoadPage gameSettings ->
                    let
                        newLocalStorageData =
                            { localStorageData | defaultMenuOptions = mModel }
                    in
                    ( { pageModel = LModel gameSettings, localStorageData = newLocalStorageData }
                    , Cmd.batch
                        [ Cmd.map LMsg (L.loadAudio (L.scaleNotePaths gameSettings))
                        , LocalStorage.saveLocalStorage (Json.Encode.encode 0 (LocalStorage.encodeLocalStorageData newLocalStorageData))
                        ]
                    )

                M.ToErrorPage errorMessage ->
                    ( { model | pageModel = Error errorMessage }, Cmd.none )

                _ ->
                    let
                        ( newMModel, mCmd ) =
                            M.update mMsg mModel
                    in
                    ( { model | pageModel = MModel newMModel }, Cmd.map MMsg mCmd )

        ( LMsg lMsg, LModel lModel ) ->
            case lMsg of
                L.ToPreparePage ->
                    ( { model | pageModel = PRModel { gameSettings = lModel, startTime = Nothing } }, Cmd.map PRMsg PR.startPrepare )

                _ ->
                    let
                        ( newLModel, lCmd ) =
                            L.update lMsg lModel
                    in
                    ( { model | pageModel = LModel newLModel }, Cmd.map LMsg lCmd )

        ( PRMsg prMsg, PRModel prModel ) ->
            case prMsg of
                PR.ToPlayPage ->
                    ( { model
                        | pageModel =
                            PModel
                                { gameSettings = prModel.gameSettings
                                , startTime = Nothing
                                , userSeq = Array.repeat (List.length prModel.gameSettings.playSeq) Nothing
                                , nowPlaying = Nothing
                                , nowUser = Nothing
                                }
                      }
                    , Cmd.map PMsg P.startPlay
                    )

                _ ->
                    let
                        ( newPRModel, prCmd ) =
                            PR.update prMsg prModel
                    in
                    ( { model | pageModel = PRModel newPRModel }, Cmd.map PRMsg prCmd )

        ( PMsg pMsg, PModel pModel ) ->
            case pMsg of
                P.ToScorePage ->
                    case pModel.startTime of
                        Nothing ->
                            ( { model | pageModel = Error "Invalid time record" }, Cmd.none )

                        Just t ->
                            let
                                newLocalStorageData = {localStorageData| playHistory = Array.push {gameSettings = pModel.gameSettings, playResult = {userSeq = pModel.userSeq, startDate = Time.posixToMillis t}} localStorageData.playHistory}
                            in
                            ( { pageModel = SModel { gameSettings = pModel.gameSettings, startTime = t, userSeq = pModel.userSeq }, localStorageData = newLocalStorageData},
                                  LocalStorage.saveLocalStorage (Json.Encode.encode 0 (LocalStorage.encodeLocalStorageData newLocalStorageData) ))

                _ ->
                    let
                        ( newPModel, pCmd ) =
                            P.update pMsg pModel
                    in
                    ( { model | pageModel = PModel newPModel }, Cmd.map PMsg pCmd )

        ( SMsg sMsg, SModel sModel ) ->
            case sMsg of
                S.ToMenuPage ->
                    ( {model| pageModel = MModel model.localStorageData.defaultMenuOptions}, Cmd.none)
                S.Retry ->
                    ( {model| pageModel = PRModel {gameSettings = sModel.gameSettings, startTime=Nothing}}, Cmd.map PRMsg PR.startPrepare)

        _ ->
            ( model, Cmd.none )



{-
   _ ->
       let
           (newSModel, sCmd) = S.update sMsg sModel
       in
           (SModel newSModel, Cmd.map SMsg sCmd)
-}
-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        pageSubscription =
            case model.pageModel of
                MModel mModel ->
                    Sub.map MMsg (M.subscriptions mModel)

                LModel lModel ->
                    Sub.map LMsg (L.subscriptions lModel)

                PRModel prModel ->
                    Sub.map PRMsg (PR.subscriptions prModel)

                PModel pModel ->
                    Sub.map PMsg (P.subscriptions pModel)

                SModel sModel ->
                    Sub.map SMsg (S.subscriptions sModel)

                Error _ ->
                    Sub.none
    in
    Sub.batch [ pageSubscription, Sub.map LSMsg (LocalStorage.receiveLocalStorage LocalStorage.handleReceivedLocalStorage) ]



-- VIEW


view : Model -> Html Msg
view model =
    case model.pageModel of
        MModel mModel ->
            M.view mModel |> Html.map MMsg

        LModel lModel ->
            L.view lModel |> Html.map LMsg

        PRModel prModel ->
            PR.view prModel |> Html.map PRMsg

        PModel pModel ->
            P.view pModel |> Html.map PMsg

        SModel sModel ->
            S.view sModel |> Html.map SMsg

        Error errorMessage ->
            div [] [ text ("Error: " ++ errorMessage) ]
