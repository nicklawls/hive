{-# LANGUAGE DeriveFunctor #-}

module Data.List.Zipper
    ( Z(..)
    , zfromList
    , zpeek
    , zleft
    , zright
    , module Control.Comonad
    ) where

import Control.Comonad

data Z a = Z [a] a [a]
    deriving Functor

instance Comonad Z where
    extract = zpeek
    duplicate z = Z (iterateMaybe z zleft) z (iterateMaybe z zright)

zfromList :: [a] -> Maybe (Z a)
zfromList []     = Nothing
zfromList (x:xs) = Just (Z [] x xs)

zpeek :: Z a -> a
zpeek (Z _ x _) = x

zleft :: Z a -> Maybe (Z a)
zleft (Z []     _ _)  = Nothing
zleft (Z (a:as) b cs) = Just (Z as a (b:cs))

zright :: Z a -> Maybe (Z a)
zright (Z _  _ [])     = Nothing
zright (Z as b (c:cs)) = Just (Z (b:as) c cs)

-- Like iterate, but also drop the inital element.
iterateMaybe :: a -> (a -> Maybe a) -> [a]
iterateMaybe x f =
    case f x of
        Nothing -> []
        Just x' -> x' : iterateMaybe x' f
