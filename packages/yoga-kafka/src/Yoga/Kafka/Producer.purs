module Yoga.Kafka.Producer where

import Prelude

import Data.Nullable (Nullable)
import Data.Time.Duration (Milliseconds)
import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Uncurried (EffectFn1, EffectFn2, runEffectFn1, runEffectFn2)
import Foreign.Object (Object)
import Yoga.Kafka.Kafka (ErrorCode, HeaderValue, Kafka, Key, Offset, PartitionId, Timestamp, TopicName, Value)
import Prim.Row (class Union)
import Promise (Promise)
import Promise.Aff (toAffE) as Promise

-- Opaque Producer type
foreign import data Producer :: Type

-- Create producer
type ProducerOptionsImpl = (allowAutoTopicCreation :: Boolean, transactionTimeout :: Milliseconds)

foreign import createProducerImpl :: forall opts. EffectFn2 Kafka { | opts } Producer

createProducer :: forall opts opts_. Union opts opts_ ProducerOptionsImpl => { | opts } -> Kafka -> Effect Producer
createProducer opts kafka = runEffectFn2 createProducerImpl kafka opts

-- Connect producer
foreign import connectProducerImpl :: EffectFn1 Producer (Promise Unit)

connect :: Producer -> Aff Unit
connect = runEffectFn1 connectProducerImpl >>> Promise.toAffE

-- Send messages
type ProducerMessageOptionsImpl = (key :: Key, partition :: PartitionId, headers :: Object HeaderValue, timestamp :: Timestamp)

type RecordMetadata =
  { topicName :: TopicName
  , partition :: PartitionId
  , errorCode :: ErrorCode
  , offset :: Nullable Offset
  , timestamp :: Nullable Timestamp
  }

type SendRecordImpl = (topic :: TopicName, messages :: Array (Record ProducerMessageOptionsImpl))

foreign import sendImpl :: forall opts msg. EffectFn2 Producer { topic :: TopicName, messages :: Array { value :: Value | msg } | opts } (Promise (Array RecordMetadata))

send :: forall opts opts_ msg msgOpts_. Union opts opts_ SendRecordImpl => Union msg msgOpts_ ProducerMessageOptionsImpl => { topic :: TopicName, messages :: Array { value :: Value | msg } | opts } -> Producer -> Aff (Array RecordMetadata)
send record producer = runEffectFn2 sendImpl producer record # Promise.toAffE

-- Disconnect producer
foreign import disconnectProducerImpl :: EffectFn1 Producer (Promise Unit)

disconnect :: Producer -> Aff Unit
disconnect = runEffectFn1 disconnectProducerImpl >>> Promise.toAffE
