module GameState.State exposing (..)

import GameState.Json.Decode exposing (..)
import GameState.Types       exposing (..)
import WebSocket             exposing (..)

initialModel : Model
initialModel =
  Model Nothing


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    BadMessage err -> Debug.crash err

    GameMessage gameState -> ({ model | game = Just gameState }, Cmd.none)


gameSocket : String -> Model -> Sub Msg
gameSocket url _ =
  listen url <|
    \str -> case parseGameState str of
              Err err      ->
                BadMessage err

              Ok gameState ->
                GameMessage gameState

