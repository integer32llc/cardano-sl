{-# LANGUAGE ExistentialQuantification #-}

-- | Runtime context of node.

module Pos.Context.Context
       ( NodeContext (..)
       , ncPublicKey
       , ncPubKeyAddress
       , ncGenesisLeaders
       , ncGenesisUtxo
       , ncSystemStart
       , NodeParams(..)
       , BaseParams(..)
       ) where

import           Control.Concurrent.STM  (TBQueue)
import qualified Control.Concurrent.STM  as STM
import           Data.Time.Clock         (UTCTime)
import           System.Wlog             (LoggerConfig)
import           Universum

import           Pos.Communication.Relay (RelayInvQueue)
import           Pos.Communication.Types (NodeId)
import           Pos.Crypto              (PublicKey, toPublic)
import           Pos.Genesis             (genesisLeaders)
import           Pos.Launcher.Param      (BaseParams (..), NodeParams (..))
import           Pos.Lrc.Context         (LrcContext)
import           Pos.Ssc.Class.Types     (Ssc (SscNodeContext))
import           Pos.Txp.Settings        (TxpGlobalSettings)
import           Pos.Txp.Toil.Types      (Utxo)
import           Pos.Types               (Address, BlockHeader, HeaderHash, SlotLeaders,
                                          Timestamp, makePubKeyAddress)
import           Pos.Update.Context      (UpdateContext)
import           Pos.Update.Params       (UpdateParams)
import           Pos.Util.Chrono         (NE, NewestFirst)
import           Pos.Util.Context        (ExtractContext (..))
import           Pos.Util.UserSecret     (UserSecret)

----------------------------------------------------------------------------
-- NodeContext
----------------------------------------------------------------------------

-- | NodeContext contains runtime context of node.
data NodeContext ssc = NodeContext
    { ncJLFile              :: !(Maybe (MVar FilePath))
    -- @georgeee please add documentation when you see this comment
    , ncSscContext          :: !(SscNodeContext ssc)
    -- @georgeee please add documentation when you see this comment
    , ncUpdateContext       :: !UpdateContext
    -- ^ Context needed for the update system
    , ncLrcContext          :: !LrcContext
    -- ^ Context needed for LRC
    , ncBlkSemaphore        :: !(MVar HeaderHash)
    -- ^ Semaphore which manages access to block application.
    -- Stored hash is a hash of last applied block.
    , ncUserSecret          :: !(STM.TVar UserSecret)
    -- ^ Secret keys (and path to file) which are used to send transactions
    , ncBlockRetrievalQueue :: !(TBQueue (NodeId, NewestFirst NE (BlockHeader ssc)))
    -- ^ Concurrent queue that holds block headers that are to be
    -- downloaded.
    , ncRecoveryHeader      :: !(STM.TMVar (NodeId, BlockHeader ssc))
    -- ^ In case of recovery mode this variable holds the latest
    -- header hash we know about so we can do chained block
    -- requests. Invariant: this mvar is full iff we're more than
    -- 'recoveryHeadersMessage' blocks deep relatively to some valid
    -- header and we're downloading blocks. Every time we get block
    -- that's more difficult than this one, we overwrite. Every time
    -- we process some blocks and fail or see that we've downloaded
    -- this header, we clean mvar.
    , ncProgressHeader      :: !(STM.TMVar (BlockHeader ssc))
    -- ^ Header of the last block that was downloaded in retrieving
    -- queue. Is needed to show smooth prorgess on the frontend.
    , ncInvPropagationQueue :: !RelayInvQueue
    -- ^ Queue is used in Relay framework,
    -- it stores inv messages for earlier received data.
    , ncLoggerConfig        :: !LoggerConfig
    -- ^ Logger config, as taken/read from CLI.
    , ncNodeParams          :: !NodeParams
    -- ^ Params node is launched with
    , ncShutdownFlag        :: !(STM.TVar Bool)
    -- ^ If this flag is `True`, then workers should stop.
    , ncShutdownNotifyQueue :: !(TBQueue ())
    -- ^ A queue which is used to count how many workers have successfully
    -- terminated.
    , ncSendLock            :: !(Maybe (MVar ()))
    -- ^ Exclusive lock for sending messages to other nodes
    -- (if Nothing, no lock used).
    , ncStartTime           :: !UTCTime
    -- ^ Time when node was started ('NodeContext' initialized).
    , ncLastKnownHeader     :: !(STM.TVar (Maybe (BlockHeader ssc)))
    -- ^ Header of last known block, generated by network (announcement of
    -- which reached us). Should be use only for informational purposes
    -- (status in Daedalus). It's easy to falsify this value.
    , ncTxpGlobalSettings   :: !TxpGlobalSettings
    -- ^ Settings for global Txp.
    , ncConnectedPeers      :: !(STM.TVar (Set NodeId))
    -- ^ Set of peers that we're connected to.
    }

instance ExtractContext UpdateContext (NodeContext ssc) where
    extractContext = ncUpdateContext
instance ExtractContext LrcContext (NodeContext ssc) where
    extractContext = ncLrcContext
instance ExtractContext NodeParams (NodeContext ssc) where
    extractContext = ncNodeParams
instance ExtractContext UpdateParams (NodeContext ssc) where
    extractContext = npUpdateParams . ncNodeParams

----------------------------------------------------------------------------
-- Helper functions
----------------------------------------------------------------------------

-- | Generate 'PublicKey' from 'SecretKey' of 'NodeContext'.
ncPublicKey :: NodeContext ssc -> PublicKey
ncPublicKey = toPublic . npSecretKey . ncNodeParams

-- | Generate 'Address' from 'SecretKey' of 'NodeContext'
ncPubKeyAddress :: NodeContext ssc -> Address
ncPubKeyAddress = makePubKeyAddress . ncPublicKey

ncGenesisUtxo :: NodeContext ssc -> Utxo
ncGenesisUtxo = npCustomUtxo . ncNodeParams

ncGenesisLeaders :: NodeContext ssc -> SlotLeaders
ncGenesisLeaders = genesisLeaders . ncGenesisUtxo

ncSystemStart :: NodeContext __ -> Timestamp
ncSystemStart = npSystemStart . ncNodeParams
