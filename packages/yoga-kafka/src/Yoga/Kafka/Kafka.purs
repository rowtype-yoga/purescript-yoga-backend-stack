module Yoga.Kafka.Kafka where

import Prelude

import Data.Newtype (class Newtype)
import Effect (Effect)
import Effect.Uncurried (EffectFn1, runEffectFn1)
import Prim.Row (class Union)

-- Opaque Kafka client type
foreign import data Kafka :: Type

-- Newtypes for type safety
newtype TopicName = TopicName String

derive instance Newtype TopicName _
derive newtype instance Eq TopicName
derive newtype instance Ord TopicName
derive newtype instance Show TopicName

newtype ConsumerGroupId = ConsumerGroupId String

derive instance Newtype ConsumerGroupId _
derive newtype instance Eq ConsumerGroupId
derive newtype instance Show ConsumerGroupId

newtype ClientId = ClientId String

derive instance Newtype ClientId _
derive newtype instance Eq ClientId
derive newtype instance Show ClientId

newtype BrokerAddress = BrokerAddress String

derive instance Newtype BrokerAddress _
derive newtype instance Eq BrokerAddress
derive newtype instance Show BrokerAddress

newtype PartitionId = PartitionId Int

derive instance Newtype PartitionId _
derive newtype instance Eq PartitionId
derive newtype instance Ord PartitionId
derive newtype instance Show PartitionId

newtype BrokerId = BrokerId String

derive instance Newtype BrokerId _
derive newtype instance Eq BrokerId
derive newtype instance Show BrokerId

newtype Offset = Offset String

derive instance Newtype Offset _
derive newtype instance Eq Offset
derive newtype instance Ord Offset
derive newtype instance Show Offset

newtype Timestamp = Timestamp String

derive instance Newtype Timestamp _
derive newtype instance Eq Timestamp
derive newtype instance Ord Timestamp
derive newtype instance Show Timestamp

newtype Key = Key String

derive instance Newtype Key _
derive newtype instance Eq Key
derive newtype instance Show Key

newtype Value = Value String

derive instance Newtype Value _
derive newtype instance Eq Value
derive newtype instance Show Value

newtype HeaderValue = HeaderValue String

derive instance Newtype HeaderValue _
derive newtype instance Eq HeaderValue
derive newtype instance Show HeaderValue

newtype PartitionCount = PartitionCount Int

derive instance Newtype PartitionCount _
derive newtype instance Eq PartitionCount
derive newtype instance Ord PartitionCount
derive newtype instance Show PartitionCount

newtype ReplicationFactor = ReplicationFactor Int

derive instance Newtype ReplicationFactor _
derive newtype instance Eq ReplicationFactor
derive newtype instance Ord ReplicationFactor
derive newtype instance Show ReplicationFactor

newtype ErrorCode = ErrorCode Int

derive instance Newtype ErrorCode _
derive newtype instance Eq ErrorCode
derive newtype instance Show ErrorCode

-- Create Kafka client
type KafkaConfigImpl = (brokers :: Array BrokerAddress, clientId :: ClientId)

foreign import kafkaImpl :: forall opts. EffectFn1 { | opts } Kafka

createKafka :: forall opts opts_. Union opts opts_ KafkaConfigImpl => { | opts } -> Effect Kafka
createKafka opts = runEffectFn1 kafkaImpl opts
