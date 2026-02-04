module Yoga.Kafka.Consumer where

import Prelude

import Data.Maybe (Maybe)
import Data.Nullable (Nullable, toMaybe)
import Data.Time.Duration (Milliseconds)
import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Uncurried (EffectFn1, EffectFn2, EffectFn5, runEffectFn1, runEffectFn2, runEffectFn5)
import Foreign (Foreign)
import Foreign.Object (Object)
import Yoga.Kafka.Kafka (ConsumerGroupId, HeaderValue, Kafka, Key, Offset, PartitionId, Timestamp, TopicName, Value)
import Prim.Row (class Union)
import Promise (Promise)
import Promise.Aff (fromAff, toAffE) as Promise

-- Opaque Consumer type
foreign import data Consumer :: Type

-- Create consumer
type ConsumerOptionsImpl = (sessionTimeout :: Milliseconds, rebalanceTimeout :: Milliseconds, heartbeatInterval :: Milliseconds)

foreign import createConsumerImpl :: forall opts. EffectFn2 Kafka { groupId :: ConsumerGroupId | opts } Consumer

createConsumer :: forall opts opts_. Union opts opts_ ConsumerOptionsImpl => { groupId :: ConsumerGroupId | opts } -> Kafka -> Effect Consumer
createConsumer opts kafka = runEffectFn2 createConsumerImpl kafka opts

-- Connect consumer
foreign import connectConsumerImpl :: EffectFn1 Consumer (Promise Unit)

connect :: Consumer -> Aff Unit
connect = runEffectFn1 connectConsumerImpl >>> Promise.toAffE

-- Subscribe to topics
type SubscribeOptionsImpl = (fromBeginning :: Boolean)

foreign import subscribeImpl :: forall opts. EffectFn2 Consumer { topic :: TopicName | opts } (Promise Unit)

subscribe :: forall opts opts_. Union opts opts_ SubscribeOptionsImpl => { topic :: TopicName | opts } -> Consumer -> Aff Unit
subscribe opts consumer = runEffectFn2 subscribeImpl consumer opts # Promise.toAffE

-- FFI types
type KafkaMessageFFI =
  { topic :: TopicName
  , partition :: PartitionId
  , message ::
      { key :: Nullable Key
      , value :: Value
      , headers :: Object HeaderValue
      , offset :: Offset
      , timestamp :: Timestamp
      }
  }

-- PureScript-friendly batch types (mutated in JavaScript before reaching PureScript)
type BatchMessage =
  { key :: Maybe Key
  , value :: Value
  , headers :: Object HeaderValue
  , offset :: Offset
  , timestamp :: Timestamp
  }

-- Batch type with async operations converted to Aff (mutated by JavaScript)
type Batch =
  { topic :: TopicName
  , partition :: PartitionId
  , highWatermark :: Offset -- Last committed offset, useful for calculating lag
  , messages :: Array BatchMessage
  , resolveOffset :: Offset -> Effect Unit -- Mark a message as processed (synchronous, returns void)
  , heartbeat :: Aff Unit -- Send heartbeat to broker (converted from Effect (Promise Unit))
  , commitOffsetsIfNecessary :: Effect (Promise Unit) -- Commit offsets based on autoCommit config
  , uncommittedOffsets :: Effect Foreign -- Get uncommitted offsets by topic-partition (complex nested structure)
  , isRunning :: Effect Boolean -- Check if consumer is still running
  , isStale :: Effect Boolean -- Check if batch is stale (e.g., after seek)
  , pause :: Effect (Effect Unit) -- Pause current partition, returns resume function
  }

-- User-facing run options (PureScript-friendly!)
-- Handlers are Aff Unit to support async operations (use liftEffect for Effect code)
type RunOptionsImpl =
  ( eachMessage :: KafkaMessageFFI -> Aff Unit
  , eachBatch :: Batch -> Aff Unit
  , eachBatchAutoResolve :: Boolean -- Auto-commit last offset if eachBatch doesn't throw (default: true)
  , autoCommit :: Boolean -- Enable/disable auto commit (default: true)
  , autoCommitInterval :: Milliseconds -- Commit every N milliseconds
  , autoCommitThreshold :: Int -- Commit after N messages
  , partitionsConsumedConcurrently :: Int -- Process N partitions concurrently (default: 1)
  )

foreign import runImpl
  :: forall opts
   . EffectFn5
       Consumer
       { | opts }
       (Nullable Key -> Maybe Key)
       (Effect (Promise Unit) -> Aff Unit)
       (Aff Unit -> Effect (Promise Unit))
       (Promise Unit)

run :: forall opts opts_. Union opts opts_ RunOptionsImpl => { | opts } -> Consumer -> Aff Unit
run opts consumer =
  runEffectFn5
    runImpl
    consumer
    opts
    toMaybe
    Promise.toAffE
    (\aff -> Promise.fromAff aff)
    # Promise.toAffE

-- Disconnect consumer
foreign import disconnectConsumerImpl :: EffectFn1 Consumer (Promise Unit)

disconnect :: Consumer -> Aff Unit
disconnect = runEffectFn1 disconnectConsumerImpl >>> Promise.toAffE
