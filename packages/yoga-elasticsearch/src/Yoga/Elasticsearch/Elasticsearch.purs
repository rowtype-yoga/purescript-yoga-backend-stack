module Yoga.Elasticsearch.Elasticsearch where

import Prelude

import Data.Maybe (Maybe(..))
import Data.Newtype (class Newtype)
import Data.Nullable (Nullable)
import Data.Nullable as Nullable
import Data.Time.Duration (Milliseconds)
import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Uncurried (EffectFn1, EffectFn2, EffectFn3, EffectFn4, runEffectFn1, runEffectFn2, runEffectFn3, runEffectFn4)
import Foreign (Foreign)
import Prim.Row (class Union)
import Promise (Promise)
import Promise.Aff (toAffE) as Promise

-- Opaque Elasticsearch types
foreign import data Client :: Type

-- Newtypes for type safety

-- Connection configuration
newtype Node = Node String
derive instance Newtype Node _
derive newtype instance Eq Node
derive newtype instance Show Node

newtype ApiKeyId = ApiKeyId String
derive instance Newtype ApiKeyId _
derive newtype instance Eq ApiKeyId
derive newtype instance Show ApiKeyId

newtype ApiKeySecret = ApiKeySecret String
derive instance Newtype ApiKeySecret _
derive newtype instance Eq ApiKeySecret
derive newtype instance Show ApiKeySecret

newtype Username = Username String
derive instance Newtype Username _
derive newtype instance Eq Username
derive newtype instance Show Username

newtype Password = Password String
derive instance Newtype Password _
derive newtype instance Eq Password
derive newtype instance Show Password

newtype BearerToken = BearerToken String
derive instance Newtype BearerToken _
derive newtype instance Eq BearerToken
derive newtype instance Show BearerToken

newtype CloudId = CloudId String
derive instance Newtype CloudId _
derive newtype instance Eq CloudId
derive newtype instance Show CloudId

newtype RequestTimeout = RequestTimeout Milliseconds
derive instance Newtype RequestTimeout _
derive newtype instance Eq RequestTimeout
derive newtype instance Ord RequestTimeout
derive newtype instance Show RequestTimeout

newtype MaxRetries = MaxRetries Int
derive instance Newtype MaxRetries _
derive newtype instance Eq MaxRetries
derive newtype instance Ord MaxRetries
derive newtype instance Show MaxRetries

-- Index and document types
newtype IndexName = IndexName String
derive instance Newtype IndexName _
derive newtype instance Eq IndexName
derive newtype instance Show IndexName

newtype DocumentId = DocumentId String
derive instance Newtype DocumentId _
derive newtype instance Eq DocumentId
derive newtype instance Show DocumentId

newtype Routing = Routing String
derive instance Newtype Routing _
derive newtype instance Eq Routing
derive newtype instance Show Routing

newtype RefreshPolicy = RefreshPolicy String
derive instance Newtype RefreshPolicy _
derive newtype instance Eq RefreshPolicy
derive newtype instance Show RefreshPolicy

-- Convenience refresh policy constructors
refreshTrue :: RefreshPolicy
refreshTrue = RefreshPolicy "true"

refreshFalse :: RefreshPolicy
refreshFalse = RefreshPolicy "false"

refreshWaitFor :: RefreshPolicy
refreshWaitFor = RefreshPolicy "wait_for"

-- Search types
newtype ScrollId = ScrollId String
derive instance Newtype ScrollId _
derive newtype instance Eq ScrollId
derive newtype instance Show ScrollId

newtype ScrollTimeout = ScrollTimeout String
derive instance Newtype ScrollTimeout _
derive newtype instance Eq ScrollTimeout
derive newtype instance Show ScrollTimeout

-- Cluster types
newtype ClusterName = ClusterName String
derive instance Newtype ClusterName _
derive newtype instance Eq ClusterName
derive newtype instance Show ClusterName

newtype ClusterUUID = ClusterUUID String
derive instance Newtype ClusterUUID _
derive newtype instance Eq ClusterUUID
derive newtype instance Show ClusterUUID

newtype Version = Version String
derive instance Newtype Version _
derive newtype instance Eq Version
derive newtype instance Show Version

newtype BuildHash = BuildHash String
derive instance Newtype BuildHash _
derive newtype instance Eq BuildHash
derive newtype instance Show BuildHash

-- Document and query types
newtype Document = Document Foreign
derive instance Newtype Document _

newtype Query = Query Foreign
derive instance Newtype Query _

newtype Script = Script Foreign
derive instance Newtype Script _

