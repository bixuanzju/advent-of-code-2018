-- |
-- Module      : AOC2018.Challenge.Day05
-- Copyright   : (c) Justin Le 2018
-- License     : BSD3
--
-- Maintainer  : justin@jle.im
-- Stability   : experimental
-- Portability : non-portable
--
-- Day 5.  See "AOC2018.Solver" for the types used in this module!

module AOC2018.Challenge.Day05 (
    day05a
  , day05b
  ) where

import           AOC2018.Solver ((:~>)(..))
import           AOC2018.Util   (strip, minimumVal)
import           Data.Char      (toLower, isUpper)
import qualified Data.Map       as M
import qualified Data.Set       as S

anti :: Char -> Char -> Bool
anti x y = toLower x == toLower y
        && isUpper x /= isUpper y

cons :: Char -> String -> String
x `cons` (y:xs)
    | anti x y  = xs
    | otherwise = x:y:xs
x `cons` []     = [x]

react :: String -> String
react = foldr cons []

day05a :: String :~> Int
day05a = MkSol
    { sParse = Just . strip
    , sShow  = show
    , sSolve = Just . length . react
    }

day05b :: String :~> Int
day05b = MkSol
    { sParse = Just . strip
    , sShow  = show
    , sSolve = \xs -> fmap snd
                    . minimumVal
                    . M.fromSet (length . react . (`remove` xs))
                    . S.fromList
                    $ ['a' .. 'z']
    }
  where
    remove c = filter $ (/= c) . toLower
