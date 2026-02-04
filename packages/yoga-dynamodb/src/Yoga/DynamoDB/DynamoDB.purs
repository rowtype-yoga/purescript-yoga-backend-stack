module Yoga.DynamoDB.DynamoDB where

import Prelude

import Data.Maybe (Maybe(..))
import Data.Newtype (class Newtype)
import Data.Nullable (Nullable, toMaybe, toNullable)
import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Uncurried (EffectFn1, EffectFn2, runEffectFn1, runEffectFn2)
import Foreign (Foreign, unsafeToForeign)
import Foreign.Object (Object)
import Foreign.Object as Object
import Prim.Row (class Union)
import Promise (Promise)
import Promise.Aff (toAffE) as Promise
import Unsafe.Coerce (unsafeCoerce)

-- Opaque DynamoDB types
foreign import data DynamoDB :: Type
foreign import data DynamoDBItem :: Type

-- Newtypes for type safety

-- Connection configuration
newtype Region = Region String

derive instance Newtype Region _
derive newtype instance Eq Region
derive newtype instance Show Region

newtype Endpoint = Endpoint String

derive instance Newtype Endpoint _
derive newtype instance Eq Endpoint
derive newtype instance Show Endpoint

newtype AccessKeyId = AccessKeyId String

derive instance Newtype AccessKeyId _
derive newtype instance Eq AccessKeyId
derive newtype instance Show AccessKeyId

newtype SecretAccessKey = SecretAccessKey String

derive instance Newtype SecretAccessKey _
derive newtype instance Eq SecretAccessKey
derive newtype instance Show SecretAccessKey

newtype SessionToken = SessionToken String

derive instance Newtype SessionToken _
derive newtype instance Eq SessionToken
derive newtype instance Show SessionToken

-- Table and item types
newtype TableName = TableName String

derive instance Newtype TableName _
derive newtype instance Eq TableName
derive newtype instance Show TableName

newtype IndexName = IndexName String

derive instance Newtype IndexName _
derive newtype instance Eq IndexName
derive newtype instance Show IndexName

newtype AttributeName = AttributeName String

derive instance Newtype AttributeName _
derive newtype instance Eq AttributeName
derive newtype instance Show AttributeName

newtype AttributeValue = AttributeValue Foreign

derive instance Newtype AttributeValue _

-- Expression types
newtype KeyConditionExpression = KeyConditionExpression String

derive instance Newtype KeyConditionExpression _
derive newtype instance Eq KeyConditionExpression
derive newtype instance Show KeyConditionExpression

newtype FilterExpression = FilterExpression String

derive instance Newtype FilterExpression _
derive newtype instance Eq FilterExpression
derive newtype instance Show FilterExpression

newtype ProjectionExpression = ProjectionExpression String

derive instance Newtype ProjectionExpression _
derive newtype instance Eq ProjectionExpression
derive newtype instance Show ProjectionExpression

newtype ConditionExpression = ConditionExpression String

derive instance Newtype ConditionExpression _
derive newtype instance Eq ConditionExpression
derive newtype instance Show ConditionExpression

newtype UpdateExpression = UpdateExpression String

derive instance Newtype UpdateExpression _
derive newtype instance Eq UpdateExpression
derive newtype instance Show UpdateExpression

-- Pagination types
newtype Limit = Limit Int

derive instance Newtype Limit _
derive newtype instance Eq Limit
derive newtype instance Ord Limit
derive newtype instance Show Limit

-- Type-safe item conversion
toItem :: Foreign -> DynamoDBItem
toItem = unsafeCoerce

fromItem :: DynamoDBItem -> Foreign
fromItem = unsafeCoerce

-- Expression attribute values/names
type ExpressionAttributeValues = Object Foreign
type ExpressionAttributeNames = Object String

-- Helper functions for building expression attributes
attrNames :: forall r. Record r -> ExpressionAttributeNames
attrNames = unsafeCoerce

attrValues :: forall r. Record r -> ExpressionAttributeValues
attrValues rec = unsafeCoerce $ map unsafeToForeign (unsafeCoerce rec :: Object _)

-- Single attribute helpers
attrName :: String -> String -> ExpressionAttributeNames
attrName placeholder name = Object.singleton placeholder name

