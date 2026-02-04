module Yoga.Kafka.Admin where

import Prelude

import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Uncurried (EffectFn1, EffectFn2, runEffectFn1, runEffectFn2)
import Yoga.Kafka.Kafka (Kafka, PartitionCount, ReplicationFactor, TopicName)
import Promise (Promise)
import Promise.Aff (toAffE) as Promise

-- Opaque Admin type
foreign import data Admin :: Type

-- Create admin
foreign import createAdminImpl :: EffectFn1 Kafka Admin

createAdmin :: Kafka -> Effect Admin
createAdmin = runEffectFn1 createAdminImpl

-- Connect admin
foreign import connectAdminImpl :: EffectFn1 Admin (Promise Unit)

connect :: Admin -> Aff Unit
connect = runEffectFn1 connectAdminImpl >>> Promise.toAffE

-- Create topics
type TopicConfig =
  { topic :: TopicName
  , numPartitions :: PartitionCount
  , replicationFactor :: ReplicationFactor
  }

foreign import createTopicsImpl :: EffectFn2 Admin { topics :: Array TopicConfig } (Promise Boolean)

createTopics :: { topics :: Array TopicConfig } -> Admin -> Aff Boolean
createTopics opts admin = runEffectFn2 createTopicsImpl admin opts # Promise.toAffE

-- Delete topics
foreign import deleteTopicsImpl :: EffectFn2 Admin { topics :: Array TopicName } (Promise Unit)

deleteTopics :: { topics :: Array TopicName } -> Admin -> Aff Unit
deleteTopics opts admin = runEffectFn2 deleteTopicsImpl admin opts # Promise.toAffE

-- List topics
foreign import listTopicsImpl :: EffectFn1 Admin (Promise (Array TopicName))

listTopics :: Admin -> Aff (Array TopicName)
listTopics = runEffectFn1 listTopicsImpl >>> Promise.toAffE

-- Disconnect admin
foreign import disconnectAdminImpl :: EffectFn1 Admin (Promise Unit)

disconnect :: Admin -> Aff Unit
disconnect = runEffectFn1 disconnectAdminImpl >>> Promise.toAffE
