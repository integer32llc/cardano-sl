{-# LANGUAGE ScopedTypeVariables #-}

-- | Applications of runners to scenarios.

module Pos.Launcher.Launcher
       ( -- * Node launchers.
         runNodeReal
       ) where

import           Mockable                   (Production)
import           Network.Transport.Abstract (Transport)

import           Pos.Communication.Protocol (OutSpecs, WorkerSpec)
import           Pos.Discovery              (DiscoveryContextSum)
import           Pos.Launcher.Param         (NodeParams (..))
import           Pos.Launcher.Runner        (runRealMode)
import           Pos.Launcher.Scenario      (runNode)
import           Pos.Security               (SecurityWorkersClass)
import           Pos.Ssc.Class              (SscConstraint)
import           Pos.Ssc.Class.Types        (SscParams)
import           Pos.WorkMode               (RealMode)

-----------------------------------------------------------------------------
-- Main launchers
-----------------------------------------------------------------------------

-- | Run full node in real mode.
runNodeReal
    :: forall ssc.
       (SscConstraint ssc, SecurityWorkersClass ssc)
    => DiscoveryContextSum
    -> Transport (RealMode ssc)
    -> ([WorkerSpec (RealMode ssc)], OutSpecs)
    -> NodeParams
    -> SscParams ssc
    -> Production ()
runNodeReal discCtx transport plugins np sscnp =
    runRealMode discCtx transport np sscnp (runNode @ssc plugins)