newtype Mappings = Mappings Foreign
derive instance Newtype Mappings _

newtype Settings = Settings Foreign
derive instance Newtype Settings _

newtype Sort = Sort Foreign
derive instance Newtype Sort _

-- Document metadata types
newtype DocumentVersion = DocumentVersion Int
derive instance Newtype DocumentVersion _
derive newtype instance Eq DocumentVersion
derive newtype instance Ord DocumentVersion
derive newtype instance Show DocumentVersion

newtype SequenceNumber = SequenceNumber Int
derive instance Newtype SequenceNumber _
derive newtype instance Eq SequenceNumber
derive newtype instance Ord SequenceNumber
derive newtype instance Show SequenceNumber

newtype PrimaryTerm = PrimaryTerm Int
derive instance Newtype PrimaryTerm _
derive newtype instance Eq PrimaryTerm
derive newtype instance Ord PrimaryTerm
derive newtype instance Show PrimaryTerm

newtype IndexResult = IndexResult String
derive instance Newtype IndexResult _
derive newtype instance Eq IndexResult
derive newtype instance Show IndexResult

-- Shard types
newtype ShardCount = ShardCount Int
derive instance Newtype ShardCount _
derive newtype instance Eq ShardCount
derive newtype instance Ord ShardCount
derive newtype instance Show ShardCount

type ShardInfo =
  { total :: ShardCount
  , successful :: ShardCount
  , failed :: ShardCount
  }

-- Search result types
newtype Score = Score Number
derive instance Newtype Score _
derive newtype instance Eq Score
derive newtype instance Ord Score
derive newtype instance Show Score

newtype TookMilliseconds = TookMilliseconds Int
derive instance Newtype TookMilliseconds _
derive newtype instance Eq TookMilliseconds
derive newtype instance Ord TookMilliseconds
derive newtype instance Show TookMilliseconds

newtype HitCount = HitCount Int
derive instance Newtype HitCount _
derive newtype instance Eq HitCount
derive newtype instance Ord HitCount
derive newtype instance Show HitCount

newtype SkippedCount = SkippedCount Int
derive instance Newtype SkippedCount _
derive newtype instance Eq SkippedCount
derive newtype instance Ord SkippedCount
derive newtype instance Show SkippedCount

-- Operation configuration types
newtype RetryCount = RetryCount Int
derive instance Newtype RetryCount _
derive newtype instance Eq RetryCount
derive newtype instance Ord RetryCount
derive newtype instance Show RetryCount

newtype FromOffset = FromOffset Int
derive instance Newtype FromOffset _
derive newtype instance Eq FromOffset
derive newtype instance Ord FromOffset
derive newtype instance Show FromOffset

newtype ResultSize = ResultSize Int
derive instance Newtype ResultSize _
derive newtype instance Eq ResultSize
derive newtype instance Ord ResultSize
derive newtype instance Show ResultSize

-- Authentication configuration
type ApiKeyAuth = 
  { id :: ApiKeyId
  , api_key :: ApiKeySecret
  }

type BasicAuth = 
  { username :: Username
  , password :: Password
  }

-- Client configuration
type ClientConfigImpl = 
  ( node :: Node
  , nodes :: Array Node
  , cloud :: { id :: CloudId }
  , auth :: { apiKey :: ApiKeyAuth }
  , basicAuth :: BasicAuth
  , bearerToken :: BearerToken
  , requestTimeout :: RequestTimeout
  , maxRetries :: MaxRetries
  , compression :: Boolean
  , ssl :: { rejectUnauthorized :: Boolean }
  )

foreign import createClientImpl :: forall opts. EffectFn1 { | opts } Client

createClient :: forall opts opts_. Union opts opts_ ClientConfigImpl => { | opts } -> Effect Client
createClient opts = runEffectFn1 createClientImpl opts

-- Info operation
type ClusterInfo = 
  { name :: ClusterName
  , cluster_name :: ClusterName
  , cluster_uuid :: ClusterUUID
  , version :: 
    { number :: Version
    , build_flavor :: String
    , build_type :: String
    , build_hash :: BuildHash
    , build_date :: String
    , build_snapshot :: Boolean
    , lucene_version :: Version
    , minimum_wire_compatibility_version :: Version
    , minimum_index_compatibility_version :: Version
    }
  , tagline :: String
  }

foreign import infoImpl :: EffectFn1 Client (Promise ClusterInfo)

info :: Client -> Aff ClusterInfo
info = runEffectFn1 infoImpl >>> Promise.toAffE

