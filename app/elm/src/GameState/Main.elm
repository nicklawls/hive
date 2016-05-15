module Main exposing (..)

import GameState.State       exposing (..)
import GameState.View        exposing (..)
import Html.App              exposing (..)


main : Program Never
main =
  Html.App.program
    { init = (initialModel, Cmd.none)
    , update = update
    , subscriptions = gameSocket "ws://localhost:6789"
    , view = view
    }