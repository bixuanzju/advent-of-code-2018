-- |
-- Module      : AOC2018.Run.Interactive
-- Copyright   : (c) Justin Le 2018
-- License     : BSD3
--
-- Maintainer  : justin@jle.im
-- Stability   : experimental
-- Portability : non-portable
--
-- Versions of loaders and runners meant to be used in GHCI.
--

module AOC2018.Run.Interactive (
    execSolution
  , execSolutionWith
  , testSolution
  , viewPrompt
  , submitSolution
  , loadInput
  , loadTests
  , mkSpec
  ) where

import           AOC2018.API
import           AOC2018.Challenge
import           AOC2018.Run
import           AOC2018.Run.Config
import           AOC2018.Run.Load
import           AOC2018.Util
import           Control.Lens
import           Control.Monad.Except
import           Data.Finite
import           Data.Text            (Text)
import           Text.Printf
import qualified Data.Map             as M

-- | Run the solution indicated by the challenge spec on the official
-- puzzle input.  Get answer as result.
execSolution :: ChallengeSpec -> IO String
execSolution cs = eitherIO $ do
    cfg <- liftIO $ configFile "aoc-conf.yaml"
    out <- mainRun cfg . defaultMRO $ TSDayPart cs
    res <- maybeToEither ["Result not found in result map (Internal Error)"] $
      lookupSolution cs out
    liftEither $ snd res

-- | Run the solution indicated by the challenge spec on a custom input.
-- Get answer as result.
execSolutionWith
    :: ChallengeSpec
    -> String               -- ^ custom puzzle input
    -> IO String
execSolutionWith cs inp = eitherIO $ do
    cfg <- liftIO $ configFile "aoc-conf.yaml"
    out <- mainRun cfg $ (defaultMRO (TSDayPart cs))
      { _mroInput = M.singleton (_csDay cs) . M.singleton (_csPart cs) $ inp
      }
    res <- maybeToEither ["Result not found in result map (Internal Error)"] $
      lookupSolution cs out
    liftEither $ snd res

-- | Run test suite for a given challenge spec.
--
-- Returns 'Just' if any tests were run, with a 'Bool' specifying whether
-- or not all tests passed.
testSolution :: ChallengeSpec -> IO (Maybe Bool)
testSolution cs = eitherIO $ do
    cfg <- liftIO $ configFile "aoc-conf.yaml"
    out <- mainRun cfg $ (defaultMRO (TSDayPart cs))
      { _mroTest  = True
      }
    res <- maybeToEither ["Result not found in result map (Internal Error)"] $
      lookupSolution cs out
    pure $ fst res

-- | View the prompt for a given challenge spec.
viewPrompt :: ChallengeSpec -> IO Text
viewPrompt cs@CS{..} = eitherIO $ do
    cfg <- liftIO $ configFile "aoc-conf.yaml"
    out <- mainView cfg MVO
      { _mvoSpec = TSDayPart cs
      }
    maybeToEither ["Prompt not found in result map (Internal Error)"] $
      lookupSolution cs out

-- | Submit solution for a given challenge spec, and lock if correct.
submitSolution :: ChallengeSpec -> IO (Text, SubmitRes)
submitSolution cs = eitherIO $ do
    cfg <- liftIO $ configFile "aoc-conf.yaml"
    mainSubmit cfg . defaultMSO $ cs

-- | Load input for a given challenge
loadInput :: ChallengeSpec -> IO String
loadInput cs = eitherIO $ do
    CD{..}  <- liftIO $ do
      Cfg{..} <- configFile "aoc-conf.yaml"
      challengeData _cfgSession cs
    liftEither _cdInput

-- | Load test cases for a given challenge
loadTests :: ChallengeSpec -> IO [(String, Maybe String)]
loadTests cs = do
    Cfg{..} <- configFile "aoc-conf.yaml"
    _cdTests <$> challengeData _cfgSession cs

-- | Unsafely create a 'ChallengeSpec' from a day number and part.
--
-- Is undefined if given a day number out of range (1-25).
mkSpec :: Integer -> Char -> ChallengeSpec
mkSpec i c = maybe e (`CS` c) . packFinite $ i - 1
  where
    e = errorWithoutStackTrace $ printf "Day out of range: %d" i

eitherIO :: ExceptT [String] IO a -> IO a
eitherIO act = runExceptT act >>= \case
    Right x  -> pure x
    Left  es -> fail $ unlines es

