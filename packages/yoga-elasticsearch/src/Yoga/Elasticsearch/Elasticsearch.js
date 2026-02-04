import { Client } from '@elastic/elasticsearch';

// Create Elasticsearch client
export const createClientImpl = (config) => {
  const clientConfig = {};

  // Handle node/nodes
  if (config.node) {
    clientConfig.node = config.node;
  }
  if (config.nodes) {
    clientConfig.nodes = config.nodes;
  }

  // Handle cloud configuration
  if (config.cloud) {
    clientConfig.cloud = config.cloud;
  }

  // Handle authentication
  if (config.auth && config.auth.apiKey) {
    clientConfig.auth = {
      apiKey: {
        id: config.auth.apiKey.id,
        api_key: config.auth.apiKey.api_key
      }
    };
  } else if (config.basicAuth) {
    clientConfig.auth = {
      username: config.basicAuth.username,
      password: config.basicAuth.password
    };
  } else if (config.bearerToken) {
    clientConfig.auth = {
      bearer: config.bearerToken
    };
  }

  // Handle timeouts and retries
  if (config.requestTimeout) {
    clientConfig.requestTimeout = config.requestTimeout;
  }
  if (config.maxRetries) {
    clientConfig.maxRetries = config.maxRetries;
  }

  // Handle compression
  if (config.compression !== undefined) {
    clientConfig.compression = config.compression;
  }

  // Handle SSL
  if (config.ssl) {
    clientConfig.ssl = config.ssl;
  }

  // Pass through any other options
  Object.keys(config).forEach(key => {
    if (!clientConfig[key] && key !== 'basicAuth' && key !== 'bearerToken') {
      clientConfig[key] = config[key];
    }
  });

  return new Client(clientConfig);
};

// Info operation
export const infoImpl = async (client) => {
  const response = await client.info();
  return {
    name: response.name,
    cluster_name: response.cluster_name,
    cluster_uuid: response.cluster_uuid,
    version: {
      number: response.version.number,
      build_flavor: response.version.build_flavor,
      build_type: response.version.build_type,
      build_hash: response.version.build_hash,
      build_date: response.version.build_date,
      build_snapshot: response.version.build_snapshot,
      lucene_version: response.version.lucene_version,
      minimum_wire_compatibility_version: response.version.minimum_wire_compatibility_version,
      minimum_index_compatibility_version: response.version.minimum_index_compatibility_version
    },
    tagline: response.tagline
  };
};

// Ping operation
export const pingImpl = async (client) => {
  try {
    await client.ping();
    return true;
  } catch (err) {
    return false;
  }
};

// Index operations

// Create index
export const createIndexImpl = async (client, index, options) => {
  const response = await client.indices.create({
    index,
    ...options
  });
  
  return {
    acknowledged: response.acknowledged,
    shards_acknowledged: response.shards_acknowledged,
    index: response.index
  };
};

// Delete index
export const deleteIndexImpl = async (client, index) => {
  const response = await client.indices.delete({ index });
  return {
    acknowledged: response.acknowledged
  };
};

// Check if index exists
export const indexExistsImpl = async (client, index) => {
  try {
    const response = await client.indices.exists({ index });
    return response;
  } catch (err) {
    return false;
  }
};

// Document operations

// Index a document
export const indexDocumentImpl = async (client, index, document, options) => {
  const response = await client.index({
    index,
    document,
    ...options
  });

  return {
    _index: response._index,
    _id: response._id,
    _version: response._version,
    result: response.result,
    _shards: {
      total: response._shards.total,
      successful: response._shards.successful,
      failed: response._shards.failed
    }
  };
};

// Get document
export const getDocumentImpl = async (client, index, id, options) => {
  try {
    const response = await client.get({
      index,
      id,
      ...options
    });

    return {
      _index: response._index,
      _id: response._id,
      _version: response._version,
      _seq_no: response._seq_no,
      _primary_term: response._primary_term,
      found: response.found,
      _source: response._source || null
    };
  } catch (err) {
    // Document not found
    if (err.meta && err.meta.statusCode === 404) {
      return {
        _index: index,
        _id: id,
        _version: 0,
        _seq_no: 0,
        _primary_term: 0,
        found: false,
        _source: null
      };
    }
    throw err;
  }
};

// Update document
export const updateDocumentImpl = async (client, index, id, options) => {
  const response = await client.update({
    index,
    id,
    ...options
  });

  return {
    _index: response._index,
    _id: response._id,
    _version: response._version,
    result: response.result
  };
};

// Delete document
export const deleteDocumentImpl = async (client, index, id, options) => {
  const response = await client.delete({
    index,
    id,
    ...options
  });

  return {
    _index: response._index,
    _id: response._id,
    _version: response._version,
    result: response.result
  };
};

// Search operations

export const searchImpl = async (client, index, options) => {
  const searchParams = { ...options };
  
  // Only add index if provided (null means search all indices)
  if (index !== null) {
    searchParams.index = index;
  }

  const response = await client.search(searchParams);

  return {
    took: response.took,
    timed_out: response.timed_out,
    _shards: {
      total: response._shards.total,
      successful: response._shards.successful,
      skipped: response._shards.skipped,
      failed: response._shards.failed
    },
    hits: {
      total: {
        value: response.hits.total.value,
        relation: response.hits.total.relation
      },
      max_score: response.hits.max_score !== null ? response.hits.max_score : null,
      hits: response.hits.hits.map(hit => ({
        _index: hit._index,
        _id: hit._id,
        _score: hit._score !== null ? hit._score : null,
        _source: hit._source
      }))
    },
    _scroll_id: response._scroll_id || null
  };
};

// Scroll API
export const scrollImpl = async (client, scrollId, options) => {
  const response = await client.scroll({
    scroll_id: scrollId,
    ...options
  });

  return {
    took: response.took,
    timed_out: response.timed_out,
    _shards: {
      total: response._shards.total,
      successful: response._shards.successful,
      skipped: response._shards.skipped,
      failed: response._shards.failed
    },
    hits: {
      total: {
        value: response.hits.total.value,
        relation: response.hits.total.relation
      },
      max_score: response.hits.max_score !== null ? response.hits.max_score : null,
      hits: response.hits.hits.map(hit => ({
        _index: hit._index,
        _id: hit._id,
        _score: hit._score !== null ? hit._score : null,
        _source: hit._source
      }))
    },
    _scroll_id: response._scroll_id || null
  };
};

// Clear scroll
export const clearScrollImpl = async (client, scrollId) => {
  const response = await client.clearScroll({
    scroll_id: scrollId
  });
  return {
    succeeded: response.succeeded
  };
};

// Bulk operations
export const bulkImpl = async (client, operations) => {
  const response = await client.bulk({
    operations
  });

  return {
    took: response.took,
    errors: response.errors,
    items: response.items
  };
};

// Count documents
export const countImpl = async (client, index, options) => {
  const countParams = { ...options };
  
  // Only add index if provided (null means count all indices)
  if (index !== null) {
    countParams.index = index;
  }

  const response = await client.count(countParams);
  
  return {
    count: response.count
  };
};

// Refresh index
export const refreshImpl = async (client, index) => {
  const response = await client.indices.refresh({ index });
  return {
    _shards: {
      total: response._shards.total,
      successful: response._shards.successful,
      failed: response._shards.failed
    }
  };
};

// Close client
export const closeImpl = async (client) => {
  await client.close();
};