-- Ping operation
foreign import pingImpl :: EffectFn1 Client (Promise Boolean)

ping :: Client -> Aff Boolean
ping = runEffectFn1 pingImpl >>> Promise.toAffE

-- Index operations

-- Create index
type CreateIndexOptionsImpl = 
  ( mappings :: Mappings
  , settings :: Settings
  )

type CreateIndexResponse = 
  { acknowledged :: Boolean
  , shards_acknowledged :: Boolean
  , index :: IndexName
  }

foreign import createIndexImpl :: forall opts. EffectFn3 Client IndexName { | opts } (Promise CreateIndexResponse)

createIndex :: forall opts opts_. Union opts opts_ CreateIndexOptionsImpl => IndexName -> { | opts } -> Client -> Aff CreateIndexResponse
createIndex index opts client = runEffectFn3 createIndexImpl client index opts # Promise.toAffE

-- Delete index
type DeleteIndexResponse = 
  { acknowledged :: Boolean
  }

foreign import deleteIndexImpl :: EffectFn2 Client IndexName (Promise DeleteIndexResponse)

deleteIndex :: IndexName -> Client -> Aff DeleteIndexResponse
deleteIndex index client = runEffectFn2 deleteIndexImpl client index # Promise.toAffE

-- Check if index exists
foreign import indexExistsImpl :: EffectFn2 Client IndexName (Promise Boolean)

indexExists :: IndexName -> Client -> Aff Boolean
indexExists index client = runEffectFn2 indexExistsImpl client index # Promise.toAffE

-- Document operations

-- Index a document
type IndexDocumentOptionsImpl = 
  ( id :: DocumentId
  , routing :: Routing
  , refresh :: RefreshPolicy
  , timeout :: RequestTimeout
  )

type IndexDocumentResponse = 
  { _index :: IndexName
  , _id :: DocumentId
  , _version :: DocumentVersion
  , result :: IndexResult
  , _shards :: ShardInfo
  }

foreign import indexDocumentImpl :: forall opts. EffectFn4 Client IndexName Document { | opts } (Promise IndexDocumentResponse)

indexDocument :: forall opts opts_. Union opts opts_ IndexDocumentOptionsImpl => IndexName -> Document -> { | opts } -> Client -> Aff IndexDocumentResponse
indexDocument index doc opts client = runEffectFn4 indexDocumentImpl client index doc opts # Promise.toAffE

-- Get document
type GetDocumentOptionsImpl = 
  ( routing :: Routing
  , _source :: Boolean
  , _source_includes :: Array String
  , _source_excludes :: Array String
  )

type GetDocumentResponse = 
  { _index :: IndexName
  , _id :: DocumentId
  , _version :: DocumentVersion
  , _seq_no :: SequenceNumber
  , _primary_term :: PrimaryTerm
  , found :: Boolean
  , _source :: Nullable Foreign
  }

foreign import getDocumentImpl :: forall opts. EffectFn4 Client IndexName DocumentId { | opts } (Promise GetDocumentResponse)

getDocument :: forall opts opts_. Union opts opts_ GetDocumentOptionsImpl => IndexName -> DocumentId -> { | opts } -> Client -> Aff GetDocumentResponse
getDocument index docId opts client = runEffectFn4 getDocumentImpl client index docId opts # Promise.toAffE

-- Get document simple (returns Maybe)
getDocumentMaybe :: IndexName -> DocumentId -> Client -> Aff (Maybe Foreign)
getDocumentMaybe index docId client = do
  result <- getDocument index docId {} client
  pure $ if result.found
    then Nullable.toMaybe result._source
    else Nothing

-- Update document
type UpdateDocumentOptionsImpl = 
  ( doc :: Document
  , script :: Script
  , routing :: Routing
  , refresh :: RefreshPolicy
  , retry_on_conflict :: RetryCount
  )

type UpdateDocumentResponse = 
  { _index :: IndexName
  , _id :: DocumentId
  , _version :: DocumentVersion
  , result :: IndexResult
  }

foreign import updateDocumentImpl :: forall opts. EffectFn4 Client IndexName DocumentId { | opts } (Promise UpdateDocumentResponse)

updateDocument :: forall opts opts_. Union opts opts_ UpdateDocumentOptionsImpl => IndexName -> DocumentId -> { | opts } -> Client -> Aff UpdateDocumentResponse
updateDocument index docId opts client = runEffectFn4 updateDocumentImpl client index docId opts # Promise.toAffE

-- Delete document
type DeleteDocumentOptionsImpl = 
  ( routing :: Routing
  , refresh :: RefreshPolicy
  )

