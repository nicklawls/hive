module GameState.Types exposing (..)

import Dict exposing (..)

{- DIRE WARNING OF IMPENDING DOOM TO ALL WHO WANT TO CHANGE THESE TYPES

  The moment you find yourself wanting to add view state to one of the types in
  here, make that type its own module, complete with an associated Msg type,
  update, and view functions

-}

type alias Model =
  { game : Maybe GameState -- Nothing when the game has not started
  }


type Msg = BadMessage String
         | GameMessage GameState


type GameState
    = GameOver (Maybe Player)
    | GameActive Game


type Player = P1 | P2


type alias Game =
    { gameBoard    : Board    -- Game board
    , gamePlayer   : Player   -- Current player
    , gameP1Bugs   : List Bug -- Player 1's bugs
    , gameP2Bugs   : List Bug -- Player 2's bugs
    , gameP1Placed : Int      -- # of bugs P1 has placed
    , gameP2Placed : Int      -- # of bugs P2 has placed
    }


type alias Board =
  { boardTiles  : Dict BoardIndex Cell
  , boardParity : Parity
  }


type alias BoardIndex = (Int,Int)


type alias Cell = List Tile


type Parity
  = Even
  | Odd


type alias Tile =
  { tylePlayer : Player
  , tyleBug    : Bug
  }


type Bug
  = Ant
  | Grasshopper
  | Spider
  | Beetle
  | Queen