attrValue :: forall a. String -> a -> ExpressionAttributeValues
attrValue placeholder value = Object.singleton placeholder (unsafeToForeign value)

-- Create DynamoDB client
type DynamoDBConfigImpl =
  ( region :: Region
  , endpoint :: Endpoint
  , credentials ::
      { accessKeyId :: AccessKeyId
      , secretAccessKey :: SecretAccessKey
      , sessionToken :: SessionToken
      }
  , maxAttempts :: Int
  , requestTimeout :: Int
  )

foreign import createDynamoDBImpl :: forall opts. EffectFn1 { | opts } DynamoDB

createDynamoDB :: forall opts opts_. Union opts opts_ DynamoDBConfigImpl => { | opts } -> Effect DynamoDB
createDynamoDB opts = runEffectFn1 createDynamoDBImpl opts

-- Put item
type PutItemOptionsImpl =
  ( conditionExpression :: ConditionExpression
  , expressionAttributeValues :: ExpressionAttributeValues
  , expressionAttributeNames :: ExpressionAttributeNames
  , returnValues :: String
  )

type PutItemResult =
  { attributes :: Maybe DynamoDBItem
  }

foreign import putItemImpl :: forall opts. EffectFn2 DynamoDB { tableName :: TableName, item :: DynamoDBItem | opts } (Promise { attributes :: Nullable DynamoDBItem })

putItem :: TableName -> DynamoDBItem -> DynamoDB -> Aff PutItemResult
putItem tableName item db = do
  result <- runEffectFn2 putItemImpl db { tableName, item } # Promise.toAffE
  pure { attributes: toMaybe result.attributes }

putItemWithOptions :: forall opts opts_. Union opts opts_ PutItemOptionsImpl => TableName -> DynamoDBItem -> { | opts } -> DynamoDB -> Aff PutItemResult
putItemWithOptions tableName item opts db = do
  result <- runEffectFn2 putItemImpl db { tableName, item, conditionExpression: unsafeCoerce opts, expressionAttributeValues: unsafeCoerce opts, expressionAttributeNames: unsafeCoerce opts, returnValues: unsafeCoerce opts } # Promise.toAffE
  pure { attributes: toMaybe result.attributes }

-- Get item
type GetItemOptionsImpl =
  ( consistentRead :: Boolean
  , projectionExpression :: ProjectionExpression
  , expressionAttributeNames :: ExpressionAttributeNames
  )

foreign import getItemImpl :: forall opts. EffectFn2 DynamoDB { tableName :: TableName, key :: DynamoDBItem | opts } (Promise { item :: Nullable DynamoDBItem })

getItem :: TableName -> DynamoDBItem -> DynamoDB -> Aff (Maybe DynamoDBItem)
getItem tableName key db = do
  result <- runEffectFn2 getItemImpl db { tableName, key } # Promise.toAffE
  pure $ toMaybe result.item

getItemWithOptions :: forall opts opts_. Union opts opts_ GetItemOptionsImpl => TableName -> DynamoDBItem -> { | opts } -> DynamoDB -> Aff (Maybe DynamoDBItem)
getItemWithOptions tableName key opts db = do
  result <- runEffectFn2 getItemImpl db { tableName, key, consistentRead: unsafeCoerce opts, projectionExpression: unsafeCoerce opts, expressionAttributeNames: unsafeCoerce opts } # Promise.toAffE
  pure $ toMaybe result.item

-- Update item
type UpdateItemOptionsImpl =
  ( conditionExpression :: ConditionExpression
  , expressionAttributeValues :: ExpressionAttributeValues
  , expressionAttributeNames :: ExpressionAttributeNames
  , returnValues :: String
  )

type UpdateItemResult =
  { attributes :: Maybe DynamoDBItem
  }

foreign import updateItemImpl :: forall opts. EffectFn2 DynamoDB { tableName :: TableName, key :: DynamoDBItem, updateExpression :: UpdateExpression | opts } (Promise { attributes :: Nullable DynamoDBItem })

updateItem :: TableName -> DynamoDBItem -> UpdateExpression -> DynamoDB -> Aff UpdateItemResult
updateItem tableName key updateExpr db = do
  result <- runEffectFn2 updateItemImpl db { tableName, key, updateExpression: updateExpr } # Promise.toAffE
  pure { attributes: toMaybe result.attributes }

