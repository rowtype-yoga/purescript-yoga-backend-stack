import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import {
  DynamoDBDocumentClient,
  PutCommand,
  GetCommand,
  UpdateCommand,
  DeleteCommand,
  QueryCommand,
  ScanCommand,
  BatchGetCommand,
  BatchWriteCommand,
  TransactGetCommand,
  TransactWriteCommand
} from '@aws-sdk/lib-dynamodb';
import {
  CreateTableCommand,
  DescribeTableCommand,
  DeleteTableCommand,
  ListTablesCommand
} from '@aws-sdk/client-dynamodb';

// Create DynamoDB Document Client
export const createDynamoDBImpl = (config) => {
  const clientConfig = {};

  // Region
  if (config.region) {
    clientConfig.region = config.region;
  }

  // Endpoint (for DynamoDB Local)
  if (config.endpoint) {
    clientConfig.endpoint = config.endpoint;
  }

  // Credentials
  if (config.credentials) {
    clientConfig.credentials = {
      accessKeyId: config.credentials.accessKeyId || 'dummy',
      secretAccessKey: config.credentials.secretAccessKey || 'dummy',
      ...(config.credentials.sessionToken && { sessionToken: config.credentials.sessionToken })
    };
  } else {
    // Default credentials for DynamoDB Local
    clientConfig.credentials = {
      accessKeyId: 'dummy',
      secretAccessKey: 'dummy'
    };
  }

  // Other options
  if (config.maxAttempts) {
    clientConfig.maxAttempts = config.maxAttempts;
  }

  if (config.requestTimeout) {
    clientConfig.requestTimeout = config.requestTimeout;
  }

  const client = new DynamoDBClient(clientConfig);
  
  // Use DocumentClient for easier JSON handling
  const docClient = DynamoDBDocumentClient.from(client, {
    marshallOptions: {
      convertEmptyValues: false,
      removeUndefinedValues: true,
      convertClassInstanceToMap: false
    },
    unmarshallOptions: {
      wrapNumbers: false
    }
  });

  // Attach raw client for table operations
  docClient._rawClient = client;
  
  return docClient;
};

// Put item
export const putItemImpl = async (db, input) => {
  const command = new PutCommand({
    TableName: input.tableName,
    Item: input.item,
    ...(input.conditionExpression && { ConditionExpression: input.conditionExpression }),
    ...(input.expressionAttributeValues && { ExpressionAttributeValues: input.expressionAttributeValues }),
    ...(input.expressionAttributeNames && { ExpressionAttributeNames: input.expressionAttributeNames }),
    ...(input.returnValues && { ReturnValues: input.returnValues })
  });

  const response = await db.send(command);
  
  return {
    attributes: response.Attributes || null,
    consumedCapacity: response.ConsumedCapacity || null
  };
};

// Get item
export const getItemImpl = async (db, input) => {
  const command = new GetCommand({
    TableName: input.tableName,
    Key: input.key,
    ...(input.consistentRead !== undefined && { ConsistentRead: input.consistentRead }),
    ...(input.projectionExpression && { ProjectionExpression: input.projectionExpression }),
    ...(input.expressionAttributeNames && { ExpressionAttributeNames: input.expressionAttributeNames })
  });

  const response = await db.send(command);
  
  return {
    item: response.Item || null
  };
};

// Update item
export const updateItemImpl = async (db, input) => {
  const command = new UpdateCommand({
    TableName: input.tableName,
    Key: input.key,
    UpdateExpression: input.updateExpression,
    ...(input.conditionExpression && { ConditionExpression: input.conditionExpression }),
    ...(input.expressionAttributeValues && { ExpressionAttributeValues: input.expressionAttributeValues }),
    ...(input.expressionAttributeNames && { ExpressionAttributeNames: input.expressionAttributeNames }),
    ...(input.returnValues && { ReturnValues: input.returnValues })
  });

  const response = await db.send(command);
  
  return {
    attributes: response.Attributes || null,
    consumedCapacity: response.ConsumedCapacity || null
  };
};

// Delete item
export const deleteItemImpl = async (db, input) => {
  const command = new DeleteCommand({
    TableName: input.tableName,
    Key: input.key,
    ...(input.conditionExpression && { ConditionExpression: input.conditionExpression }),
    ...(input.expressionAttributeValues && { ExpressionAttributeValues: input.expressionAttributeValues }),
    ...(input.expressionAttributeNames && { ExpressionAttributeNames: input.expressionAttributeNames }),
    ...(input.returnValues && { ReturnValues: input.returnValues })
  });

  const response = await db.send(command);
  
  return {
    attributes: response.Attributes || null,
    consumedCapacity: response.ConsumedCapacity || null
  };
};

