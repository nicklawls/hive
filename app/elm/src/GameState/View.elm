module GameState.View exposing (..)

import GameState.Types exposing (..)
import Html            exposing (..)


view : Model -> Html Msg
view model =
  Html.text (toString model)