updateItemWithOptions :: forall opts opts_. Union opts opts_ UpdateItemOptionsImpl => TableName -> DynamoDBItem -> UpdateExpression -> { | opts } -> DynamoDB -> Aff UpdateItemResult
updateItemWithOptions tableName key updateExpr opts db = do
  result <- runEffectFn2 updateItemImpl db { tableName, key, updateExpression: updateExpr, conditionExpression: unsafeCoerce opts, expressionAttributeValues: unsafeCoerce opts, expressionAttributeNames: unsafeCoerce opts, returnValues: unsafeCoerce opts } # Promise.toAffE
  pure { attributes: toMaybe result.attributes }

-- Delete item
type DeleteItemOptionsImpl =
  ( conditionExpression :: ConditionExpression
  , expressionAttributeValues :: ExpressionAttributeValues
  , expressionAttributeNames :: ExpressionAttributeNames
  , returnValues :: String
  )

type DeleteItemResult =
  { attributes :: Maybe DynamoDBItem
  }

foreign import deleteItemImpl :: forall opts. EffectFn2 DynamoDB { tableName :: TableName, key :: DynamoDBItem | opts } (Promise { attributes :: Nullable DynamoDBItem })

deleteItem :: TableName -> DynamoDBItem -> DynamoDB -> Aff DeleteItemResult
deleteItem tableName key db = do
  result <- runEffectFn2 deleteItemImpl db { tableName, key } # Promise.toAffE
  pure { attributes: toMaybe result.attributes }

deleteItemWithOptions :: forall opts opts_. Union opts opts_ DeleteItemOptionsImpl => TableName -> DynamoDBItem -> { | opts } -> DynamoDB -> Aff DeleteItemResult
deleteItemWithOptions tableName key opts db = do
  result <- runEffectFn2 deleteItemImpl db { tableName, key, conditionExpression: unsafeCoerce opts, expressionAttributeValues: unsafeCoerce opts, expressionAttributeNames: unsafeCoerce opts, returnValues: unsafeCoerce opts } # Promise.toAffE
  pure { attributes: toMaybe result.attributes }

-- Query
type QueryOptionsImpl =
  ( indexName :: IndexName
  , filterExpression :: FilterExpression
  , projectionExpression :: ProjectionExpression
  , expressionAttributeValues :: ExpressionAttributeValues
  , expressionAttributeNames :: ExpressionAttributeNames
  , consistentRead :: Boolean
  , scanIndexForward :: Boolean
  , limit :: Limit
  , exclusiveStartKey :: DynamoDBItem
  )

type QueryResult =
  { items :: Array DynamoDBItem
  , count :: Int
  , scannedCount :: Int
  , lastEvaluatedKey :: Maybe DynamoDBItem
  }

foreign import queryImpl :: forall opts. EffectFn2 DynamoDB { tableName :: TableName, keyConditionExpression :: KeyConditionExpression | opts } (Promise { items :: Array DynamoDBItem, count :: Int, scannedCount :: Int, lastEvaluatedKey :: Nullable DynamoDBItem })

query :: TableName -> KeyConditionExpression -> DynamoDB -> Aff QueryResult
query tableName keyCondition db = do
  result <- runEffectFn2 queryImpl db { tableName, keyConditionExpression: keyCondition } # Promise.toAffE
  pure
    { items: result.items
    , count: result.count
    , scannedCount: result.scannedCount
    , lastEvaluatedKey: toMaybe result.lastEvaluatedKey
    }

queryWithOptions :: forall opts opts_. Union opts opts_ QueryOptionsImpl => TableName -> KeyConditionExpression -> { | opts } -> DynamoDB -> Aff QueryResult
queryWithOptions tableName keyCondition opts db = do
  result <- runEffectFn2 queryImpl db { tableName, keyConditionExpression: keyCondition, indexName: unsafeCoerce opts, filterExpression: unsafeCoerce opts, projectionExpression: unsafeCoerce opts, expressionAttributeValues: unsafeCoerce opts, expressionAttributeNames: unsafeCoerce opts, consistentRead: unsafeCoerce opts, scanIndexForward: unsafeCoerce opts, limit: unsafeCoerce opts, exclusiveStartKey: unsafeCoerce opts } # Promise.toAffE
  pure
    { items: result.items
    , count: result.count
    , scannedCount: result.scannedCount
    , lastEvaluatedKey: toMaybe result.lastEvaluatedKey
    }

