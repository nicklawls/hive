{-# LANGUAGE DeriveGeneric       #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell     #-}
{-# LANGUAGE TupleSections       #-}
{-# LANGUAGE TypeFamilies        #-}

module Data.HexBoard
    ( HexBoard(..)
    , BoardIndex
    , boardTiles
    , boardParity
    , boardWidth
    , boardHeight
    , boardNeighbors
    , boardAdjacency
    , boardNumSCCs
    , Parity(..)
    , flipParity
    , Adjacency(..)
    ) where

import Control.Lens
import Control.Monad
import Data.Maybe
import Data.Vector  (Vector)
import GHC.Generics (Generic)

import qualified Data.Graph  as Graph
import qualified Data.Vector as V

-- Even or odd board parity.
data Parity
    = Even
    | Odd
    deriving (Eq, Generic, Show)

flipParity :: Parity -> Parity
flipParity Even = Odd
flipParity Odd  = Even

-- One cell's relation to another.
data Adjacency
    = Up
    | UpRight
    | DownRight
    | Down
    | DownLeft
    | UpLeft
    deriving Eq

-- (row, col)
--
-- For example, on a 5-by-5 board,
--
--     (0,0) represents the top left tile
--     (0,4) represents the top right tile
type BoardIndex = (Int, Int)

-- | Hexagonal board.
--
-- Uses the "odd-q" or "even-q" vertical layout (tracked by boardParity field),
-- as depected here:
-- http://www.redblobgames.com/grids/hexagons/#coordinates
--
-- Invariant: each row contains the same number of columns as the others (the
--            board is a rectangle)

-- Invariant: boardWidth and boardHeight are always kept in sync with boardTiles
data HexBoard a = HexBoard
    { _boardTiles  :: Vector (Vector a)
    , _boardParity :: Parity
    } deriving (Eq, Generic, Show)
makeLenses ''HexBoard

type instance Index   (HexBoard a) = (Int, Int)
type instance IxValue (HexBoard a) = a

instance Ixed (HexBoard a) where
    ix (row, col) = boardTiles . ix row . ix col

boardWidth :: Getter (HexBoard a) Int
boardWidth = to (\board -> maybe 0 length (board ^? boardTiles . ix 0))

boardHeight :: Getter (HexBoard a) Int
boardHeight = boardTiles . to length

boardNeighbors :: BoardIndex -> HexBoard a -> [(BoardIndex, a)]
boardNeighbors (row, col) board =
    catMaybes (map (\i -> fmap (i,) (board ^? ix i)) neighbor_idxs)
  where
    neighbor_idxs :: [BoardIndex]
    neighbor_idxs =
        case tileParity col (board^.boardParity) of
            Even -> [up, right, downright, down, downleft, left]
            Odd  -> [up, upright, right, down, left, upleft]

    up        = (row-1, col)
    upright   = (row-1, col+1)
    right     = (row,   col+1)
    downright = (row+1, col+1)
    down      = (row+1, col)
    downleft  = (row+1, col-1)
    left      = (row,   col-1)
    upleft    = (row-1, col-1)

boardAdjacency :: HexBoard a -> BoardIndex -> BoardIndex -> Maybe Adjacency
boardAdjacency board (r0,c0) (r1,c1) =
    case tileParity c0 (board^.boardParity) of
        Even
            | r0 == r1+1 && c0 == c1   -> Just Up
            | r0 == r1   && c0 == c1+1 -> Just UpLeft
            | r0 == r1   && c0 == c1-1 -> Just UpRight
            | r0 == r1-1 && c0 == c1+1 -> Just DownLeft
            | r0 == r1-1 && c0 == c1   -> Just Down
            | r0 == r1-1 && c0 == c1-1 -> Just DownRight
            | otherwise                -> Nothing
        Odd
            | r0 == r1+1 && c0 == c1+1 -> Just UpLeft
            | r0 == r1+1 && c0 == c1   -> Just Up
            | r0 == r1+1 && c0 == c1-1 -> Just UpRight
            | r0 == r1   && c0 == c1+1 -> Just DownLeft
            | r0 == r1   && c0 == c1-1 -> Just DownRight
            | r0 == r1-1 && c0 == c1   -> Just Down
            | otherwise                -> Nothing

tileParity :: Int -> Parity -> Parity
tileParity col p1
    | colParity == p1 = Even
    | otherwise = Odd
  where
    colParity :: Parity
    colParity
        | even col  = Even
        | otherwise = Odd

boardNumSCCs :: forall a. (a -> Bool) -> HexBoard a -> Int
boardNumSCCs hasElement board = length (Graph.stronglyConnComp adjacency_list)
  where
    -- Fold the board into an adjacency list, suitable for the strongly
    -- connected component API of Data.Graph. Since we don't care what the
    -- nodes' values are, just use unit. Key nodes by their unique indices.
    adjacency_list :: [((), BoardIndex, [BoardIndex])]
    adjacency_list = V.ifoldl' f [] (board^.boardTiles)

    -- First fold: over each row
    f :: [((), BoardIndex, [BoardIndex])]
      -> Int
      -> Vector a
      -> [((), BoardIndex, [BoardIndex])]
    f acc row_idx = V.ifoldl (g row_idx) acc

    -- Second fold: over each element of each row
    g :: Int
      -> [((), BoardIndex, [BoardIndex])]
      -> Int
      -> a
      -> [((), BoardIndex, [BoardIndex])]
    g row_idx acc col_idx x
        | hasElement x =
            let
                idx0 :: BoardIndex
                idx0 = (row_idx, col_idx)

                -- All neighbors of this cell that have elements.
                neighbors :: [BoardIndex]
                neighbors = do
                    (idx1, y) <- boardNeighbors idx0 board
                    guard (hasElement y)
                    pure idx1
            in
                ((), idx0, neighbors) : acc
        | otherwise = acc
