module GameState.Json.Decode exposing (parseGameState)

import GameState.Types   exposing (..)
import Json.Decode       exposing (..)
import Json.Decode.Extra exposing (..)


parseGameState : String -> Result String GameState
parseGameState =
  Json.Decode.decodeString gameState


gameState : Decoder GameState
gameState =
  "tag" := string `andThen`
    \tag ->
        case tag of
          "GameOver"   ->
            ("contents" := maybe player)
              |> map GameOver

          "GameActive" ->
            ("contents" := game)
              |> map GameActive

          _            ->
            fail ("Unknown GameState" ++ tag)


player : Decoder Player
player =
  customDecoder string <|
      \str -> case str of
        "P1" -> Ok P1
        "P2" -> Ok P2
        _    -> Err ("Unknown Player: " ++ str)


game : Decoder Game
game = object6 Game
  ("gameBoard"    := board)
  ("gamePlayer"   := player)
  ("gameP1Bugs"   := list bug)
  ("gameP2Bugs"   := list bug)
  ("gameP1Placed" := int)
  ("gameP2Placed" := int)


board : Decoder Board
board =
  object2 Board
    ("boardTiles"  := dict2 boardIndex cell)
    ("boardParity" := parity)


boardIndex : Decoder BoardIndex
boardIndex =
  tuple2 (,) int int


cell : Decoder Cell
cell = list tile


parity : Decoder Parity
parity =
  customDecoder string <|
    \str ->
      case str of
        "Even" -> Ok Even
        "Odd"  -> Ok Odd
        _      -> Err ("Unknown Parity" ++ str)


tile : Decoder Tile
tile =
  object2 Tile
    ("tilePlayer" := player)
    ("tileBug"    := bug)


bug : Decoder Bug
bug =
  customDecoder string <|
    \str ->
      case str of
        "Ant"         -> Ok Ant
        "Grasshopper" -> Ok Grasshopper
        "Spider"      -> Ok Spider
        "Beetle"      -> Ok Beetle
        "Queen"       -> Ok Queen
        _             -> Err ("Unknown Bug" ++ str)