-- Scan
type ScanOptionsImpl =
  ( indexName :: IndexName
  , filterExpression :: FilterExpression
  , projectionExpression :: ProjectionExpression
  , expressionAttributeValues :: ExpressionAttributeValues
  , expressionAttributeNames :: ExpressionAttributeNames
  , consistentRead :: Boolean
  , limit :: Limit
  , exclusiveStartKey :: DynamoDBItem
  )

type ScanResult =
  { items :: Array DynamoDBItem
  , count :: Int
  , scannedCount :: Int
  , lastEvaluatedKey :: Maybe DynamoDBItem
  }

foreign import scanImpl :: forall opts. EffectFn2 DynamoDB { tableName :: TableName | opts } (Promise { items :: Array DynamoDBItem, count :: Int, scannedCount :: Int, lastEvaluatedKey :: Nullable DynamoDBItem })

scan :: TableName -> DynamoDB -> Aff ScanResult
scan tableName db = do
  result <- runEffectFn2 scanImpl db { tableName } # Promise.toAffE
  pure
    { items: result.items
    , count: result.count
    , scannedCount: result.scannedCount
    , lastEvaluatedKey: toMaybe result.lastEvaluatedKey
    }

scanWithOptions :: forall opts opts_. Union opts opts_ ScanOptionsImpl => TableName -> { | opts } -> DynamoDB -> Aff ScanResult
scanWithOptions tableName opts db = do
  result <- runEffectFn2 scanImpl db { tableName, indexName: unsafeCoerce opts, filterExpression: unsafeCoerce opts, projectionExpression: unsafeCoerce opts, expressionAttributeValues: unsafeCoerce opts, expressionAttributeNames: unsafeCoerce opts, consistentRead: unsafeCoerce opts, limit: unsafeCoerce opts, exclusiveStartKey: unsafeCoerce opts } # Promise.toAffE
  pure
    { items: result.items
    , count: result.count
    , scannedCount: result.scannedCount
    , lastEvaluatedKey: toMaybe result.lastEvaluatedKey
    }

-- Batch operations types
type BatchGetRequestItems = Object { keys :: Array DynamoDBItem, projectionExpression :: Maybe ProjectionExpression }
type BatchGetResponses = Object (Array DynamoDBItem)

type BatchGetResult =
  { responses :: BatchGetResponses
  , unprocessedKeys :: Object (Array DynamoDBItem)
  }

foreign import batchGetItemImpl :: EffectFn2 DynamoDB Foreign (Promise { responses :: Foreign, unprocessedKeys :: Foreign })

batchGetItem :: Foreign -> DynamoDB -> Aff BatchGetResult
batchGetItem requestItems db = do
  result <- runEffectFn2 batchGetItemImpl db requestItems # Promise.toAffE
  pure 
    { responses: unsafeCoerce result.responses
    , unprocessedKeys: unsafeCoerce result.unprocessedKeys
    }

-- Batch write types
type PutRequest = { item :: DynamoDBItem }
type DeleteRequest = { key :: DynamoDBItem }
type WriteRequest = { putRequest :: Maybe PutRequest, deleteRequest :: Maybe DeleteRequest }

type BatchWriteResult =
  { unprocessedItems :: Object (Array WriteRequest)
  }

foreign import batchWriteItemImpl :: EffectFn2 DynamoDB Foreign (Promise { unprocessedItems :: Foreign })

batchWriteItem :: Foreign -> DynamoDB -> Aff BatchWriteResult
batchWriteItem requestItems db = do
  result <- runEffectFn2 batchWriteItemImpl db requestItems # Promise.toAffE
  pure { unprocessedItems: unsafeCoerce result.unprocessedItems }

-- Transaction types
type TransactGetItem = { tableName :: TableName, key :: DynamoDBItem }
type TransactPutItem = { tableName :: TableName, item :: DynamoDBItem, conditionExpression :: Maybe ConditionExpression }
type TransactUpdateItem = { tableName :: TableName, key :: DynamoDBItem, updateExpression :: UpdateExpression }
type TransactDeleteItem = { tableName :: TableName, key :: DynamoDBItem, conditionExpression :: Maybe ConditionExpression }