type DeleteDocumentResponse = 
  { _index :: IndexName
  , _id :: DocumentId
  , _version :: DocumentVersion
  , result :: IndexResult
  }

foreign import deleteDocumentImpl :: forall opts. EffectFn4 Client IndexName DocumentId { | opts } (Promise DeleteDocumentResponse)

deleteDocument :: forall opts opts_. Union opts opts_ DeleteDocumentOptionsImpl => IndexName -> DocumentId -> { | opts } -> Client -> Aff DeleteDocumentResponse
deleteDocument index docId opts client = runEffectFn4 deleteDocumentImpl client index docId opts # Promise.toAffE

-- Search operations

type SearchOptionsImpl = 
  ( query :: Query
  , from :: FromOffset
  , size :: ResultSize
  , sort :: Sort
  , _source :: Boolean
  , _source_includes :: Array String
  , _source_excludes :: Array String
  , track_total_hits :: Boolean
  , scroll :: ScrollTimeout
  , routing :: Routing
  )

type SearchHit = 
  { _index :: IndexName
  , _id :: DocumentId
  , _score :: Nullable Score
  , _source :: Foreign
  }

type SearchResponse = 
  { took :: TookMilliseconds
  , timed_out :: Boolean
  , _shards :: 
    { total :: ShardCount
    , successful :: ShardCount
    , skipped :: SkippedCount
    , failed :: ShardCount
    }
  , hits :: 
    { total :: { value :: HitCount, relation :: String }
    , max_score :: Nullable Score
    , hits :: Array SearchHit
    }
  , _scroll_id :: Nullable ScrollId
  }

foreign import searchImpl :: forall opts. EffectFn3 Client (Nullable IndexName) { | opts } (Promise SearchResponse)

search :: forall opts opts_. Union opts opts_ SearchOptionsImpl => Maybe IndexName -> { | opts } -> Client -> Aff SearchResponse
search index opts client = runEffectFn3 searchImpl client (Nullable.toNullable index) opts # Promise.toAffE

-- Search all indices
searchAll :: forall opts opts_. Union opts opts_ SearchOptionsImpl => { | opts } -> Client -> Aff SearchResponse
searchAll opts client = search Nothing opts client

-- Scroll API for pagination
type ScrollOptionsImpl = 
  ( scroll :: ScrollTimeout
  )

foreign import scrollImpl :: forall opts. EffectFn3 Client ScrollId { | opts } (Promise SearchResponse)

scroll :: forall opts opts_. Union opts opts_ ScrollOptionsImpl => ScrollId -> { | opts } -> Client -> Aff SearchResponse
scroll scrollId opts client = runEffectFn3 scrollImpl client scrollId opts # Promise.toAffE

-- Clear scroll
foreign import clearScrollImpl :: EffectFn2 Client ScrollId (Promise { succeeded :: Boolean })

clearScroll :: ScrollId -> Client -> Aff { succeeded :: Boolean }
clearScroll scrollId client = runEffectFn2 clearScrollImpl client scrollId # Promise.toAffE

-- Bulk operations

type BulkOperation = Foreign

type BulkResponse = 
  { took :: TookMilliseconds
  , errors :: Boolean
  , items :: Array Foreign
  }

foreign import bulkImpl :: EffectFn2 Client (Array BulkOperation) (Promise BulkResponse)

bulk :: Array BulkOperation -> Client -> Aff BulkResponse
bulk operations client = runEffectFn2 bulkImpl client operations # Promise.toAffE

-- Count documents
type CountOptionsImpl = 
  ( query :: Query
  )

type CountResponse = 
  { count :: HitCount
  }

foreign import countImpl :: forall opts. EffectFn3 Client (Nullable IndexName) { | opts } (Promise CountResponse)

count :: forall opts opts_. Union opts opts_ CountOptionsImpl => Maybe IndexName -> { | opts } -> Client -> Aff CountResponse
count index opts client = runEffectFn3 countImpl client (Nullable.toNullable index) opts # Promise.toAffE

-- Refresh index
foreign import refreshImpl :: EffectFn2 Client IndexName (Promise { _shards :: ShardInfo })

refresh :: IndexName -> Client -> Aff { _shards :: ShardInfo }
refresh index client = runEffectFn2 refreshImpl client index # Promise.toAffE

-- Close client
foreign import closeImpl :: EffectFn1 Client (Promise Unit)

close :: Client -> Aff Unit
close = runEffectFn1 closeImpl >>> Promise.toAffE
