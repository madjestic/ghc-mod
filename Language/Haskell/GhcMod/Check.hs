module Language.Haskell.GhcMod.Check (checkSyntax, check) where

import CoreMonad (liftIO)
import GHC (Ghc)
import qualified GHC as G
import Language.Haskell.GhcMod.ErrMsg
import Language.Haskell.GhcMod.GHCApi
import Language.Haskell.GhcMod.Types

----------------------------------------------------------------

-- | Checking syntax of a target file using GHC.
--   Warnings and errors are returned.
checkSyntax :: Options
            -> Cradle
            -> [FilePath]  -- ^ The target files.
            -> IO String
checkSyntax _   _      []    = error "ghc-mod: checkSyntax: No files given"
checkSyntax opt cradle files = withGHC sessionName (check opt cradle files)
  where
    sessionName = case files of
      [file] -> file
      _      -> "MultipleFiles"

----------------------------------------------------------------

-- | Checking syntax of a target file using GHC.
--   Warnings and errors are returned.
check :: Options
      -> Cradle
      -> [FilePath]  -- ^ The target files.
      -> Ghc String
check _   _      []        = error "ghc-mod: check: No files given"
check opt cradle fileNames = checkIt `G.gcatch` handleErrMsg opt
  where
    checkIt = do
        (readLog,_) <- initializeFlagsWithCradle opt cradle options True
        setTargetFiles fileNames
        liftIO readLog
    options
      | expandSplice opt = "-w:"   : ghcOpts opt
      | otherwise        = "-Wall" : ghcOpts opt