type TransactGetResult =
  { responses :: Array { item :: Maybe DynamoDBItem }
  }

foreign import transactGetItemsImpl :: EffectFn2 DynamoDB (Array Foreign) (Promise { responses :: Array { item :: Nullable DynamoDBItem } })

transactGetItems :: Array Foreign -> DynamoDB -> Aff TransactGetResult
transactGetItems items db = do
  result <- runEffectFn2 transactGetItemsImpl db items # Promise.toAffE
  pure { responses: map (\r -> { item: toMaybe r.item }) result.responses }

foreign import transactWriteItemsImpl :: EffectFn2 DynamoDB (Array Foreign) (Promise Unit)

transactWriteItems :: Array Foreign -> DynamoDB -> Aff Unit
transactWriteItems items db = runEffectFn2 transactWriteItemsImpl db items # Promise.toAffE

-- Table operations

-- Table schema types
type AttributeDefinition = { attributeName :: String, attributeType :: String }
type KeySchemaElement = { attributeName :: String, keyType :: String }

type ProvisionedThroughput = 
  { readCapacityUnits :: Int
  , writeCapacityUnits :: Int
  }

type GlobalSecondaryIndex =
  { indexName :: IndexName
  , keySchema :: Array KeySchemaElement
  , projection :: { projectionType :: String }
  , provisionedThroughput :: Maybe ProvisionedThroughput
  }

type LocalSecondaryIndex =
  { indexName :: IndexName
  , keySchema :: Array KeySchemaElement
  , projection :: { projectionType :: String }
  }

type StreamSpecification =
  { streamEnabled :: Boolean
  , streamViewType :: String
  }

type Tag = { key :: String, value :: String }

type CreateTableOptionsImpl =
  ( billingMode :: String
  , provisionedThroughput :: ProvisionedThroughput
  , globalSecondaryIndexes :: Array GlobalSecondaryIndex
  , localSecondaryIndexes :: Array LocalSecondaryIndex
  , streamSpecification :: StreamSpecification
  , tags :: Array Tag
  )

foreign import createTableImpl :: forall opts. EffectFn2 DynamoDB { tableName :: TableName, attributeDefinitions :: Array AttributeDefinition, keySchema :: Array KeySchemaElement | opts } (Promise Foreign)

createTable :: forall opts opts_. Union opts opts_ CreateTableOptionsImpl => { tableName :: TableName, attributeDefinitions :: Array AttributeDefinition, keySchema :: Array KeySchemaElement | opts } -> DynamoDB -> Aff Foreign
createTable input db = runEffectFn2 createTableImpl db input # Promise.toAffE

-- Describe table
foreign import describeTableImpl :: EffectFn2 DynamoDB TableName (Promise Foreign)

describeTable :: TableName -> DynamoDB -> Aff Foreign
describeTable tableName db = runEffectFn2 describeTableImpl db tableName # Promise.toAffE

-- Delete table
foreign import deleteTableImpl :: EffectFn2 DynamoDB TableName (Promise Foreign)

deleteTable :: TableName -> DynamoDB -> Aff Foreign
deleteTable tableName db = runEffectFn2 deleteTableImpl db tableName # Promise.toAffE

-- List tables
type ListTablesResult =
  { tableNames :: Array TableName
  , lastEvaluatedTableName :: Maybe TableName
  }

foreign import listTablesImpl :: EffectFn2 DynamoDB (Nullable Int) (Promise { tableNames :: Array TableName, lastEvaluatedTableName :: Nullable TableName })

listTables :: DynamoDB -> Aff ListTablesResult
listTables db = do
  result <- runEffectFn2 listTablesImpl db (toNullable Nothing) # Promise.toAffE
  pure { tableNames: result.tableNames, lastEvaluatedTableName: toMaybe result.lastEvaluatedTableName }

listTablesLimit :: Int -> DynamoDB -> Aff ListTablesResult
listTablesLimit limit db = do
  result <- runEffectFn2 listTablesImpl db (toNullable $ Just limit) # Promise.toAffE
  pure { tableNames: result.tableNames, lastEvaluatedTableName: toMaybe result.lastEvaluatedTableName }