// Query
export const queryImpl = async (db, input) => {
  const command = new QueryCommand({
    TableName: input.tableName,
    KeyConditionExpression: input.keyConditionExpression,
    ...(input.indexName && { IndexName: input.indexName }),
    ...(input.filterExpression && { FilterExpression: input.filterExpression }),
    ...(input.projectionExpression && { ProjectionExpression: input.projectionExpression }),
    ...(input.expressionAttributeValues && { ExpressionAttributeValues: input.expressionAttributeValues }),
    ...(input.expressionAttributeNames && { ExpressionAttributeNames: input.expressionAttributeNames }),
    ...(input.consistentRead !== undefined && { ConsistentRead: input.consistentRead }),
    ...(input.scanIndexForward !== undefined && { ScanIndexForward: input.scanIndexForward }),
    ...(input.limit && { Limit: input.limit }),
    ...(input.exclusiveStartKey && { ExclusiveStartKey: input.exclusiveStartKey })
  });

  const response = await db.send(command);
  
  return {
    items: response.Items || [],
    count: response.Count || 0,
    scannedCount: response.ScannedCount || 0,
    lastEvaluatedKey: response.LastEvaluatedKey || null,
    consumedCapacity: response.ConsumedCapacity || null
  };
};

// Scan
export const scanImpl = async (db, input) => {
  const command = new ScanCommand({
    TableName: input.tableName,
    ...(input.indexName && { IndexName: input.indexName }),
    ...(input.filterExpression && { FilterExpression: input.filterExpression }),
    ...(input.projectionExpression && { ProjectionExpression: input.projectionExpression }),
    ...(input.expressionAttributeValues && { ExpressionAttributeValues: input.expressionAttributeValues }),
    ...(input.expressionAttributeNames && { ExpressionAttributeNames: input.expressionAttributeNames }),
    ...(input.consistentRead !== undefined && { ConsistentRead: input.consistentRead }),
    ...(input.limit && { Limit: input.limit }),
    ...(input.exclusiveStartKey && { ExclusiveStartKey: input.exclusiveStartKey })
  });

  const response = await db.send(command);
  
  return {
    items: response.Items || [],
    count: response.Count || 0,
    scannedCount: response.ScannedCount || 0,
    lastEvaluatedKey: response.LastEvaluatedKey || null,
    consumedCapacity: response.ConsumedCapacity || null
  };
};

// Batch get item
export const batchGetItemImpl = async (db, requestItems) => {
  const command = new BatchGetCommand({
    RequestItems: requestItems
  });

  const response = await db.send(command);
  
  return {
    responses: response.Responses || {},
    unprocessedKeys: response.UnprocessedKeys || {}
  };
};

// Batch write item
export const batchWriteItemImpl = async (db, requestItems) => {
  const command = new BatchWriteCommand({
    RequestItems: requestItems
  });

  const response = await db.send(command);
  
  return {
    unprocessedItems: response.UnprocessedItems || {}
  };
};

// TransactGetItems
export const transactGetItemsImpl = async (db, transactItems) => {
  const command = new TransactGetCommand({
    TransactItems: transactItems
  });

  const response = await db.send(command);
  
  return {
    responses: (response.Responses || []).map(r => ({
      item: r.Item || null
    }))
  };
};

// TransactWriteItems
export const transactWriteItemsImpl = async (db, transactItems) => {
  const command = new TransactWriteCommand({
    TransactItems: transactItems
  });

  await db.send(command);
};

// Table operations (use raw client)

// Create table
export const createTableImpl = async (db, input) => {
  const command = new CreateTableCommand({
    TableName: input.tableName,
    AttributeDefinitions: input.attributeDefinitions,
    KeySchema: input.keySchema,
    ...(input.billingMode && { BillingMode: input.billingMode }),
    ...(input.provisionedThroughput && { ProvisionedThroughput: input.provisionedThroughput }),
    ...(input.globalSecondaryIndexes && { GlobalSecondaryIndexes: input.globalSecondaryIndexes }),
    ...(input.localSecondaryIndexes && { LocalSecondaryIndexes: input.localSecondaryIndexes }),
    ...(input.streamSpecification && { StreamSpecification: input.streamSpecification }),
    ...(input.tags && { Tags: input.tags })
  });

  const response = await db._rawClient.send(command);
  return response.TableDescription;
};

// Describe table
export const describeTableImpl = async (db, tableName) => {
  const command = new DescribeTableCommand({
    TableName: tableName
  });

  const response = await db._rawClient.send(command);
  return response.Table;
};

// Delete table
export const deleteTableImpl = async (db, tableName) => {
  const command = new DeleteTableCommand({
    TableName: tableName
  });

  const response = await db._rawClient.send(command);
  return response.TableDescription;
};

// List tables
export const listTablesImpl = async (db, limit) => {
  const command = new ListTablesCommand({
    ...(limit !== null && { Limit: limit })
  });

  const response = await db._rawClient.send(command);
  
  return {
    tableNames: response.TableNames || [],
    lastEvaluatedTableName: response.LastEvaluatedTableName || null
  };
};
