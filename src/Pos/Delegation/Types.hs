{-# LANGUAGE TemplateHaskell #-}
{-# OPTIONS_GHC -Wno-warnings-deprecations #-} -- makeArbitrary uses error, we use panic

-- | Delegation-related network and local types.

module Pos.Delegation.Types
       ( SendProxySK (..)
       , ConfirmProxySK (..)
       , CheckProxySKConfirmed (..)
       , CheckProxySKConfirmedRes (..)
       ) where

import           Data.DeriveTH   (derive, makeArbitrary)
import           Node.Message    (Message (..))
import           Test.QuickCheck (Arbitrary (..), choose)
import           Universum

import           Pos.Types       (ProxySKEpoch, ProxySKSimple, ProxySigEpoch)

----------------------------------------------------------------------------
-- Generic PSKs propagation
----------------------------------------------------------------------------

-- | Message with delegated proxy secret key. Is used to propagate
-- both epoch-oriented psks (lightweight) and simple (heavyweight).
data SendProxySK
    = SendProxySKEpoch !ProxySKEpoch
    | SendProxySKSimple !ProxySKSimple
    deriving (Show, Eq, Generic)

instance Hashable SendProxySK

instance Message SendProxySK where
    messageName _ = "SendProxySK"
    formatMessage _ = "SendProxySK"

----------------------------------------------------------------------------
-- Lightweight PSKs confirmation mechanism
----------------------------------------------------------------------------

-- | Confirmation of proxy signature delivery. Delegate should take
-- the proxy signing key he has and sign this key with itself. If the
-- signature is correct, then it was done by delegate (guaranteed by
-- PSK scheme). Checking @w@ can be done with @(const True)@
-- predicate, because certificate may be sent in epoch id that's
-- before lower cert's @EpochIndex@.
data ConfirmProxySK =
    ConfirmProxySK !ProxySKEpoch !(ProxySigEpoch ProxySKEpoch)
    deriving (Show, Eq, Generic)

instance Message ConfirmProxySK where
    messageName _ = "ConfirmProxySK"
    formatMessage _ = "ConfirmProxySK"

-- | Request to check if a node has any info about PSK delivery.
data CheckProxySKConfirmed =
    CheckProxySKConfirmed !ProxySKEpoch
    deriving (Show, Eq, Generic)

instance Message CheckProxySKConfirmed where
    messageName _ = "CheckProxySKConfirmed"
    formatMessage _ = "CheckProxySKConfirmed"

-- | Response to the @CheckProxySKConfirmed@ call.
data CheckProxySKConfirmedRes =
    CheckProxySKConfirmedRes !Bool
    deriving (Show, Eq, Generic)

instance Message CheckProxySKConfirmedRes where
    messageName _ = "CheckProxySKConfirmedRes"
    formatMessage _ = "CheckProxySKConfirmedRes"

----------------------------------------------------------------------------
-- Arbitrary instances
----------------------------------------------------------------------------

derive makeArbitrary ''SendProxySK
derive makeArbitrary ''ConfirmProxySK
derive makeArbitrary ''CheckProxySKConfirmed
derive makeArbitrary ''CheckProxySKConfirmedRes